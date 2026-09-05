---
name: multi-agent-session
description: Use when this Claude Code session is one of several live agents collaborating on the same GitHub issue at once — a multi-agent session, distinct from spawning subagents. Triggers on /multi-agent-session (or /multiAgentSession), or a request to have two or more running sessions talk, coordinate, poll each other, or hand work off through a shared issue. Symptoms — "have the two terminals talk", "agents coordinate via the issue", spec/reviewer agent + builder agent working the same issue.
---
<!-- Version: 2026-09-05.11 -->

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
2. **Your identity** — a readable role name, e.g. `ARCHITECT`, `BUILDER`, `REVIEWER`

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

> **So an `@$HUMAN` ask is INVISIBLE, and that is dangerous.** You post a blocker, the human
> is never told, and to anyone glancing at the thread you simply look busy. An agent can wait
> like that indefinitely.
>
> When you genuinely need the human:
> 1. **Post the ask on the thread** — that is the record, and a peer may answer it.
> 2. **Also say it in your own window as plain text** — a short, visible "I am blocked on X,
>    I need you to decide Y." Not a prompt: **never `AskUserQuestion`** (rule 7), because that
>    stops you polling and the answer may already be on its way.
> 3. **Go back to `watch`** and keep listening while you wait.
>
> If you are the human's *only* live agent and nothing moves, that is your human's cue to
> check the thread. Consider naming the wait explicitly: *"holding on @$HUMAN; nobody else
> can unblock this."*

## The seven golden rules

1. **Sign** every comment — start it with `<identity>:` (e.g. `Frank:`).
2. **Address** every comment — name who it is for in **square brackets**: `[DocWriter]`
   or `[all]`. Brackets, never `@`. **`@` is reserved for real GitHub accounts.** Any
   obvious agent name is also somebody's real GitHub handle — `@`-mentioning one on a
   public issue notifies a stranger, and no prefix is safe (adding `agent-` does not
   help; those are taken too). `[Builder]` belongs to no namespace, so it never collides.
3. **Watermark** — never re-read old comments. The poll script tracks this for you.
4. **Act only if it is for you AND needs action.** A plain "ok / thanks" ends the chain. Reply to it and you start an echo loop. Silence is allowed.
5. **Stop word** — the signal is **`[SESSION DONE]`**, in brackets, and it is matched **anywhere**
   in a comment. When you see one: stop the loop, sign off, wait for the human. Brackets are
   already the signal namespace, so a bracketed stop can never be mistaken for prose.
   - **To end a session:** post `[SESSION DONE]`. Position does not matter.
   - **To talk ABOUT the stop word:** write it **without** brackets — `SESSION DONE` inside a
     sentence does not trigger. Writing the bracketed form in prose **will** stop everyone,
     the same way a stray `@handle` pings a stranger.
   - **Quoting it is now safe.** The matcher ignores anything markdown renders as code or quoted
     text — fences, inline code, blockquotes, indented blocks. The token tripped watchers **five
     times** across two sprints and *every* trip was a quote, while every real close was bare
     prose. Pasting raw evidence verbatim is the rigorous instinct, so this is fixed in the parser,
     not by asking you to be careful. **Typing it bare in prose is still a live wire** — that is a
     choice, not an instinct, so it stays your job.
   - **There is no positional rule, on purpose.** Every genuine close appended the token to a
     sign-off. "Own line" or "start of comment" would turn a loud false trip into a **silent
     miss** — and rule 1 requires comments to start with `IDENTITY:`, so a start-anchored token
     could only fire from a comment that breaks rule 1.
   - **The old form no longer works.** A bare `SESSION DONE` on its own line used to trigger a
     stop. It does not any more — but `watch` **shouts** when it sees one, because a live session
     holds the old skill text in its context even after the repo updates, so an agent can emit the
     old form believing it ended the session. Never a silent no-op.
6. **Never use `SendMessage`.** The issue is the only channel — no wire between
   terminals. Direct session-to-session messages leave **no record**: your human cannot
   read them, a restarted agent cannot recover them, and an agent that is not on this
   machine never sees them. If you cannot get a response from an agent you need, post
   the blocker on the thread addressed to `@$HUMAN` **and** ask your human in your own
   window. Do not route around the bus.
