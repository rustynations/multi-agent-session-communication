---
name: multi-agent-session
description: Use when this Claude Code session is one of several live agents collaborating on the same GitHub issue at once — a multi-agent session, distinct from spawning subagents. Triggers on /multi-agent-session (or /multiAgentSession), or a request to have two or more running sessions talk, coordinate, poll each other, or hand work off through a shared issue. Symptoms — "have the two terminals talk", "agents coordinate via the issue", spec/reviewer agent + builder agent working the same issue.
---
<!-- Version: 2026-09-05.2 -->

# Multi-Agent Session

## Overview

You are ONE agent among several, all working the same GitHub issue at the same time.
The **issue is the bus.** Comments are the messages. You listen by polling, and you
speak by commenting. Any agent anywhere that can see the issue can join — no shared
machine, no wire between terminals.

This is NOT a subagent you spawned. These are peer sessions you cannot see directly.

## Required inputs — ask if missing

You need TWO things before doing anything else:

1. **Issue number** — e.g. `42`
2. **Your identity** — a short name, e.g. `Frank`, `DocWriter`, `Builder`

If either is missing from how you were invoked, **STOP and ask the user for it.** Do
not guess an identity. Do not guess the issue.

**Repo:** default to this repo's GitHub remote — `gh repo view --json nameWithOwner -q .nameWithOwner`.
If the issue lives in a different repo (common for scaffold projects: issues live in
`<project>-project`), confirm the repo with the user.

**Your human's GitHub alias:** do **NOT** ask, and never hardcode it — derive it with
`gh api user -q .login`. Address the human as `@$HUMAN` so the thread names a real
account instead of a guess. Guessing is worse than it looks: a short nickname or first
name that looks like your human's handle usually belongs to **a different real person**,
so the mention points at a stranger. (Caveat: when the agents post under the human's own account, GitHub sends no
notification — you cannot notify yourself. The `@$HUMAN` is for the record, so a human
scanning the thread can see which lines are theirs to answer. It becomes a real alert
only if the agents post under a separate account.)

## The seven golden rules

1. **Sign** every comment — start it with `<identity>:` (e.g. `Frank:`).
2. **Address** every comment — name who it is for in **square brackets**: `[DocWriter]`
   or `[all]`. Brackets, never `@`. **`@` is reserved for real GitHub accounts.** Any
   obvious agent name is also somebody's real GitHub handle — `@`-mentioning one on a
   public issue notifies a stranger, and no prefix is safe (adding `agent-` does not
   help; those are taken too). `[Builder]` belongs to no namespace, so it never collides.
3. **Watermark** — never re-read old comments. The poll script tracks this for you.
4. **Act only if it is for you AND needs action.** A plain "ok / thanks" ends the chain. Reply to it and you start an echo loop. Silence is allowed.
5. **Stop word** — if anyone posts `SESSION DONE` **on its own line**, stop the loop, sign off, wait for the human. When you post it, put it on its **own line, nothing else** — never inside a sentence. (A prose mention used to false-trigger every watcher; the poller now only matches a standalone line, but keep it clean.)
6. **Never use `SendMessage`.** The issue is the only channel — no wire between
   terminals. Direct session-to-session messages leave **no record**: your human cannot
   read them, a restarted agent cannot recover them, and an agent that is not on this
   machine never sees them. If you cannot get a response from an agent you need, post
   the blocker on the thread addressed to `@$HUMAN` **and** ask your human in your own
   window. Do not route around the bus.
7. **Never block on a prompt.** Do **not** use `AskUserQuestion`, and do not run anything else
   that stops and waits for a person. A blocking prompt freezes your session, so **you are not
   polling** — and the thread still says you are watching. You go deaf and you look fine.

   This happened in a real sprint (2026-09-05): an agent hit a permission refusal, asked the
   human a modal question, posted *"Parked, watching"*, and sat frozen. The coordinator answered
   **55 seconds later** and the agent could not receive it. No peer could detect the problem —
   the thread looked healthy. Only the human staring at that terminal could see it, and had to
   dismiss the prompt by hand.

   **Need the human? Post the ask on the thread and go straight back to `watch`.** Then you are
   listening when the answer lands — and the answer often comes from a **peer**, not the human.
   Before you ask at all, `peek`: it may already be answered.

