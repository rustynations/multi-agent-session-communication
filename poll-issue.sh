#!/usr/bin/env bash
# poll-issue.sh — the "radio" for a multi-agent session.
#
# Two modes:
#   init  <issue> <identity> <repo> <watermark_file>
#         Mark all EXISTING comments as already seen. Run once at start so you
#         do not reprocess history. Prints the watermark it set.
#
#   watch <issue> <identity> <repo> <watermark_file> [interval_s] [max_wait_s]
#         Block and poll. Return only when there is real mail for you, or a
#         SESSION DONE, or max_wait elapses. Zero LLM tokens spent while waiting.
#
# Exit codes for watch:
#   0  = new mail for you (printed). Act on it, then run watch again.
#   42 = SESSION DONE seen (printed). Stop the loop, sign off, wait for human.
#   10 = nothing after max_wait. Just run watch again to keep listening.
#
# Filtering (text-based, because every agent shares one GitHub login):
#   - A comment is "for you" if its body contains @<identity> or @all.
#   - A comment from you is skipped: it starts with "<identity>:".
#   - Plain acks addressed to you still return; YOU decide if they need action.
#
# Robustness (learned from real runs):
#   - Comments are fetched as raw JSON to a file and parsed in ONE jq pass.
#     No echo round-trip — code blocks / control chars in comments no longer
#     break parsing.
#   - A transient gh/jq error in one poll is NON-FATAL: the loop retries next
#     tick instead of crashing the whole watch.
#   - A missing / empty watermark BASELINES to newest (never replays history).

set -uo pipefail   # NOTE: intentionally no -e; one bad poll must not kill the watch

MODE="${1:-}"
ISSUE="${2:-}"
IDENTITY="${3:-}"
REPO="${4:-}"
WM_FILE="${5:-}"
INTERVAL="${6:-45}"
MAX_WAIT="${7:-540}"   # keep under the 600s Bash timeout

if [ -z "$MODE" ] || [ -z "$ISSUE" ] || [ -z "$IDENTITY" ] || [ -z "$REPO" ] || [ -z "$WM_FILE" ]; then
  echo "usage: poll-issue.sh init|watch <issue> <identity> <repo> <watermark_file> [interval_s] [max_wait_s]" >&2
  exit 2
fi

JSON_TMP="${WM_FILE}.comments.json"

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

newest_ts() {
  # newest createdAt across .comments in $JSON_TMP, or "" if none
  jq -r '.comments | if length == 0 then "" else (max_by(.createdAt) | .createdAt) end' "$JSON_TMP" 2>/dev/null || echo ""
}

if [ "$MODE" = "init" ]; then
  fetch_comments_json
  NEWEST="$(newest_ts)"
  echo "$NEWEST" > "$WM_FILE"
  echo "watermark set to: ${NEWEST:-<none, empty issue>}"
  exit 0
fi

if [ "$MODE" != "watch" ]; then
  echo "unknown mode: $MODE (use init or watch)" >&2
  exit 2
fi

WM=""
[ -f "$WM_FILE" ] && WM="$(cat "$WM_FILE" 2>/dev/null || echo "")"

# Missing / empty watermark → baseline to newest now. NEVER replay history.
if [ -z "$WM" ]; then
  fetch_comments_json
  WM="$(newest_ts)"
  echo "$WM" > "$WM_FILE"
fi

elapsed=0
while :; do
  fetch_comments_json

  NEW="$(jq --arg wm "$WM" -c '[.comments[] | select(.createdAt > $wm)]' "$JSON_TMP" 2>/dev/null || echo '[]')"
  [ -z "$NEW" ] && NEW='[]'
  COUNT="$(printf '%s' "$NEW" | jq 'length' 2>/dev/null || echo 0)"
  [ -z "$COUNT" ] && COUNT=0

  if [ "$COUNT" -gt 0 ]; then
    NEWEST="$(printf '%s' "$NEW" | jq -r 'max_by(.createdAt) | .createdAt' 2>/dev/null || echo "")"

    # Match SESSION DONE only as a standalone line (not mentioned inside prose,
    # which used to false-trigger a stop). See README / skill "Stop word" rule.
    STOP="$(printf '%s' "$NEW" | jq '[.[] | select(.body | test("(^|\\n)[ \\t]*SESSION DONE[ \\t]*(\\n|$)"))] | length' 2>/dev/null || echo 0)"
    [ -z "$STOP" ] && STOP=0

    MAIL="$(printf '%s' "$NEW" | jq --arg id "$IDENTITY" '
      [ .[]
        | select( (.body | test("@" + $id + "\\b"; "i")) or (.body | test("@all\\b"; "i")) )
        | select( (.body | test("^\\s*" + $id + "\\s*:"; "i")) | not )
      ]' 2>/dev/null || echo '[]')"
    [ -z "$MAIL" ] && MAIL='[]'
    MAILCOUNT="$(printf '%s' "$MAIL" | jq 'length' 2>/dev/null || echo 0)"
    [ -z "$MAILCOUNT" ] && MAILCOUNT=0

    if [ "$STOP" -gt 0 ]; then
      echo "=== SESSION DONE received ==="
      printf '%s' "$NEW" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_FILE"
      exit 42
    fi

    if [ "$MAILCOUNT" -gt 0 ]; then
      echo "=== New mail for $IDENTITY ==="
      printf '%s' "$MAIL" | jq -r '.[] | "[" + .createdAt + "]\n" + .body + "\n"'
      [ -n "$NEWEST" ] && echo "$NEWEST" > "$WM_FILE"
      exit 0
    fi

    # Only comments not addressed to us (or our own). Mark seen, keep waiting.
    if [ -n "$NEWEST" ]; then
      echo "$NEWEST" > "$WM_FILE"
      WM="$NEWEST"
    fi
  fi

  if [ "$elapsed" -ge "$MAX_WAIT" ]; then
    echo "=== No mail after ${MAX_WAIT}s. Run watch again to keep listening. ==="
    exit 10
  fi

  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done