7. **Run the watcher in the BACKGROUND, via your harness's background flag.** This is the
   structural fix that makes the rest of the loop safe, so it is a rule rather than a tip.
   Requirements, all three learned the hard way — three agents found three different ways to
   break this in one sprint (2026-09-05):
   - **Its own tool call.** Never folded into a compound command.
   - **Read the output every time.** The output IS the mail. A shell `&` or a `>/dev/null`
     detaches the poller: it still collects your mail and still advances your watermark, then
     bins it. No error, nothing wrong on the thread, and you look busy.
   - **One at a time.** Never arm a second watcher against the same watermark file.

   **Consequence — do not block on a prompt while watching.** `AskUserQuestion` (or anything that
   waits for a person) freezes a FOREGROUND session, so you stop polling while the thread still
   says you are watching. An agent did this, posted *"Parked, watching"*, and sat frozen while the
   coordinator's answer landed 55 seconds later. Backgrounding removes the hazard; the ban is the
   seatbelt for when you have not. The one exception is the FIRST agent's alignment with the human
   before its first `watch` — nobody expects you on the bus yet.

   **Self-check, because a rule you just read will not stop you but a number will:**
   ```
   cat "$WM"          # what has been consumed
   ```
   A watermark **ahead** of the newest comment you have actually read proves something was
   delivered and discarded. Recover with `peek`, then say on the thread that you lost mail.

Rules 6 and 7 guard the same thing from two sides. `SendMessage` leaves **no record**; a detached
or blocked watcher leaves you **deaf**. Both route around the bus, and the bus is the only thing
every agent can hear.

Ignore your own comments. Frank never acts on Frank.

## Address the AGENT WHO ACTS, not the agent who asked

When you answer a question, name **everyone who has to act on the answer** — which is usually
not just whoever asked you.

A coordinator was asked whether to promote to prod. The human answered, addressed to the
**coordinator**. But the agent that actually pushes was the **reviewer**, who was not named — so
the reviewer's `watch` classified the approval as not-for-it, marked it seen, and **discarded
it**. The reviewer then correctly refused to push, holding for an approval that already existed
and that it could never receive. The sender got no error either. (2026-09-05; the reviewer later
confirmed it from the inside: *"my filter dropped it and marked it seen."*)

**So:**
- Answering a question? Address **the asker AND the doer.** When unsure, use `[all]`.
- Announcing a **decision, a release, or an authorization**? `[all]`. A decision is never private.
- Waiting on an answer that "should have come by now"? It may have been sent to somebody else.
  `peek` the thread — `watch` cannot show you what it already discarded.

This is the same silent-loss family as an orphaned watermark: **nothing failed, a message simply
was not there.** Both were found by someone noticing an absence, not by an error.

## Authority scales with reversibility

A **relayed** approval is fine for a preference. It is **not** authority for an action you
cannot walk back — a push to prod, a force-push, a delete, anything outward-facing.

**Authorization must be READABLE BY THE AGENT TAKING THE ACTION** — not relayed, not quoted.
A faithful quote and a mistaken one are indistinguishable to the receiver, so *"in their own words,
in my session"* is still a relay to everyone else. Two agents derived this separately, mid-sprint,
on the least reversible action in the session, and both were right.

**So a coordinator cannot relay authority for a one-way action at all.** Its job is to get the
human to post it **where the actor can read it** — on the thread, addressed to the actor.

**One narrow exception, and it must be pre-announced:** if you state the gate in advance —
*"tell me when X finishes and I will do Y"* — then the human clearing that named gate IS
authorization. If you did not pre-announce it, a status report is not an instruction.

For those, require the decision **firsthand from whoever owns it**, and say so plainly:
*"I have the relay; I am holding for your own words because this touches prod."* Holding a
one-way action once too often is much cheaper than releasing it once too early. When an agent
does hold on you for this reason, **say it was the right call** — you want that instinct kept.

And check the shape of the action before you gate it. A push that a pipeline turns into a
**live deploy** is not a staged artifact awaiting a separate step; it IS the deploy. Read the
pipeline's source-branch config rather than assuming there is another gate after yours.

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

**Open every comment with ONE line: evidence, decision, what happens next.** Detail goes below it.
This is not a length limit — a ceiling gets abandoned the first time something genuinely needs
explaining. It is a *lead*, and it is checkable.

Why it is a rule: a debrief of two sprints found the same top problem from all three agents.
*"An omission gets called out, length never does."* One thread ran to ~25 comments, several over
5,000 characters, and **the coordinator closed over a builder's objection specifically because it
was buried in volume** — every endgame failure was downstream of a thread nobody could scan.
**Bound the narrative, not the evidence:** a file-and-line trace earns its length; the paragraphs
around it do not.

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

**There are only TWO mechanisms.** Seven incidents across three sprints all reduce to these, and
the split matters because **only one of them yields to being careful:**

| | **Delivery side** — it never entered your output | **Reading side** — it entered, nobody read it |
|---|---|---|
| **Causes** | Orphaned watermark (relative path + a `cd`) · addressed to the agent who **asked**, not the one who **acts** · a misspelled name your filter rejects · **no watcher armed at all** (`init` is not `watch`) | Poller backgrounded with shell `&` · output sent to `/dev/null` · two watchers armed and only one output file read |
| **What you see** | Your poller runs, reads fine, and truthfully says "no mail" about a set that never held the message | Nothing. There is no output to read, or it went in the bin |
| **The fix** | **Not reachable by discipline.** You cannot read your way out of a poller pointed at the wrong file. Only the machine noticing and shouting helps — the `NO WATERMARK FOUND` banner and the `init` banner exist for this | **Discipline, and it is one sentence: one armed watcher, one output file read.** Held every time it was tested |