Rules 6 and 7 are the same mistake wearing two hats. `SendMessage` leaves **no record**; a
blocking prompt leaves you **deaf**. Both route around the bus, and the bus is the only thing
every agent can hear.

Ignore your own comments. Frank never acts on Frank.

## Keep the record current

The issue is the shared source of truth. **If it isn't on the thread, no one — agent or
human — can see it.** Post an update (signed, `[all]` unless it is for someone), then keep
working — do NOT wait for a reply — when any of these happen:

- You **start** a distinct piece of work, or **change your plan.**
- You **finish** a unit of work — a commit, a deploy, a verification — with the **raw evidence**, not just "done."
- You **make or change a decision.**
- You hit a **blocker — including needing the human** (expired login, a decision, a manual
  check, a permission refusal), hand off, or **stand down.** Post it on the thread — addressed
  to `@$HUMAN` when it is the human you need — even if you also mention it in your own window:
  an out-of-band ask is invisible to the team, and the thread just looks like you are working.
  Then **go back to `watch` immediately.** Do not stop and wait on a prompt (rule 7), and do not
  assume only the human can unblock you: state the blocker, offer the options you can see, and a
  **peer** will often answer it before the human ever reads the thread.
- You are about to go **heads-down** for a while — say what you are doing and roughly when
  you will resurface. While working you cannot hear the channel, so a labeled pause beats
  ambiguous silence.

These are boundaries, not chatter — that is the "record, not noise" line. Do not narrate
every step; do mark every turn. A current thread also keeps watchers awake: they wake on
your updates instead of timing out on dead air.

## Re-check before you commit

Going heads-down means you stop hearing the channel — decisions and answers can land while
you work. So before any **commit / push / deploy** (or after a long heads-down stretch), do
**one quick read** of the thread. Build the instructions that are **current now**, not the
ones from when you started. If a decision changed your task, absorb it before you ship.

Use `peek` — it prints the recent thread and **does not move your watermark**, so your next
`watch` still delivers everything it would have:

```
"$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 10
```

This is the listening half of the record: post at your boundaries, and **read at them too.**

## When a message goes missing

Lost mail does not look like an error. It looks like **someone doing nothing.** Two agents
each waiting on the other is the signature, and neither one can see the problem from inside.

**Spot it.** If an agent has been silent since it said "holding", check the thread against
its watermark instead of assuming it is busy:

```
"$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 20     # what was actually said
cat "$WM"                                        # what that agent has consumed
ls -la "$HOME/.claude/mas-state/" | grep "$ISSUE"  # TWO files for one agent = orphaned
```

Two watermark files for the same agent and issue is proof. Compare their values against the
timestamp of the message that seems to have vanished — a message dated **between** them was
swallowed.

**Recover it — three rules, in order:**

1. **Rewind the watermark. Do not carry the broken value forward.** The tempting fix is to
   copy the newer file to the correct path. That keeps the value that caused the loss, so the
   message stays unreachable. Set the watermark to just **before** the lost message instead:
   ```
   echo "2026-09-05T15:25:00Z" > "$WM"   # one second before the lost comment
   ```
2. **Re-send the FULL message, not just the trigger.** A lost `[BUILDER] go` almost never
   carries only the word "go" — it carries decisions, bounds, and clarifications that rode
   along with it. Re-posting a bare "go" hands the work back with **every instruction
   stripped out, and nobody can tell what is missing.** Copy the original body verbatim.
3. **Say it on the thread.** Name what was lost and that it was lost, not withheld. An agent
   that missed a message did nothing wrong, and the record needs to show why the gap exists.

**Verify before you accuse.** Read the two watermark files and the message timestamp yourself,
even if a peer hands you the diagnosis. Same rule as any alarming result: cheapest
discriminating check first.

## Sharing a working tree

If several agents run against the **same repo checkout** (the common setup), you share one git
working tree — so be careful what you commit:

- **Commit only your own paths:** `git add <your files>`. **Never `git add -A` or `git add .`** —
  a broad add sweeps a peer's **uncommitted, maybe half-finished** work into your commit and can
  push it to a shared branch before it is ready.
- A pushed shared-branch commit is **hard to reverse.** If a mix-up happens, flag it on the
  thread and let the human decide — do **not** force-push or rewrite shared history on your own.

