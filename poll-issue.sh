#!/usr/bin/env bash
# poll-issue.sh — the "radio" for a multi-agent session.
#
# Three modes:
#   init  <issue> <identity> <repo> <watermark_file>
#         Mark all EXISTING comments as already seen. Run once at start so you
#         do not reprocess history. Prints the watermark it set.
#
#   peek  <issue> <identity> <repo> <watermark_file> [count]
#         Print the last <count> comments (default 10) WITHOUT moving the
#         watermark. Use before any commit / push / deploy so you build against
#         the instructions that are current NOW. Consumes nothing.
#
#   watch <issue> <identity> <repo> <watermark_file> [interval_s] [max_wait_s]
#         Block and poll. Return only when there is real mail for you, or a
#         SESSION DONE, or max_wait elapses. Zero LLM tokens spent while waiting.
#
#   audit <issue> <identity> <repo> <state_file> [interval_s] [max_wait_s]
#         Like watch, but returns EVERY new or edited comment, not just yours.
#         For an observer / auditor role that must see agent-to-agent traffic.
#         Your own comments advance the state but never wake you.
#
# Exit codes for watch and audit:
#   0  = new mail (printed). Act on it, then run again.
#   42 = SESSION DONE seen (printed). Stop the loop, sign off, wait for human.
#   10 = nothing after max_wait. Just run again to keep listening.
#
# Filtering in watch (text-based, because every agent shares one GitHub login):
#   - A comment is "for you" if its body contains [<identity>] or [all].
#     Brackets, not @ — an @Name is a real GitHub handle owned by a stranger, and
#     mentioning it on a public issue notifies them. Brackets own no namespace.
#   - A comment from you is skipped: it starts with "<identity>:".
#   - Plain acks addressed to you still return; YOU decide if they need action.
#
# Robustness (learned from real runs):
#   - Comments are fetched as raw JSON to a file and parsed in ONE jq pass.
#     No echo round-trip — code blocks / control chars in comments no longer
#     break parsing.
#   - A transient gh/jq error in one poll is NON-FATAL: the loop retries next
#     tick instead of crashing the whole watch.
#   - The resolved ABSOLUTE watermark path is printed every run. A relative path
#     silently follows your cwd, and Bash cwd PERSISTS across calls in Claude
#     Code — one `cd` mid-session pointed a watcher at a fresh empty watermark
#     and swallowed a `[BUILDER] go`, deadlocking a live three-agent sprint
#     (2026-09-05). Printing the path makes that drift visible immediately.
#   - A missing / empty watermark still baselines to newest (never replays
#     history) BUT now SHOUTS about it when the issue already has comments,
#     because that is exactly the silent-mail-loss case above.
#   - The stop token is matched EXCEPT inside markup that renders as code or
#     quoted text (fences, inline code, blockquotes, indented blocks). It tripped
#     watchers 5/5 times from a QUOTE and never once from a real close, so the fix
#     is in the parser rather than in a rule nobody can follow while pasting
#     evidence. No positional rule: every genuine close appended the token to a
#     sign-off, so "own line" would turn a loud false trip into a silent miss.
#   - watch also reports a comment EDITED AFTER YOU SAW IT (via GitHub's
#     includesCreatedEdit flag). An edited spec used to be invisible: the
#     watermark only tracks createdAt, so every agent kept building from the
#     stale text with nothing to warn them.

set -uo pipefail   # NOTE: intentionally no -e; one bad poll must not kill the watch

MODE="${1:-}"
ISSUE="${2:-}"
IDENTITY="${3:-}"
REPO="${4:-}"
WM_FILE="${5:-}"
INTERVAL="${6:-45}"
MAX_WAIT="${7:-540}"   # keep under the 600s Bash timeout

if [ -z "$MODE" ] || [ -z "$ISSUE" ] || [ -z "$IDENTITY" ] || [ -z "$REPO" ] || [ -z "$WM_FILE" ]; then
  echo "usage: poll-issue.sh init|watch|audit <issue> <identity> <repo> <watermark_file> [interval_s] [max_wait_s]" >&2
  exit 2
fi