**Neither side errors, and the sender gets no feedback either way.** That is why an absence has
to be actively looked for.

**A rule you break while looking at it belongs in the machine.** All three agents of one sprint
broke the one-watcher rule inside an hour — two of them minutes after reading a written analysis
of someone else breaking it. That is why `watch` and `audit` now **refuse to start** when a live
watcher already holds the watermark, rather than asking you to remember.

### Is a peer actually listening?

**The rule is the peer's own acknowledgement.** Ask, and wait for them to say so. Only the peer
can tell you a message was *delivered* — and **consumed is not delivered.** A watermark advancing
proves a poller ate the comment; a poller binning its output to `/dev/null` eats it exactly the
same way.

**The shortcut, when every agent shares one filesystem:** read the peer's watermark and see
whether it moved past your message. Cheaper and more direct than reading a transcript, and it is
the artifact the protocol actually depends on.

```
"$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 20        # what was actually said
cat "$HOME/.claude/mas-state/<repo>-<issue>-PEER.txt"  # what that peer has consumed
ls -la "$HOME/.claude/mas-state/" | grep "$ISSUE"   # TWO files for one agent = orphaned
```

> ⚠️ **An absent watermark file means "I cannot tell" — never "they are not listening."**
> Agents on separate machines, containers or cloud sessions do not share
> `~/.claude/mas-state/`, so every healthy peer would look deaf. Check that they share a
> filesystem before you read anything into a missing file, and fall back to asking them.

> **⚠️ Reading the thread by hand? Always pass `--paginate`.**
> `gh api .../issues/N/comments` returns only the **first 30** comments. Past that, a
> hand-written check silently stops seeing the newest ones — so a message that exists looks
> missing, and you can "confirm" a problem that was already fixed. This bit the auditor of the
> very sprint that produced these rules: it declared a decision missing from a query
> structurally unable to see it.
> ```
> gh api "repos/$REPO/issues/$ISSUE/comments" --paginate    # correct
> ```
> `watch` and `peek` are safe — `gh issue view --json comments` paginates internally — and
> `audit` passes `--paginate` explicitly. **Only your ad-hoc commands are exposed.**

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

- **Pushing a branch you do not have checked out leaves your LOCAL ref stale.** Promoting with
  `git push origin <sha>:main` while standing on another branch updates the remote and
  `origin/main` — but the local `main` pointer does **not** move. Everything is correct on GitHub
  and wrong on disk, so the next session checks out `main`, sees the old commit, and concludes
  prod is behind. (Caught at the close of the founding sprint, 2026-09-05.) After any push you
  did not make from that branch, reconcile it:
  ```
  git fetch origin
  git rev-parse main origin/main         # must match
  git ls-remote origin main              # and match GitHub
  git update-ref refs/heads/main origin/main   # if it does not
  ```
  Do it locally. Nothing needs pushing — the remote was already right.

(Structural alternative: give each agent its own **git worktree**, so there is no shared tree to
collide on.)

## Keep watching until told to stop

A quiet thread is **NOT** a stop signal. These sessions run for **hours** — a long build, a
slow deploy, or a human testing on prod can leave the thread silent for a very long stretch,
and that is normal. Keep re-running `watch` on every `exit 10`, indefinitely.

**You stop for exactly two reasons:** a `[SESSION DONE]` on the thread, or the human tells you
to. Nothing else. Not one hour of quiet, not several, not a hunch that "it looks done" or
"it looks dead," not a wish to "save resources." **Silence means keep listening, not give up.**

If you genuinely think the session should end, that is the human's call — ask on the thread
and wait. Do not pause or stand down on your own judgment.

### If the last open item belongs to your human, post a heartbeat

**Make the silence legible instead of ambiguous.** When everything is built, pushed and verified
and the only thing left needs a person, a long quiet stretch is indistinguishable from a deadlock
to anyone reading the thread — including the human, who may not know they are the blocker.

After a stretch of quiet, the coordinator posts one comment:

- **the state table, frozen** — every item and where its evidence is
- **the one open item, and who owns it** — by name
- **that nothing is degrading and nothing needs re-running**
- **"quiet is not a stop signal"**
- **that the other agents are not being waited on**, and an offer to record a stand-down if one
  needs to stop before the close

Then keep watching. Observed working (2026-09-05): 65 minutes of quiet while a human was away, and
one heartbeat turned "is this dead?" into a legible hold — costing one comment.

**Do not build a timeout instead.** A timeout stands agents down on a clock, which is exactly the
judgment call the rule above reserves for the human. A heartbeat is cheaper and it removes the
ambiguity that made a timeout look attractive.

## Closing the session — drain the thread first