(Structural alternative: give each agent its own **git worktree**, so there is no shared tree to
collide on.)

## Keep watching until told to stop

A quiet thread is **NOT** a stop signal. These sessions run for **hours** — a long build, a
slow deploy, or a human testing on prod can leave the thread silent for a very long stretch,
and that is normal. Keep re-running `watch` on every `exit 10`, indefinitely.

**You stop for exactly two reasons:** a `SESSION DONE` on the thread, or the human tells you
to. Nothing else. Not one hour of quiet, not several, not a hunch that "it looks done" or
"it looks dead," not a wish to "save resources." **Silence means keep listening, not give up.**

If you genuinely think the session should end, that is the human's call — ask on the thread
and wait. Do not pause or stand down on your own judgment.

## Start-up: align before you watch

First, work out whether you are the **first** agent or a **later** one — read the issue and
look at the thread.

### If you are the FIRST agent (empty thread — no one has set up the session)

There is no record to align to yet, so you align with the **human**. Do **NOT** jump straight
into announcing, deciding, or polling.

1. **Read the issue** and form your understanding.
2. **Sync with the human** in your own session — cover BOTH: **the issue** (understanding,
   gaps, any product/scope decision it needs) AND **the sprint shape** (how many agents, their
   roles, how the work breaks up).
3. **Wait for the go.** Do not announce, post a decision, or start `watch` until the human is
   happy and explicitly tells you to start.
4. **Hand the trigger back:** *"say the word and I'll announce and start watching."*

Settle any product/scope decision with the human here — do not decide it solo and post it.

### If you are a LATER agent (the thread already has the setup + your role)

Your alignment is **already on the thread** — do **NOT** sync with the human. Read the issue +
your assigned role, then announce and start watching. If you were told to hold for a
**coordinator's** go (e.g. `[you] go`), wait for **that**, not the human. The human is in the
loop for the first agent only. (If your role genuinely isn't defined on the thread, ask the
**coordinator** there — still not the human.)

### If you are an OBSERVER (auditor / reviewer of the session itself)

You are on the thread but **not on the work.** You write no code, gate nothing, and decide
nothing about the issue. Three differences from a working agent:

- **Use `audit`, not `watch`.** `watch` returns only mail addressed to you and **throws the
  rest away** — so the agent-to-agent traffic you exist to observe never reaches you. `audit`
  returns every new or edited comment, and your own comments never wake you.
- **Announce once, then go quiet.** Say you are read-only and that nobody should address you,
  report to you, or wait on you. Then stay silent. A chatty observer bends the session it is
  measuring; a completely silent one leaves no record it was ever there, which breaks the
  thread-is-the-truth rule.
- **Break silence only for a derailment,** and hand the fix to whoever owns the decision. Post
  the evidence, name the owner, and **do not act on their behalf.** Never post `SESSION DONE`.

```
"$POLL" audit "$ISSUE" "$ME" "$REPO" "$WM"
```

## Workflow

Set variables once. **The watermark path must be ABSOLUTE and cwd-independent** —
see the warning right below, it has already deadlocked a real sprint:

```
ISSUE=42
ME=Frank
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
HUMAN=$(gh api user -q .login)   # your human's real GitHub alias — derived, never asked
POLL=~/.claude/skills/multi-agent-session/poll-issue.sh

# Watermark: fixed location, immune to `cd` and to a session restart.
mkdir -p "$HOME/.claude/mas-state"
WM="$HOME/.claude/mas-state/$(printf '%s' "$REPO" | tr '/' '-')-${ISSUE}-${ME}.txt"
```

> ### ⚠️ NEVER use a relative watermark path
>
> **Bash cwd PERSISTS between tool calls in Claude Code.** A relative path like
> `tmp/mas-watermark-...` follows your cwd, so **one `cd` into a subdirectory points
> the same argument at a different, empty file.** An empty watermark baselines to the
> newest comment — so every message waiting for you is **silently swallowed. No error.
> No warning.**
>
> This is not hypothetical. On 2026-09-05 a BUILDER agent ran `init` from the project
> root, then `cd`-ed into a component repo to read code. Its next `watch` created a
> second watermark file and jumped straight past the `[BUILDER] go` that had landed in
> between. BUILDER waited forever for a go it had already been sent, the coordinator
> believed BUILDER was building, and the reviewer waited on BUILDER. **All three agents
> stopped**, and nothing on the thread showed anything was wrong.
>
> `$HOME/.claude/mas-state/` is used above **on purpose**, over the usual project
> `tmp/`: it cannot move when you `cd`, and it survives a session restart from a
> different directory. Every `init` / `peek` / `watch` call must pass the **same**
> absolute path.

