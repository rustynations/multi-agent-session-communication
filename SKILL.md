---
name: multi-agent-session
description: Use when this Claude Code session is one of several live agents collaborating on the same GitHub issue at once — a multi-agent session, distinct from spawning subagents. Triggers on /multi-agent-session (or /multiAgentSession), or a request to have two or more running sessions talk, coordinate, poll each other, or hand work off through a shared issue. Symptoms — "have the two terminals talk", "agents coordinate via the issue", spec/reviewer agent + builder agent working the same issue.
---

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

## The five golden rules

1. **Sign** every comment — start it with `<identity>:` (e.g. `Frank:`).
2. **Address** every comment — name who it is for: `@DocWriter` or `@all`.
3. **Watermark** — never re-read old comments. The poll script tracks this for you.
4. **Act only if it is for you AND needs action.** A plain "ok / thanks" ends the chain. Reply to it and you start an echo loop. Silence is allowed.
5. **Stop word** — if anyone posts `SESSION DONE` **on its own line**, stop the loop, sign off, wait for the human. When you post it, put it on its **own line, nothing else** — never inside a sentence. (A prose mention used to false-trigger every watcher; the poller now only matches a standalone line, but keep it clean.)

Ignore your own comments. Frank never acts on Frank.

## Keep the record current

The issue is the shared source of truth. **If it isn't on the thread, no one — agent or
human — can see it.** Post an update (signed, `@all` unless it is for someone), then keep
working — do NOT wait for a reply — when any of these happen:

- You **start** a distinct piece of work, or **change your plan.**
- You **finish** a unit of work — a commit, a deploy, a verification — with the **raw evidence**, not just "done."
- You **make or change a decision.**
- You hit a **blocker — including needing the human** (expired login, a decision, a manual
  check), hand off, or **stand down.** Post it on the thread even if you also ask the human
  in your own window: an out-of-band ask is invisible to the team, and the thread just looks
  like you are working.
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

This is the listening half of the record: post at your boundaries, and **read at them too.**

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
**coordinator's** go (e.g. `@you go`), wait for **that**, not the human. The human is in the
loop for the first agent only. (If your role genuinely isn't defined on the thread, ask the
**coordinator** there — still not the human.)

## Workflow

Set variables once (use the project `tmp/` for the watermark file):

```
ISSUE=42
ME=Frank
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
WM=tmp/mas-watermark-${ME}-${ISSUE}.txt
POLL=~/.claude/skills/multi-agent-session/poll-issue.sh
```

**Step 1 — mark history as seen** (so you do not reprocess old comments):

```
"$POLL" init "$ISSUE" "$ME" "$REPO" "$WM"
```

**Step 2 — announce you are here:**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: @all — online, watching #$ISSUE."
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
  - **If it means your goal is met** (your question is answered, the work is agreed or done),
    do not just fall silent — post `SESSION DONE` to close the session.
- **42** → SESSION DONE. Post `"$ME: signing off."` and stop. Tell the human.
- **10** → nothing yet. Just run `watch` again to keep listening.

**Step 5 — reply (only if needed):**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: @Builder answer is X."
```

Then go back to Step 4. That loop IS the session.

## Common mistakes

| Mistake | Fix |
|---|---|
| Replying to every "ok / thanks" | Only reply if action is needed. Kill the echo. |
| Forgetting to sign or address | Every comment starts `Me:` and names `@who`. |
| Re-answering old comments | Run `init` once at start; trust the watermark. |
| Polling with a tight loop in the LLM | Never. Use `watch` — it blocks in bash, not in tokens. |
| Guessing your identity | Ask the user. |
| Everyone listens, nobody starts | The agent with the first move acts BEFORE listening (Step 3). |
| First agent jumping straight into setup/decisions | The first agent aligns with the human on the issue AND the sprint plan (agent count, roles, breakdown) and waits for an explicit go before announcing / deciding / watching. |
| Later agent syncing with the human | Only the FIRST agent talks to the human. Later agents read their role from the thread and just go (or wait for a coordinator's go) — no human round-trip. |
| Goal met but nobody closes | When your objective is done or agreed, post `SESSION DONE`. Do not treat agreement as a silent ack. |
| Letting the record go stale | Post at each boundary (start / finish / decide / block). The thread is the source of truth. |
| Going heads-down silently | Say what you are doing and when you will resurface. Silence reads as stalled. |
| Asking the human out-of-band | Need the human? Post the blocker on the thread too — your own window is invisible to the team. |
| Building against stale instructions | Re-read the thread before you commit/deploy — a decision may have landed while you were heads-down. |
| `git add -A` on a shared tree | Commit only your own paths (`git add <files>`). A broad add captures a peer's in-flight work and may push it early. |
| Pausing / stopping on a quiet thread | Long silence is NOT a stop signal — re-arm through hours of quiet. You stop only on `SESSION DONE` or the human. |
| Writing the stop phrase in prose | Put `SESSION DONE` on its own line, nothing else — a mention inside a sentence used to false-trigger every watcher. |

## Notes

- The watcher blocks up to ~9 min per call (under the 600s Bash timeout), then exits 10 so you re-run it. This is normal; **keep re-running — for hours if the task takes that long.** Idle time is never a reason to stop; only `SESSION DONE` or the human ends the watch.
- All agents share one GitHub login, so mail is matched by TEXT (`@name` / `@all`), not by author. That is why signing and addressing are mandatory.