> **Issue status is not session status.** A session ends on the stop token plus every sign-off,
> and on nothing else. Whether the issue is open or closed is bookkeeping — it starts nothing,
> ends nothing, and is not a signal to act on. A closed issue still accepts comments, and every
> watcher still reads them, so an issue closed early changes no agent's behaviour and blocks no
> work. **Do not treat a state change as an instruction, and do not stand down because a tracker
> says you are done.** Observed on `gotjeep.com-project#182` (2026-09-05): a commit trailer closed
> the issue ~1h46m before the last acceptance check, three agents kept working normally, and the
> only real cost was a tracker that briefly asserted "done" too early.

With several agents writing at once, **a close always races them.** Someone is usually mid-post
when you decide it is over, and their comment lands after your close comment — unread, unanswered,
and looking like it was ignored.

Observed (2026-09-05), inside 14 seconds:

```
16:35:59  a builder raises an unverified check
16:36:03  the coordinator posts "done ... closing now" + the stop token
16:36:13  the reviewer posts the very verification the close depended on
```

Neither could be absorbed. So, before you close:

1. **Post a last call** — `[all] closing in ~60s unless someone objects` — then `watch` through it.
   One cheap round trip lets in-flight work land.
2. **An objection BLOCKS the close until you state its disposition.** Precedence, not timing —
   `peek` "immediately before" cannot work when the close comment takes minutes to write, and a
   coordinator missed a 44-second-old objection while doing exactly that.
   - **An objection must be declared: `OBJECT:` as the first thing in the comment.** The closer
     matches a token, not prose. This is why: one last-call comment opened *"NO OBJECTION to
     closing"* and then said a line must be fixed **before** the close. Both, in one comment.
   - **A named limitation is not an objection.** Otherwise every honest caveat blocks forever.
   - **Answered = you state the disposition: applied, or "raised and consciously deferred."**
     The objector confirming is better, never required — one idle agent must not stall a close.
3. **Name an OWNER for every open item.** `item → owner → done/deferred`. Two agents each
   declining to touch a shared file, to avoid racing a peer, is indistinguishable from nobody
   noticing it — and that produced the only defect that outlived a sprint.
4. **Read the thread AFTER the close comment is written, not before.** The writing is where the
   race lives.
5. **FILO — the agent that opened the session signs off LAST, and it OWNS the endgame.** Not
   courtesy. A coordinator posting the stop token while two agents still had open items orphaned a
   finding, left a reviewer holding an offer nobody could answer, and killed an observer's watcher
   before it could sign off. *"That one act caused every failure of the endgame."*

   **FILO without a wait is only a preference. The procedure is:**

   1. **Release the team** — post the stop token and say plainly that they are released, that
      nothing is assigned to them, and that they do not need to wait for you.
   2. **Build the roster from the thread**, not from memory. Everyone who has signed a comment is
      playing:
      ```
      gh api "repos/$REPO/issues/$ISSUE/comments" --paginate -q '.[].body' \
        | grep -oE '^[A-Za-z][A-Za-z0-9_-]*:' | tr -d ':' | sort -u
      ```
   3. **Wait for every agent on that roster to sign off, and CHECK — do not assume.** Silence is
      not consent. A missing sign-off can mean a dead session, a watcher whose output was
      discarded, or an agent that never received the release at all.
   4. **If someone has not signed off after about one watch cycle, tell your human** — name who is
      missing and that you are holding the close for them. Do **not** close over a silent agent:
      their session is still live and their terminal is the only place anyone can see it. This is
      the one endgame step that needs a person.
   5. **Do a final read immediately before your own sign-off.** Last chance for an `OBJECT:`, and
      the writing of your sign-off is itself a window in which something can land.
   6. **Then sign off, then close, then verify the close** (step 6 below).
6. **Verify the close actually closed it — so you do not report something false.** `gh issue
   close` **exits 0 on an already-closed issue**, so a coordinator can announce "closing now"
   about something closed hours earlier and nothing will contradict it.
   ```
   gh issue view "$ISSUE" --repo "$REPO" --json state,closedAt
   ```
   A `closedAt` earlier than your own close means somebody beat you to it — most often a commit
   trailer, which fires on **push**, and therefore before any verification. Say what actually
   happened instead of claiming the close.

   **This is about honest reporting, not about the session.** See the note below: the issue's
   open/closed state has no authority over whether you are finished.
7. **Verify YOUR OWN item landed.** The closer drains the thread; nobody else is told to confirm
   their item was applied. One raised item was acknowledged, implied handled, and not done — the
   line had **moved**, not changed, because a section was inserted above it. **A line moving down
   a file looks exactly like a file that changed.** One command.

## Rejoining after you have stopped

**On rejoin, do NOT run `init`.** `init` re-baselines to the newest comment, so the documented
setup step is a **guaranteed silent-loss mode for a returning agent** — the one path where unread
mail certainly exists. It happened: a rejoining agent's `init` skipped two peers' answers, and it
only had them because it read the thread by hand out of habit.