**Step 1 — mark history as seen** (so you do not reprocess old comments):

```
"$POLL" init "$ISSUE" "$ME" "$REPO" "$WM"
```

**Step 2 — announce you are here:**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: [all] — online, watching #$ISSUE."
```

**Step 3 — make your opening move, if you have one.** Re-read the issue. Do you hold the
first action or a starting task assigned to you? If yes, DO it now and post the result
**before** you listen. If every agent only listens, nobody starts and the session deadlocks.
No opening move? Skip straight to listening.

**Step 4 — listen.** Run the watcher. It BLOCKS and spends zero tokens while waiting.
It returns only when there is real mail for you, a SESSION DONE, or it times out:

```
"$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"
```

Read the exit code:
- **0** → new mail printed. Handle it (see Step 5), then run `watch` again.
  - **Read the WHOLE batch before you act.** One `watch` can return several messages at
    once, and a later one may cancel or change an earlier one. Acting on the first line and
    ignoring the rest is how an agent ends up building the wrong thing while believing it is
    on spec.
  - A message may be flagged `*** EDITED AFTER YOU SAW IT ***`. That means text you already
    absorbed has changed under you — re-read it, because your earlier understanding is stale.
  - **If it means your goal is met** (your question is answered, the work is agreed or done),
    do not just fall silent — post `SESSION DONE` to close the session.
- **42** → SESSION DONE. Post `"$ME: signing off."` and stop. Tell the human.
- **10** → nothing yet. Just run `watch` again to keep listening.

If `watch` prints a **`WARNING — NO WATERMARK FOUND`** banner, stop and treat it as lost mail:
read the thread by hand and follow **When a message goes missing** above. Do not just carry on
watching — anything sent to you before that moment will never arrive.

**Step 5 — reply (only if needed):**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: [Builder] answer is X."
```

Then go back to Step 4. That loop IS the session.

## Common mistakes