# --- state paths -------------------------------------------------------------
# Resolve to absolute so the path we REPORT is the path we USE, and so a later
# `cd` cannot quietly point us at a different file mid-session.
case "$WM_FILE" in
  /*) WM_ABS="$WM_FILE" ;;
  *)  WM_ABS="$PWD/$WM_FILE" ;;
esac
mkdir -p "$(dirname "$WM_ABS")" 2>/dev/null

JSON_TMP="${WM_ABS}.comments.json"   # raw fetch
EDIT_FILE="${WM_ABS}.edits"          # sidecar: id:includesCreatedEdit per comment
FP_FILE="${WM_ABS}.fp"               # sidecar: id:updated_at per comment (audit)

echo "watermark file: $WM_ABS"

# --- fetch helpers -----------------------------------------------------------
# Fetch comments as raw JSON into $JSON_TMP. Always leaves a valid JSON doc
# behind, even on gh failure or malformed output — so the caller's jq never dies.
fetch_comments_json() {
  if ! gh issue view "$ISSUE" --repo "$REPO" --json comments > "$JSON_TMP" 2>/dev/null; then
    echo '{"comments":[]}' > "$JSON_TMP"
    return
  fi
  if ! jq -e . "$JSON_TMP" >/dev/null 2>&1; then
    echo '{"comments":[]}' > "$JSON_TMP"
  fi
}

# audit mode needs updated_at, which `gh issue view --json comments` does NOT
# expose (it returns null). Only the REST API carries it.
fetch_comments_api() {
  if ! gh api "repos/${REPO}/issues/${ISSUE}/comments" --paginate > "$JSON_TMP" 2>/dev/null; then
    echo '[]' > "$JSON_TMP"
    return
  fi
  jq -e 'type == "array"' "$JSON_TMP" >/dev/null 2>&1 || echo '[]' > "$JSON_TMP"
}

newest_ts() {
  # newest createdAt across .comments in $JSON_TMP, or "" if none
  jq -r '.comments | if length == 0 then "" else (max_by(.createdAt) | .createdAt) end' "$JSON_TMP" 2>/dev/null || echo ""
}

comment_count() {
  jq -r '.comments | length' "$JSON_TMP" 2>/dev/null || echo 0
}

write_edit_sidecar() {
  jq -r '.comments[]? | "\(.id):\(.includesCreatedEdit)"' "$JSON_TMP" 2>/dev/null | sort > "$EDIT_FILE"
}

if [ "$MODE" = "init" ]; then
  fetch_comments_json
  NEWEST="$(newest_ts)"
  echo "$NEWEST" > "$WM_ABS"
  write_edit_sidecar
  echo "watermark set to: ${NEWEST:-<none, empty issue>}"
  echo
  echo "NOTE: pass this SAME absolute path to every later watch call."
  echo "      A relative path follows your cwd, and cwd persists between Bash"
  echo "      calls — one 'cd' would orphan this watermark and silently drop mail."
  exit 0
fi

# --- peek --------------------------------------------------------------------
# Read the thread WITHOUT touching the watermark. This is the "re-check before
# you commit" rule made runnable: going heads-down means you stop hearing the
# channel, so re-read before any commit / push / deploy. Safe to run any time —
# it consumes nothing, so your next watch still delivers everything it would
# have. (Added because an agent went looking for exactly this mode and had to
# grep the script for it — 2026-09-05.)
if [ "$MODE" = "peek" ]; then
  COUNT_ARG="${6:-10}"
  fetch_comments_json
  TOTAL="$(comment_count)"
  echo "=== thread #$ISSUE — last $COUNT_ARG of $TOTAL comment(s). Watermark NOT moved. ==="
  jq -r --argjson n "$COUNT_ARG" '.comments | (if length > $n then .[length-$n:] else . end)[]
    | "[" + .createdAt + "]" + (if .includesCreatedEdit then "  *** EDITED SINCE POSTING ***" else "" end)
      + "\n" + .body + "\n"' "$JSON_TMP" 2>/dev/null
  echo "=== end of thread. Build against THESE instructions, not the ones you started with. ==="
  exit 0
fi

if [ "$MODE" != "watch" ] && [ "$MODE" != "audit" ]; then
  echo "unknown mode: $MODE (use init, peek, watch or audit)" >&2
  exit 2
fi

# =============================================================================
# audit — return EVERY new or edited comment (observer role)
# =============================================================================
if [ "$MODE" = "audit" ]; then
  fingerprint() { jq -r '.[] | "\(.id):\(.updated_at)"' "$JSON_TMP" 2>/dev/null | sort; }

  fetch_comments_api
  if [ ! -s "$FP_FILE" ]; then
    fingerprint > "$FP_FILE"
    echo "=== audit baseline set: $(wc -l < "$FP_FILE" | tr -d ' ') comment(s) ==="
    exit 10
  fi

  elapsed=0
  while :; do
    fetch_comments_api
    NEWFP="$(fingerprint)"
    CHANGED="$(comm -13 "$FP_FILE" <(printf '%s\n' "$NEWFP") | cut -d: -f1 | sort -u)"

    if [ -n "$CHANGED" ]; then
      IDS="$(printf '%s' "$CHANGED" | jq -R . | jq -s -c .)"

      # Your own comments advance the state but must not wake you.
      OTHERS="$(jq -r --argjson ids "$IDS" --arg me "$IDENTITY" '
        .[] | select((.id|tostring) as $i | $ids | index($i))
            | select((.body | test("^\\s*" + $me + "\\s*:"; "i")) | not)
            | .id' "$JSON_TMP" 2>/dev/null | sort -u)"

      if [ -z "$OTHERS" ]; then
        printf '%s\n' "$NEWFP" > "$FP_FILE"
      else
        echo "=== AUDIT: $(printf '%s\n' "$CHANGED" | grep -c .) comment(s) new or edited ==="
        jq -r --argjson ids "$IDS" '
          .[] | select((.id|tostring) as $i | $ids | index($i))
          | "--- id=\(.id) created=\(.created_at) updated=\(.updated_at) author=\(.user.login)"
            + (if .created_at != .updated_at then "  *** EDITED AFTER POSTING ***" else "" end)
            + "\n\(.body)\n"
        ' "$JSON_TMP"

        printf '%s\n' "$NEWFP" > "$FP_FILE"

        # Same markup-stripped match as watch — see the long note there.
        if jq -e --argjson ids "$IDS" '
          any(.[]; ((.id|tostring) as $i | $ids | index($i))
                   and (( .body
                          | gsub("```[\\s\\S]*?```"; ""; "m")
                          | gsub("~~~[\\s\\S]*?~~~"; ""; "m")
                          | gsub("`[^`\n]*`"; "")
                          | gsub("(^|\n)[ \t]*>[^\n]*"; "")
                          | gsub("(^|\n)(    |\t)[^\n]*"; "")
                        ) | test("\\[SESSION DONE\\]"; "i")))
        ' "$JSON_TMP" >/dev/null 2>&1; then
          echo "=== SESSION DONE seen on the thread ==="
          exit 42
        fi
        exit 0
      fi
    fi

    if [ "$elapsed" -ge "$MAX_WAIT" ]; then
      echo "=== AUDIT: no thread activity after ${MAX_WAIT}s. Run again to keep listening. ==="
      exit 10
    fi
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
  done
fi

# =============================================================================
# watch — return only mail addressed to you
# =============================================================================
WM=""
[ -f "$WM_ABS" ] && WM="$(cat "$WM_ABS" 2>/dev/null || echo "")"

# Missing / empty watermark → baseline to newest. NEVER replay history.
# But SHOUT if the issue already has comments: that is the silent-mail-loss case.
if [ -z "$WM" ]; then
  fetch_comments_json
  EXISTING="$(comment_count)"
  WM="$(newest_ts)"
  echo "$WM" > "$WM_ABS"
  write_edit_sidecar

  if [ "${EXISTING:-0}" -gt 0 ]; then
    echo "########################################################################"
    echo "## WARNING — NO WATERMARK FOUND, BUT THIS ISSUE HAS $EXISTING COMMENT(S)."
    echo "##"
    echo "## Path checked: $WM_ABS"
    echo "##"
    echo "## Either you skipped 'init', or your watermark was ORPHANED — a"
    echo "## relative path plus a 'cd' (Bash cwd persists between calls) makes"
    echo "## the same argument resolve to a different file."
    echo "##"
    echo "## I have baselined to the newest comment ($WM). ANY MAIL ADDRESSED TO"
    echo "## YOU BEFORE THAT POINT IS NOW UNREACHABLE VIA watch."
    echo "##"
    echo "## DO THIS NOW:"
    echo "##   1. Read the thread by hand:"
    echo "##      gh issue view $ISSUE --repo $REPO --comments"
    echo "##   2. Act on anything addressed to [$IDENTITY] or [all] that you"
    echo "##      have not already handled."
    echo "##   3. Post on the thread that mail may have been lost, so whoever"
    echo "##      sent it can re-send the FULL message (not just a trigger word)."
    echo "##   4. Use this SAME absolute path for every later watch call."
    echo "########################################################################"
    echo
  fi
fi

elapsed=0
while :; do
  fetch_comments_json

  NEW="$(jq --arg wm "$WM" -c '[.comments[] | select(.createdAt > $wm)]' "$JSON_TMP" 2>/dev/null || echo '[]')"
  [ -z "$NEW" ] && NEW='[]'
  COUNT="$(printf '%s' "$NEW" | jq 'length' 2>/dev/null || echo 0)"
  [ -z "$COUNT" ] && COUNT=0

  # --- edits: a comment you ALREADY saw whose text changed under you ---------
  # The watermark only tracks createdAt, so an edited comment is otherwise
  # invisible and every agent keeps building from the stale text.
  EDITED_OUT=""
  if [ -s "$EDIT_FILE" ]; then
    NOW_EDITS="$(jq -r '.comments[]? | "\(.id):\(.includesCreatedEdit)"' "$JSON_TMP" 2>/dev/null | sort)"
    FLIPPED="$(comm -13 "$EDIT_FILE" <(printf '%s\n' "$NOW_EDITS") \
               | grep ':true$' | cut -d: -f1 | sort -u)"
    if [ -n "$FLIPPED" ]; then
      FIDS="$(printf '%s' "$FLIPPED" | jq -R . | jq -s -c .)"
      EDITED_OUT="$(jq -r --argjson ids "$FIDS" --arg id "$IDENTITY" '
        [ .comments[]
          | select((.id|tostring) as $i | $ids | index($i))
          | select( (.body | test("\\[" + $id + "\\]"; "i")) or (.body | test("\\[all\\]"; "i")) )
          | select( (.body | test("^\\s*" + $id + "\\s*:"; "i")) | not )
        ] | .[] | "*** EDITED AFTER YOU SAW IT *** [" + .createdAt + "]\n" + .body + "\n"
      ' "$JSON_TMP" 2>/dev/null || echo "")"
    fi
  fi
  # Sidecar always catches up, so an edit is reported once, not every tick.
  write_edit_sidecar

  if [ "$COUNT" -gt 0 ]; then
    NEWEST="$(printf '%s' "$NEW" | jq -r 'max_by(.createdAt) | .createdAt' 2>/dev/null || echo "")"

    # Stop signal: the bracketed token [SESSION DONE], matched ANYWHERE in a comment
    # EXCEPT inside markup that markdown renders as code or as quoted text.
    #
    # WHY THE STRIP: the token tripped watchers FIVE times across two sprints, and
    # every single trip was a quote — inline backticks, a fenced block, or a
    # blockquote — while every genuine close was bare prose. Pasting raw evidence
    # verbatim is the RIGOROUS instinct, so telling agents to be careful failed 5/5,
    # the fifth time inside the review of this very fix, by an agent that had just
    # read three write-ups of the trap. You fix an instinct in the parser and a
    # choice in the instructions: quoting is an instinct, so it is handled here;
    # typing the token bare in prose is a choice, and rule 5 covers that.
    #
    # No positional rule. Every real close appended the token to a sign-off, so
    # "own line" or "start of comment" would turn a loud false trip into a SILENT
    # MISS — and rule 1 requires comments to START with "IDENTITY:", so a
    # start-anchored token could only ever fire from a comment that breaks rule 1.
    # Zero behaviour change for anyone closing a session; that is the point.
    #
    # The strip list is CLOSED, not accumulating: it is everything markdown renders
    # as code or quoted text.
    STOP="$(printf '%s' "$NEW" | jq '
      [ .[]
        | select(
            ( .body
              | gsub("```[\\s\\S]*?```"; ""; "m")      # fenced block, backticks
              | gsub("~~~[\\s\\S]*?~~~"; ""; "m")      # fenced block, tildes
              | gsub("`[^`\n]*`"; "")                   # inline code span
              | gsub("(^|\n)[ \t]*>[^\n]*"; "")         # blockquote line
              | gsub("(^|\n)(    |\t)[^\n]*"; "")       # indented code block
            ) | test("\\[SESSION DONE\\]"; "i")
          )
      ] | length' 2>/dev/null || echo 0)"
    [ -z "$STOP" ] && STOP=0

    # A bare standalone `SESSION DONE` was the OLD trigger and no longer stops
    # anything. Never let that fail silently: a live session holds the old skill text
    # in its context even after the repo updates, so an agent can still emit the old
    # form believing it ended the session. Say so out loud instead.
    LEGACY="$(printf '%s' "$NEW" | jq '[.[] | select((.body | test("(^|\\n)[ \\t]*SESSION DONE[ \\t]*(\\n|$)")) and (.body | test("\\[SESSION DONE\\]"; "i") | not))] | length' 2>/dev/null || echo 0)"
    [ -z "$LEGACY" ] && LEGACY=0

    MAIL="$(printf '%s' "$NEW" | jq --arg id "$IDENTITY" '
      [ .[]
        | select( (.body | test("\\[" + $id + "\\]"; "i")) or (.body | test("\\[all\\]"; "i")) )
        | select( (.body | test("^\\s*" + $id + "\\s*:"; "i")) | not )
      ]' 2>/dev/null || echo '[]')"
    [ -z "$MAIL" ] && MAIL='[]'
    MAILCOUNT="$(printf '%s' "$MAIL" | jq 'length' 2>/dev/null || echo 0)"
    [ -z "$MAILCOUNT" ] && MAILCOUNT=0


    if [ "$STOP" -gt 0 ]; then
      echo "=== SESSION DONE received ==="
      printf '%s' "$NEW" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_ABS"
      exit 42
    fi

    if [ "$LEGACY" -gt 0 ]; then
      echo "########################################################################"
      echo "## WARNING — OLD-FORMAT STOP SIGNAL SEEN. IT DID *NOT* STOP ANYTHING."
      echo "##"
      echo "## Someone posted a bare \`SESSION DONE\` on its own line. That was the"
      echo "## old trigger. The signal is now the bracketed token \`[SESSION DONE]\`,"
      echo "## so this session is STILL RUNNING and every other agent is still"
      echo "## watching — including whoever posted it, who probably believes they"
      echo "## just closed the session."
      echo "##"
      echo "## Most likely cause: that agent loaded an older copy of the skill into"
      echo "## its context before the repo updated. Its instructions are stale even"
      echo "## though the script on disk is current."
      echo "##"
      echo "## DO THIS: if the session really is finished, post the bracketed token"
      echo "## yourself. If it is not, say so on the thread so nobody stands down."
      echo "########################################################################"
      echo
      printf '%s' "$NEW" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_ABS"
      exit 0
    fi

    if [ "$MAILCOUNT" -gt 0 ]; then
      echo "=== New mail for $IDENTITY ($MAILCOUNT) ==="
      [ -n "$EDITED_OUT" ] && printf '%s\n' "$EDITED_OUT"
      printf '%s' "$MAIL" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      echo "--- read ALL of the above before you act: a single batch can hold"
      echo "--- several messages, and the later one may change the earlier one."
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_ABS"
      exit 0
    fi

    # Only comments not addressed to us (or our own). Mark seen, keep waiting.
    if [ -n "$NEWEST" ]; then
      echo "$NEWEST" > "$WM_ABS"
      WM="$NEWEST"
    fi
  fi

  # An edit to an older comment is still mail, even with no new comments.
  if [ -n "$EDITED_OUT" ]; then
    echo "=== A comment addressed to $IDENTITY was EDITED after you saw it ==="
    printf '%s\n' "$EDITED_OUT"
    echo "--- Re-read it. Your earlier understanding may now be stale."
    exit 0
  fi

  if [ "$elapsed" -ge "$MAX_WAIT" ]; then
    echo "=== No mail after ${MAX_WAIT}s. Run watch again to keep listening. ==="
    exit 10
  fi

  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done