- Watermark still exists? **Read from it forward**, then watch.
- No watermark? **Read the whole thread**, then watch.

## The spec itself is a defect source

The most serious findings of two sprints were **defects in the work order**, not in the code:
a work item naming the wrong lambda (which would have blanked the very column the issue was
about), and an out-of-scope list that silently broke account erasure. Three of seven items in one
order were wrong.

- **Read the spec against the code BEFORE you build, and report every mismatch.** Both builders
  did this unprompted and it is where everything real came from. Findings are cheapest before a
  line is staged.
- **The coordinator re-derives a finding before amending the work order.** Every time a coordinator
  checked a peer's report, the defect it found was its own — because checking the report is what
  made it read the code it had wrongly excluded.
- **Read the project's own docs first.** A coordinator's unread doc becomes three agents' wrong
  belief. One session spent two separate hours re-deriving what was written in the project's memory
  file. In a solo session that costs you; here it propagates.

**When you correct one work item, re-check the items already FINISHED.** A correction does not only
change what is left to build — it can rot something already done and signed off.

> **The edit that goes stale is not the one you are editing.**

Live example (2026-09-05): a coordinator's correction moved a rationale from one doc to another.
That was right. But a *completed and verbatim-correct* item still carried a pointer to the doc the
rationale had just been **deleted from** — so a future reader following it would land somewhere
that no longer explained anything, which was the exact failure the issue existed to prevent. The
builder had written that pointer four minutes earlier and never re-read it; the coordinator caught
it only by reading the working tree while the builder was still typing.

Neither the author of the correction nor the author of the stale line will find it by re-reading
their own work. **Ask what your correction just made untrue elsewhere.**

## If you write the spec: numbering is not ordering

Work items numbered `W1…W6` invite every reader to treat the numbers as the running order. They
usually are not: a verification step often has to run **after** a deploy that is numbered later.
A reviewer had to stop and ask which came first (2026-09-05).

**State the chronological order explicitly, separately from the item numbers:**

```
gate → push → green AND propagated → W5 verification → W6 pentest → close
```

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
  the evidence, name the owner, and **do not act on their behalf.** Never post `[SESSION DONE]`.

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
It returns only when there is real mail for you, a `[SESSION DONE]`, or it times out:

```
"$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"
```

> ### Run the watcher in the BACKGROUND — via the HARNESS, never with `&`
>
> **Use your harness's own background flag** (Claude Code: `run_in_background`, or `ctrl+b`).
> It captures the output and wakes you when the command returns.
>
> ```
> "$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"          # + run_in_background / ctrl+b
>
> "$POLL" watch ... > /dev/null 2>&1 &                # ☠️ DESTROYS YOUR MAIL
> "$POLL" watch ... &                                 # ☠️ output goes nowhere you will read
> ```
>
> A shell `&` detaches the poller from you. It still runs, still collects your mail, and still
> **advances your watermark** — then throws the mail away. No error. Nothing on the thread looks
> wrong. You look busy. An agent did exactly this and lost its human's own message (2026-09-05).
>
> **Never redirect the output either.** The output IS the mail.
>
> **Cheap self-check, and it is how that agent caught itself:** compare your watermark against
> the newest comment you have actually read.
> ```
> cat "$WM"                                        # what has been consumed
> ```
> A watermark **ahead** of your own reading is proof that something was delivered and discarded.
> Recover it with `peek`, then say on the thread that you lost mail so senders can re-send.
>
> You are re-invoked when a harness-backgrounded watch returns, so you lose nothing — and you gain
> the single best property in this whole protocol:
>
> **You keep listening AND stay reachable at the same time.**
>
> A foreground watcher makes your session unreachable for ~9 minutes at a stretch. Your human
> cannot ask you anything, and if you ever stop to prompt them you go **deaf** (rule 7). Both
> problems disappear when the watcher runs in the background.
>
> This is measured, not theoretical. In the founding sprint (2026-09-05) all three working agents
> polled in the **foreground**; two of them went deaf on a prompt, and one had to be rescued by
> hand. The observer polled in the **background**, talked to its human continuously, and never
> missed a comment — including one that a foreground watcher had already discarded.
>
> **Prefer the structural fix to the disciplinary one.** Rule 7 is the seatbelt; backgrounding is
> not crashing.

Read the exit code:
- **0** → new mail printed. Handle it (see Step 5), then run `watch` again.
  - **Read the WHOLE batch before you act.** One `watch` can return several messages at
    once, and a later one may cancel or change an earlier one. Acting on the first line and
    ignoring the rest is how an agent ends up building the wrong thing while believing it is
    on spec.
  - A message may be flagged `*** EDITED AFTER YOU SAW IT ***`. That means text you already
    absorbed has changed under you — re-read it, because your earlier understanding is stale.
  - **If it means your goal is met** (your question is answered, the work is agreed or done),
    do not just fall silent — post `[SESSION DONE]` to close the session.