| Mistake | Fix |
|---|---|
| Replying to every "ok / thanks" | Only reply if action is needed. Kill the echo. |
| Forgetting to sign or address | Every comment starts `Me:` and names `[who]`. |
| Addressing an agent with `@` | Use brackets — `[Reviewer]`. `@` is for real GitHub accounts; agent names collide with strangers' handles. |
| Re-answering old comments | Run `init` once at start; trust the watermark. |
| Polling with a tight loop in the LLM | Never. Use `watch` — it blocks in bash, not in tokens. |
| Guessing your identity | Ask the user. |
| Everyone listens, nobody starts | The agent with the first move acts BEFORE listening (Step 3). |
| First agent jumping straight into setup/decisions | The first agent aligns with the human on the issue AND the sprint plan (agent count, roles, breakdown) and waits for an explicit go before announcing / deciding / watching. |
| Later agent syncing with the human | Only the FIRST agent talks to the human. Later agents read their role from the thread and just go (or wait for a coordinator's go) — no human round-trip. |
| Goal met but nobody closes | When your objective is done or agreed, post `SESSION DONE`. Do not treat agreement as a silent ack. |
| Letting the record go stale | Post at each boundary (start / finish / decide / block). The thread is the source of truth. |
| Going heads-down silently | Say what you are doing and when you will resurface. Silence reads as stalled. |
| Asking the human out-of-band | Need the human? Post the blocker on the thread too, addressed to `@$HUMAN` — your own window is invisible to the team. |
| Reaching a peer with `SendMessage` | The issue is the only channel. No answer from someone? Post the blocker on the thread AND ask your human. |
| Guessing the human's `@` handle | Derive it: `HUMAN=$(gh api user -q .login)`. A guessed handle usually belongs to a different real person. |
| Building against stale instructions | Re-read the thread before you commit/deploy — a decision may have landed while you were heads-down. |
| `git add -A` on a shared tree | Commit only your own paths (`git add <files>`). A broad add captures a peer's in-flight work and may push it early. |
| Pausing / stopping on a quiet thread | Long silence is NOT a stop signal — re-arm through hours of quiet. You stop only on `SESSION DONE` or the human. |
| Writing the stop phrase in prose | Put `SESSION DONE` on its own line, nothing else — a mention inside a sentence used to false-trigger every watcher. |
| Theorising on a scary result before the cheapest check | An alarming reading gets ONE cheap isolated re-check first, not a fan-out of theories. See below. |
| Verifying on unstable ground | Don't test mid-deploy-propagation, and don't use a probe that dies before reaching the code. See below. |
| Inflating a minor finding into an epic | A minor limitation is a one-line note, not a multi-defect issue with a spec. |
| **Relative watermark path** | Use an absolute, cwd-proof path (`$HOME/.claude/mas-state/...`). Bash cwd persists between calls, so one `cd` orphans a relative watermark and mail vanishes with no error. **This has deadlocked a real sprint.** |
| Ignoring the `NO WATERMARK FOUND` banner | It means mail was probably lost. Read the thread by hand, then follow "When a message goes missing". |
| Copying a broken watermark to the fixed path | Copying keeps the value that caused the loss. **Rewind** to just before the lost message instead. |
| Re-sending only the trigger after lost mail | Re-post the **full** message. A bare "go" strips every decision and bound that rode with the original, and nobody can tell what is missing. |
| Acting on the first message in a batch | One `watch` can return several messages. Read them all — a later one may change an earlier one. |
| Assuming a silent agent is busy | Silence can mean lost mail. `peek` the thread and compare it against that agent's watermark before you wait any longer. |
| Auditing with `watch` | `watch` returns only mail addressed to you and **discards** everything else. An observer needs `audit`, which returns all traffic. |
| **Asking with `AskUserQuestion`** | It freezes your session, so you stop polling while the thread still says you are watching. Post the ask on the thread and go back to `watch`. |
| Posting "parked, watching" and then not watching | If you are not in `watch`, do not claim you are. A false status is worse than silence — it stops peers looking for the problem. |
| Assuming only the human can unblock you | State the blocker with the options you can see. A peer often answers before the human reads the thread. |
| Escalating without re-reading | `peek` first. The answer may already be on the thread — and a permission refusal may be blocking a step you do not actually need. |

## When a verification looks alarming — cheapest check FIRST

A scary result ("the whole feature is broken") invites elaborate root-cause **theories** — and in a multi-agent session, agents amplifying each other's theories. Two confident wrong reads in a row is the tell.

**Before anyone theorises, do the ONE cheapest check that could disprove the alarm:**

- **One clean call beats a big run.** A single hand-issued request (right inputs, one at a time) tells you more than an automated baseline.
- **Verify on solid ground.** A deploy isn't live when the pipeline says "succeeded" — wait for evidence it propagated. Testing mid-propagation produces phantom failures.
- **Check what layer answered.** Two `403`s from different layers look identical by status; the body (or a log line) shows which one — and whether your code even ran. A probe that errors before reaching your code proves nothing about it.

**Coordinator:** demand that one discriminating check before greenlighting a wide investigation or a scope change. Chasing a ghost costs real pipeline cycles — and real side effects (e.g. a live broadcast).

## Notes

- The watcher blocks up to ~9 min per call (under the 600s Bash timeout), then exits 10 so you re-run it. This is normal; **keep re-running — for hours if the task takes that long.** Idle time is never a reason to stop; only `SESSION DONE` or the human ends the watch.
- All agents share one GitHub login, so mail is matched by TEXT (`[name]` / `[all]`), not by author. That is why signing and addressing are mandatory.
- Modes: `init` (mark history seen) · `peek` (read without consuming) · `watch` (block for your mail) · `audit` (block for all traffic — observers).
- Every call prints the **resolved absolute** watermark path as its first line. If that path ever changes between calls, your cwd moved and your mail is at risk. Check it.
- Edit detection uses GitHub's `includesCreatedEdit` flag in `watch`, which reports the **first** edit to a comment. `audit` uses the REST API's `updated_at` and catches every edit. (`gh issue view --json comments` does not expose `updatedAt` — it returns `null`.)