- **42** → `[SESSION DONE]`. Post `"$ME: signing off."` and stop. Tell the human.
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
| Goal met but nobody closes | When your objective is done or agreed, post `[SESSION DONE]`. Do not treat agreement as a silent ack. |
| Letting the record go stale | Post at each boundary (start / finish / decide / block). The thread is the source of truth. |
| Going heads-down silently | Say what you are doing and when you will resurface. Silence reads as stalled. |
| Asking the human out-of-band | Need the human? Post the blocker on the thread too, addressed to `@$HUMAN` — your own window is invisible to the team. |
| Reaching a peer with `SendMessage` | The issue is the only channel. No answer from someone? Post the blocker on the thread AND ask your human. |
| Guessing the human's `@` handle | Derive it: `HUMAN=$(gh api user -q .login)`. A guessed handle usually belongs to a different real person. |
| Building against stale instructions | Re-read the thread before you commit/deploy — a decision may have landed while you were heads-down. |
| Pushing a branch you are not standing on | Your local ref stays stale — GitHub is right, disk is wrong. `git fetch` then compare `main` / `origin/main` / `ls-remote`. |
| `git add -A` on a shared tree | Commit only your own paths (`git add <files>`). A broad add captures a peer's in-flight work and may push it early. |
| Pausing / stopping on a quiet thread | Long silence is NOT a stop signal — re-arm through hours of quiet. You stop only on `[SESSION DONE]` or the human. |
| Writing the bracketed stop token in prose | `[SESSION DONE]` triggers **anywhere** in a comment. To discuss the stop word, write it **without** brackets. |
| Theorising on a scary result before the cheapest check | An alarming reading gets ONE cheap isolated re-check first, not a fan-out of theories. See below. |
| Verifying on unstable ground | Don't test mid-deploy-propagation, and don't use a probe that dies before reaching the code. See below. |
| Inflating a minor finding into an epic | A minor limitation is a one-line note, not a multi-defect issue with a spec. |
| **Relative watermark path** | Use an absolute, cwd-proof path (`$HOME/.claude/mas-state/...`). Bash cwd persists between calls, so one `cd` orphans a relative watermark and mail vanishes with no error. **This has deadlocked a real sprint.** |
| Ignoring the `NO WATERMARK FOUND` banner | It means mail was probably lost. Read the thread by hand, then follow "When a message goes missing". |
| Copying a broken watermark to the fixed path | Copying keeps the value that caused the loss. **Rewind** to just before the lost message instead. |
| Re-sending only the trigger after lost mail | Re-post the **full** message. A bare "go" strips every decision and bound that rode with the original, and nobody can tell what is missing. |
| Acting on the first message in a batch | One `watch` can return several messages. Read them all — a later one may change an earlier one. |
| Assuming a silent agent is busy | Silence can mean lost mail. `peek` the thread and compare it against that agent's watermark before you wait any longer. |
| No lead line on a comment | Open with one line: evidence, decision, what happens next. A thread nobody can scan is how a close ran over an objection. |
| Closing over a silent agent | Silence is not consent. Check every signature on the roster; if one is missing after ~a watch cycle, tell your human — their terminal is the only place it is visible. |
| Coordinator signing off first | FILO. The opener signs off last, or it strands decisions and orphans open items. |
| Treating a caveat as an objection, or missing a real one | An objection says `OBJECT:` first. A named limitation is not one. Answered = you state applied or consciously deferred. |
| Leaving a last-call item unowned | `item → owner → done/deferred`. Two agents each avoiding a shared file looks exactly like nobody noticing. |
| Running `init` on rejoin | It re-baselines to newest and swallows the mail you came back for. Read from your watermark forward instead. |
| Relaying authority for a one-way action | It is not readable by the actor. Get the human to post it on the thread, addressed to the actor. |
| Re-reading your own claim and calling it verified | 5/5 real catches came from a peer or a tool, never from an author re-reading. Get the method checked. |
| Citing line numbers to a peer on a live tree | They go stale in a minute. Quote the text and give the check, not the coordinates. |
| Verifying only after the run | Write the predictions first and mark which correct results will look alarming. |
| Building the spec as written | Read it against the code first and report mismatches. Three of seven work items in one order were wrong. |
| Polling in the foreground | Background the watcher via the harness flag. A foreground poll makes you unreachable for ~9 min, and any prompt then makes you deaf. |
| **Backgrounding with `&` or redirecting the output** | The poller consumes your mail, advances the watermark and bins it — silently. Use the harness's background flag; the output IS the mail. |
| Not checking your own watermark | `cat "$WM"`. A watermark AHEAD of the newest comment you actually read proves mail was consumed and discarded. |
| Auditing with `watch` | `watch` returns only mail addressed to you and **discards** everything else. An observer needs `audit`, which returns all traffic. |
| **Asking with `AskUserQuestion`** | It freezes your session, so you stop polling while the thread still says you are watching. Post the ask on the thread and go back to `watch`. |
| Posting "parked, watching" and then not watching | If you are not in `watch`, do not claim you are. A false status is worse than silence — it stops peers looking for the problem. |
| Assuming only the human can unblock you | State the blocker with the options you can see. A peer often answers before the human reads the thread. |
| Escalating without re-reading | `peek` first. The answer may already be on the thread — and a permission refusal may be blocking a step you do not actually need. |
| **Answering only the agent who asked** | Address **the doer too**, or `[all]`. A decision sent only to the asker never reaches whoever has to act on it. |
| Treating a relayed approval as authority for a one-way action | Fine for a preference. For a prod push / force-push / delete, require the owner's own words. |
| Closing while peers are mid-post | Post a last call, `watch` through it, then `peek` immediately before the close. |
| Trusting `gh issue close` to have closed it | It exits 0 on an already-closed issue. Check `state` **and** `closedAt`. |
| Reading the thread with `gh api` and no `--paginate` | You only see the first 30 comments, so recent messages look missing. |
| Numbering work items and calling it the order | State the chronological sequence separately from the item numbers. |
| Verifying only the after-state | Capture the "before" number while it still exists, and rehearse the check against the old build. |
| Silently skipping a check | Name the omission and the reason. A skipped check and a forgotten one look identical later. |

## When a verification looks alarming — cheapest check FIRST

A scary result ("the whole feature is broken") invites elaborate root-cause **theories** — and in a multi-agent session, agents amplifying each other's theories. Two confident wrong reads in a row is the tell.

**Before anyone theorises, do the ONE cheapest check that could disprove the alarm:**

- **One clean call beats a big run.** A single hand-issued request (right inputs, one at a time) tells you more than an automated baseline.
- **Verify on solid ground.** A deploy isn't live when the pipeline says "succeeded" — wait for evidence it propagated. Testing mid-propagation produces phantom failures.
- **Check what layer answered.** Two `403`s from different layers look identical by status; the body (or a log line) shows which one — and whether your code even ran. A probe that errors before reaching your code proves nothing about it.

**Coordinator:** demand that one discriminating check before greenlighting a wide investigation or a scope change. Chasing a ghost costs real pipeline cycles — and real side effects (e.g. a live broadcast).

### Best of all: write the predictions down BEFORE the run

**Before a deploy, write what each check will return, and mark every expected-but-alarming result
as expected.** A prediction made before the run outranks any explanation after it.

Everything else in this section is **reactive** — it helps once something already looks wrong.
This is **preventive**: it makes the alarm unable to fire. In one sprint four correct-but-alarming
results were named in advance and not one became a false alarm. The sharpest: a verification step
said *"the column must show a real value, not `—`"*, but against pre-existing rows a blank column
was **guaranteed and correct**. Reported literally it reads as a broken fix and very likely
triggers a rollback; predicted in advance it is a pass.

A second payoff, observed: the *act* of committing to falsifiable predictions is itself a
discriminating check. One contradiction surfaced while the predictions were being written, not
during any review.

**This applies hardest when you hand the check to your HUMAN.** They will report literally what
they see, and they have none of your context about what a benign failure looks like — so an
expected-but-alarming result comes back as *"it did not ship."*

Observed (2026-09-05): an agent gave a human a "read the dialog on staging" step with no
prediction. The screenshot showed the **old** copy, which reads as total failure. The human had a
page open from **before** the deploy and had not reloaded it. One `curl` against the live asset
proved the served bytes were correct, and nothing was changed. **Had the step said "reload the page
before you read it", the alarm could not have fired.** A prediction written for the next step held,
and that one came back clean.

**A sharp correction from that same incident, worth more than the rule it sits under.** The agents
concluded "stale client" — correct — and then attributed it to a cached `index.html` pointing at an
older asset hash. **That mechanism was wrong**, and the `curl` did not test it: the check proved the
*conclusion* (the deploy is fine), not the *explanation*. The theory was plausible and cheap to
check, and nobody checked it. **A discriminating check that confirms your conclusion does not
license the story you attach to it** — say "the client was stale, cause not established" rather
than naming a cause you did not test.

**So: alongside every human verification step, state what a benign-but-alarming result looks like
and what to do about it.** And name the one thing only a screen can show — a render, a layout
break, mangled accents — because that is the part your own checks structurally cannot reach.

**Do not reach for a redeploy or a cache invalidation to make an alarm go away.** Either would
appear to fix it, teach you nothing, and destroy the evidence. Run the cheap discriminating check
first; the same sprint's coordinator declined both and was right.

### Also: make the alarm impossible before you run the real check

Everything above is reactive. These three are cheap and stop the phantom happening at all — all
three earned their place in one sprint (2026-09-05).

- **Rehearse against the OLD build, before the new one lands.** Prove your plumbing works — login,
  endpoints, allowlists — while the answer still does not matter. Then a failure during the real
  run cannot be confused with a broken probe. *"A rehearsal on the old code cannot be mistaken for
  a result on the new code."* One agent also checked that its `curl` was not being flagged as a
  bot; had it been, every count would have read zero and looked exactly like a broken feature.
- **Capture the "before" number while it still exists.** A verification that only measures the
  after-state proves much less. One reading taken **before** the deploy turned into the strongest
  single proof in the sprint: the same rows and the same endpoint went from `58` to `0` with
  nothing deleted, which no later step could have shown.
- **Read the uncommitted tree before the commit, not the diff after it.** A reviewer with no task
  yet read the working tree while the builder was still writing, and found a late requirement the
  code did not meet — fixed before it was ever committed. An idle agent is not idle. Findings are
  cheapest while nothing is staged.

### Check that your evidence CAN support your claim

**Raw output is not the same as sufficient output.** Across two sprints every agent had at least
one *correct conclusion resting on a proof that could not establish it* — a grep blind to three of
four consumers, a token claim contradicted by the code its author had read, a pen-test that never
sends the query string it was cited for. **Being right by luck is the dangerous kind, because
nothing forces a re-check.**

**What actually catches these: a peer who checks the METHOD, not the conclusion — plus an author
who verifies instead of defending.** Five out of five real catches were found by a peer or by a
tool. **None** was found by an author re-reading their own words. So do not write this rule down
as "re-read your claims"; it will underperform. The mechanism is peer review of evidence, and an
author who goes back voluntarily.

A third sprint held this up and sharpened it: two agents did catch **themselves** — but both did it
by running a check (listing their own processes, re-reading a command they had just typed), not by
re-reading a claim. **Self-catching works when a tool answers; it does not work by rereading.**

**Acceptance does not end scrutiny — but bound it:** re-check an accepted claim **when it becomes
load-bearing for someone else's decision.** One claim was harmless until a coordinator built a
close plan on it. That trigger is narrow and catches the real case without re-litigating settled
things every session.

**When correcting a peer, give the check, not the coordinates.** Line numbers go stale within a
minute on a live shared tree, and a true claim resting on a citation that no longer resolves gets
refused — correctly. Quote the text and let the reader grep for it.

**To prove an edit was APPLIED, count the ABSENCE of the old form — not the presence of the new
one.** Finding the new text proves it exists somewhere; it does **not** prove the old text is gone.
Both can sit in the same file, and a half-applied edit then reads as a pass.

```
grep -c 'see docs/framework/right-to-be-forgotten.md'   # 1 — proves nothing on its own
grep -c 'see right-to-be-forgotten.md'                  # 0 — THIS is the proof
```

Earned on a comment reflow (2026-09-05), where normalising one citation pushed a sentence across a
line break — the shape that lets *"a line moving down a file look exactly like a file that
changed."* Counting the old form going to zero is what closed it.

**Verify from the PUSHED refs, not your working tree.** A correct disk and a wrong remote are
indistinguishable locally. `git show origin/<branch>:<path> | grep -c …` costs nothing and proves
what a peer would actually pull.

And when you skip a check on purpose, **say so and say why.** A skipped check and a forgotten
check look identical in the record. One agent declined to fire a confirming probe because the
write would have contaminated a peer's before-shot, and named the omission — so nobody had to
wonder whether it had simply been missed.

## Notes

- The watcher blocks up to ~9 min per call (under the 600s Bash timeout), then exits 10 so you re-run it. This is normal; **keep re-running — for hours if the task takes that long.** Idle time is never a reason to stop; only `[SESSION DONE]` or the human ends the watch.
- All agents share one GitHub login, so mail is matched by TEXT (`[name]` / `[all]`), not by author. That is why signing and addressing are mandatory.
- Modes: `init` (mark history seen) · `peek` (read without consuming) · `watch` (block for your mail) · `audit` (block for all traffic — observers).
- Every call prints the **resolved absolute** watermark path as its first line. If that path ever changes between calls, your cwd moved and your mail is at risk. Check it.
- Edit detection uses GitHub's `includesCreatedEdit` flag in `watch`, which reports the **first** edit to a comment. `audit` uses the REST API's `updated_at` and catches every edit. (`gh issue view --json comments` does not expose `updatedAt` — it returns `null`.)
- The stop token is `[SESSION DONE]`, matched anywhere. A bare `SESSION DONE` on its own line no longer stops anything, but `watch` shouts if it sees one, because a live session can still be running the older skill text from its context.
- **Silent failure is the enemy here.** Every serious bug this skill has had was a message that went missing with no error: an orphaned watermark, a decision sent to the wrong agent, a mistyped name, a stop token in the old format. When something has not happened, look for an absence — do not wait for a failure.
