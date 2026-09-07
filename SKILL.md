---
name: multi-agent-session
description: Use when this Claude Code session is one of several live agents collaborating on the same GitHub issue at once — a multi-agent session, distinct from spawning subagents. Triggers on /multi-agent-session (or /multiAgentSession), or a request to have two or more running sessions talk, coordinate, poll each other, or hand work off through a shared issue. Symptoms — "have the two terminals talk", "agents coordinate via the issue", spec/reviewer agent + builder agent working the same issue.
---
<!-- Version: 2026-09-06.3 -->

# Multi-Agent Session

## Overview

You are ONE agent among several, all working the same GitHub issue at the same time.
The **issue is the bus.** Comments are the messages. You listen by polling, you speak by
commenting. Any agent anywhere that can see the issue can join — no shared machine, no
wire between terminals.

This is NOT a subagent you spawned. These are peer sessions you cannot see directly.

> **The issue owns the work. This skill owns the talking.**
>
> What to build, who does which part, and how much the job is worth are decided **on the
> issue** — not here. This skill tells you how to sign, address, listen, recover lost mail
> and close. It never tells you how to do your lane's work, and it never assigns you a
> second lane. **If it is not on the thread, it is not your job.**

## Required inputs — ask if missing

1. **Issue number** — e.g. `42`
2. **Your identity** — a readable role name given to you, e.g. `SPEC`, `BUILD`, `CHECK`

If either is missing from how you were invoked, **STOP and ask the user.** Do not guess
either one.

**Repo:** default to this repo's remote — `gh repo view --json nameWithOwner -q .nameWithOwner`.
If the issue lives elsewhere, confirm with the user.

**Your human's GitHub alias:** never ask, never hardcode — derive it with
`gh api user -q .login` and address them as `@$HUMAN`. A guessed handle usually belongs to
a different real person.

## The nine golden rules

1. **Sign** every comment — start it with `<identity>:` (e.g. `Frank:`).
2. **Address** every comment — name who it is for in **square brackets**: `[Builder]` or
   `[all]`. Brackets, never `@`. **`@` is reserved for real GitHub accounts** — any obvious
   agent name is also somebody's real handle, and no prefix is safe.
3. **Watermark** — never re-read old comments. The poll script tracks this for you.
4. **Act only if it is for you AND needs action.** A plain "ok / thanks" ends the chain.
   Reply to it and you start an echo loop. Silence is allowed.
5. **Stop word** — post `[SESSION DONE]` to end a session; it matches **anywhere** in a
   comment. **Typing it bare in prose is a live wire.** Write it unbracketed to discuss it;
   quoting is safe.
6. **Never use a direct message tool.** The issue is the only channel. A session-to-session
   message leaves **no record**: your human cannot read it, a restarted agent cannot recover
   it, and an agent on another machine never sees it. Blocked on a peer? Post it on the
   thread addressed to `@$HUMAN` **and** say it in your own window. Do not route around the bus.
7. **Arm the watcher as its own tool call** — never joined to another command — **and read
   its output. Background it via your harness's flag, never a shell `&`.** A notification
   anywhere in a turn means the turn is not over until you have armed and read.
8. **A structured question tool is allowed** — but never while your only watcher is in the
   foreground, and never as a second outstanding ask. Both conditions required.
9. **A closed issue is not a completed sprint.** The session ends on the stop token plus
   every sign-off, and on nothing else. An issue's open/closed state starts nothing and ends
   nothing — a closed issue still accepts comments and every watcher still reads them.
   **Never stand down because a tracker says you are done.**

Ignore your own comments. Frank never acts on Frank.

## FILO — the agent that opens and closes

**FILO is First In, Last Out.** It is not a lane the issue assigns; it is whoever arrives on
an empty thread. Exactly one agent per session is FILO.

FILO is the only agent that talks to the human, agrees the sprint's shape, writes the work
order, rules disputes and closes the session. **So a FILO mistake is never only FILO's** —
it is the session's mistake, multiplied by every agent that correctly obeyed it.

If you are not FILO, skip to **Start-up**.

### Before you name a single agent

1. **Bring your human a question, not a work order.** Give them: the job as you read it ·
   what already does this job · the smallest change you can see · one larger option and what
   it buys · your recommendation. **Your human is the cheapest reviewer of the requirement.**
   Do not spend them at the end, when the plan has already bought the work.

2. **Test the issue. It is an input, not an instruction.**
   - **Search for the nearest thing that already does this job**, before any plan. Report
     what it returned, including when it returns nothing.
   - **Read the acceptance criteria for shape. A criterion that names an artifact — "route X
     exists", "file Y is added" — makes that design compulsory**, because no agent can pass
     it with a cheaper correct fix. Rewrite it as observable behaviour, or get a ruling.
   - **If the issue's framing and its prescription disagree, stop and say so.** Detail beats
     a one-sentence framing, so a prescription wins by default.

3. **Say the size out loud, in one line** — *"I read this as about ten lines in one file."*
   A number can be argued with in seconds. A long work order cannot.

4. **Size the session to that number, not to the issue's plan.** Agent count, lanes and check
   budget all come off the size. **Two agents on a small job is a good session.**

### While you write the plan

5. **The plan is a floor you cannot lower later.** Every item you write down has to be
   ticked, waived or answered before the session can end. Not every item needs a
   verification, but every one needs accounting, and accounting is not free. **Write fewer
   items than you think you need.**

6. **Set a check budget, because nothing else will.** The plan is a floor, **not a ceiling** —
   agents generate checks *beyond* it wherever the design is closed and the verification is
   left open. **An unbounded check budget is a scope decision you make by not making it.**
   Name the budget and the stopping point before work starts.

7. **Never write "the design is sound — take it."** That closes the one question worth
   leaving open. **Agents get creative wherever you leave room** — so leave the design open
   and bound the checking, not the other way round.

### Publish the shape on the thread

8. Settle these with the human, then post them:
   - **Who issues asks to the human** — exactly one agent. Everyone else reports state freely
     and names who they take instructions from.
   - **Who pushes / deploys** — one designated actor for anything outward-facing.
   - **Each lane's boundary, scoped by consequence, and what it does NOT cover.**
   - **If one agent both verifies and ships, who independently confirms at least one item.**
   - **The ledger comment and the close sequence.**
   - Tell the human: *"you are the most reliable detector of a stalled agent — if a window is
     quiet and the thread has moved, say so."*

9. **Wait for an explicit go** before announcing, deciding or watching. Then hand the trigger
   back: *"say the word and I'll announce and start watching."*

### While it runs

10. **Rule; do not join in.** When agents start converging, refining and re-litigating, that
    is your cue to **rule and close the round**, not to add your own analysis.

11. **Do not let a lane leak.** An agent doing another lane's job is not thoroughness — it is
    one lane done twice. Name it and send it back.

12. **A halt is yours to call.** If the checking has outgrown the change, say so, waive what
    is left **with its reasoning on the record**, and finish. Do not add a retrospective check
    to make the waiver feel better.

13. **Escalate only the half you cannot decide.** Split decide-from-execute and name the class
    you are asking for: **credentials, scope and money are your human's; work-order judgement
    is yours.**

### At the end

14. **Out last.** You opened it, you close it — see **Closing the session**. A FILO that posts
    the stop token while peers still hold open items orphans their findings and kills their
    watchers before they can sign off.

## Start-up: align before you watch

Read the issue and the thread, and work out which of these you are.

### FIRST agent — empty thread

You are FILO. Go to the **FILO** section above and work through it before you announce,
decide, or poll.

### LATER agent — the thread already has the setup and your lane

Your alignment is **already on the thread** — do **NOT** sync with the human. Read the issue
and your lane, then announce and start watching. Told to hold for FILO's go? Wait for **that**,
not the human. **The human is in the loop for the first agent only.** If your lane genuinely
is not defined on the thread, ask FILO there — still not the human.

### OBSERVER — auditing the session itself

You are on the thread but **not on the work.** You write no code, gate nothing, and decide
nothing about the issue.

- **Use `audit`, not `watch`.** `watch` returns only mail addressed to you and **throws the
  rest away**, so the agent-to-agent traffic you exist to observe never reaches you.
- **Announce once, then go quiet.** Say you are read-only and that nobody should address you,
  report to you, or wait on you.
- **Break silence only for a derailment**, and hand the fix to whoever owns the decision. Post
  the evidence, name the owner, **do not act on their behalf.** Never post the stop token.

```
"$POLL" audit "$ISSUE" "$ME" "$REPO" "$WM"
```

## Workflow

Set variables once. **The watermark path must be ABSOLUTE and cwd-independent** — Bash cwd
persists between tool calls, so one `cd` orphans a relative watermark and mail vanishes with
no error.

```
ISSUE=42
ME=Frank
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
HUMAN=$(gh api user -q .login)   # derived, never asked
POLL=~/.claude/skills/multi-agent-session/poll-issue.sh

mkdir -p "$HOME/.claude/mas-state"
WM="$HOME/.claude/mas-state/$(printf '%s' "$REPO" | tr '/' '-')-${ISSUE}-${ME}.txt"
```

**Step 1 — mark history as seen:**

```
"$POLL" init "$ISSUE" "$ME" "$REPO" "$WM"
```

**Step 2 — announce you are here:**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: [all] — online, watching #$ISSUE."
```

**Step 3 — make your opening move, if you have one.** Hold the first action or a starting
task? DO it now and post the result **before** you listen. If every agent only listens,
nobody starts and the session deadlocks.

**Step 4 — listen. Arm TWO background tasks, always together:**

```
"$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"    # the listener
sleep 300                                      # the backup wake
```

The watcher blocks, spends zero tokens, and returns on mail for you, a stop token, or a
timeout. **It can only reach you by EXITING, so the moment it delivers, nothing is
listening** — and on a busy thread it can exit inside a turn already in flight, where it is
lost when that turn ends. A fixed `sleep` cannot exit early, so it fires while you are
**idle** — the only state in which a notification starts a fresh turn. **Whichever one wakes
you, re-arm BOTH before anything else.** Woken by the sleep with no watcher live? You were
deaf: read from your watermark forward, and do **not** run `init`.

> ### Background it via the HARNESS, never with `&`
>
> ```
> "$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"          # + run_in_background / ctrl+b
> "$POLL" watch ... &        (redirected or not)      # ☠️ DESTROYS YOUR MAIL
> ```
>
> A shell `&` detaches the poller. It still runs, still collects your mail, and still
> **advances your watermark** — then bins it, with no error and nothing wrong on the thread.
> **Never redirect the output either. The output IS the mail.**
>
> A foreground watcher also makes you unreachable for ~9 minutes at a stretch, and any prompt
> then makes you deaf (rule 7). Backgrounding fixes both.
>
> **Self-check:** `cat "$WM"`. It legitimately advances over comments for **others**, so
> "ahead of my reading" proves nothing. The test is narrower: **a comment addressed to you
> that was never printed.** Confirm that in `peek`, then say on the thread that you lost mail.

Read the exit code:

- **0** → new mail printed. Handle it, then run `watch` again.
  - **Read the WHOLE batch before you act.** One `watch` can return several messages, and a
    later one may cancel an earlier one.
  - A message flagged `*** EDITED AFTER YOU SAW IT ***` means text you already absorbed has
    changed under you. Re-read it.
  - **If it means your goal is met**, do not just fall silent — post the stop token.
- **42** → stop token. Post `"$ME: signing off."`, stop, and tell the human.
- **10** → nothing yet. Run `watch` again.
- **anything else** (`3` aside) → **the HOST killed your watcher; nothing is broken and
  nothing is lost.** Read the output file named in the notification, then arm a new pair. A
  repeat message after a kill is expected.

If `watch` prints **`WARNING — NO WATERMARK FOUND`**, treat it as lost mail: read the thread
by hand and follow **When a message goes missing**. Do not just carry on watching.

**Step 5 — reply, only if needed:**

```
gh issue comment "$ISSUE" --repo "$REPO" --body "$ME: [Builder] answer is X."
```

Then back to Step 4. That loop IS the session.

## Keep the record current

The issue is the shared source of truth. **If it is not on the thread, no one — agent or
human — can see it.** Post (signed, `[all]` unless it is for someone), then keep working —
do NOT wait for a reply — when any of these happen:

- You **start** a distinct piece of work, or **change your plan.**
- You **finish** a unit of work, **with the raw evidence** — not just "done."
- You **make or change a decision that diverges from what a peer proposed.**
- **Agreement that changes a row is silent; agreement that changes only a belief needs one
  line.** Silence-as-consent is otherwise indistinguishable from deafness.
- You hit a **blocker — including needing the human.** Post it on the thread, addressed to
  `@$HUMAN` when it is the human you need, then **go back to `watch` immediately.** Do not
  assume only the human can unblock you: state the blocker and the options you can see, and a
  **peer** often answers first. **If the owner is unreachable: decide it yourself and say so
  when reversible, or re-address it when it belongs to a different owner. Do not park.**
- You are going **heads-down** — say what you are doing and roughly when you will resurface.
  While working you cannot hear the channel, so a labeled pause beats ambiguous silence.

**Open every comment with ONE line: evidence, decision, what happens next.** Detail below it.
This is a *lead*, not a length limit — and it is checkable. **Bound the narrative, not the
evidence:** a file-and-line trace earns its length; the paragraphs around it do not.

**One ledger comment, owned by the gate-holder — not FILO, who is likeliest to go deaf —
edited in place: `item → owner → state`.** Comments carry new information; restating state is
an edit.

**`peek` before posting anything long, or any correction about a peer's comment.** A long
comment's premise expires mid-draft; if your point is already there, its value is zero.

**A retraction is one line plus the corrected claim.** No re-litigation, no restating the
chain, no tally of who caught it.

### Read at your boundaries too

Going heads-down means you stop hearing the channel. Before any **commit / push / deploy**, or
after a long heads-down stretch, do **one quick read**. Build the instructions that are
**current now**. `peek` prints the recent thread and **does not move your watermark**:

```
"$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 10
```

## Working with your human

- **One outstanding ask: a single action with a single expected result.** Two halves means two
  owners and two states.
- **Ask for the raw artifact, never a verdict.** Exact wording verbatim beats any paraphrase.
- **Never let your human's fatigue decide what counts as verified.** State the gap, offer the
  waiver explicitly, record whichever they choose — **scaling scope down is theirs.**

> **An `@$HUMAN` ask is INVISIBLE, and that is dangerous.** You post a blocker, the human is
> never told, and to anyone glancing at the thread you simply look busy. An agent can wait
> like that indefinitely.
>
> 1. **Post the ask on the thread** — that is the record, and a peer may answer it.
> 2. **Also say it in your own window as plain text** — "I am blocked on X, I need you to
>    decide Y."
> 3. **Go back to `watch`** and keep listening while you wait.

### If the last open item belongs to your human, post a heartbeat

When everything is built and verified and the only thing left needs a person, long quiet is
indistinguishable from a deadlock — including to the human, who may not know they are the
blocker. FILO posts one comment: **the frozen state table · the one open item and its owner ·
that nothing is degrading · "quiet is not a stop signal" · that the other agents are not being
waited on.** Then keep watching.

**Do not build a timeout instead.** A timeout stands agents down on a clock, which is exactly
the judgment reserved for the human.

## Address the AGENT WHO ACTS, not the agent who asked

When you answer a question, name **everyone who has to act on the answer** — usually not just
whoever asked. An answer addressed only to the asker is classified as not-for-me by the doer's
watcher, **marked seen, and discarded.** No error either end.

- Answering a question? Address **the asker AND the doer.** Unsure → `[all]`.
- Announcing a **decision, release or authorization**? `[all]`. A decision is never private.
- Waiting on an answer that "should have come by now"? It may have gone to somebody else.
  **`peek` the thread — `watch` cannot show you what it already discarded.**

## Authority scales with reversibility

A **relayed** approval is fine for a preference. It is **not** authority for an action you
cannot walk back — a push to prod, a force-push, a delete, anything outward-facing.

**Authorization must be READABLE BY THE AGENT TAKING THE ACTION** — not relayed, not quoted.
A faithful quote and a mistaken one are indistinguishable to the receiver. **So FILO cannot
relay authority for a one-way action at all**; its job is to get the human to post it **where
the actor can read it**, addressed to the actor.

**One narrow exception, pre-announced only:** if you state the gate in advance — *"tell me
when X finishes and I will do Y"* — the human clearing that named gate IS authorization.
Without the pre-announcement, a status report is not an instruction.

Say it plainly when you hold: *"I have the relay; I am holding for your own words because this
touches prod."* Holding a one-way action once too often is far cheaper than releasing it once
too early. When an agent holds on you for this reason, **say it was the right call.**

And **check the shape of the action before you gate it.** A push that a pipeline turns into a
live deploy is not an artifact awaiting a later step; it IS the deploy. Read the pipeline's
source-branch config rather than assuming there is another gate after yours.

## When a message goes missing

Lost mail does not look like an error. It looks like **someone doing nothing.** Two agents
each waiting on the other is the signature, and neither can see it from inside.

**There are only TWO mechanisms, and only one yields to being careful:**

| | **Delivery side** — it never entered your output | **Reading side** — it entered, nobody read it |
|---|---|---|
| **Causes** | Orphaned watermark (relative path + a `cd`) · addressed to the agent who **asked**, not the one who **acts** · a misspelled name your filter rejects · **no watcher armed at all** (`init` is not `watch`) | Poller backgrounded with shell `&` · output sent to `/dev/null` · two watchers armed, one output file read |
| **What you see** | Your poller runs, reads fine, and truthfully says "no mail" about a set that never held the message | Nothing. There is no output to read, or it went in the bin |
| **The fix** | **Not reachable by discipline.** Only the machine noticing and shouting helps — that is what the `NO WATERMARK FOUND` and `init` banners are for | **One armed watcher, one output file read.** |

**Neither side errors, and the sender gets no feedback either way.** That is why an absence has
to be actively looked for.

**Confirm the loss before recovering from it.** Name the message and show it in `peek` first —
the diagnostic is non-destructive, the remedy is not. Then rewind to just before it and
**re-send the FULL original**, never the trigger word alone.

### Is a peer actually listening?

**The rule is the peer's own acknowledgement.** Ask, and wait for them to say so. Only the peer
can tell you a message was *delivered* — and **consumed is not delivered.** A watermark
advancing proves a poller ate the comment; a poller binning its output eats it the same way.

**Shortcut, when every agent shares one filesystem:**

```
"$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 20           # what was actually said
cat "$HOME/.claude/mas-state/<repo>-<issue>-PEER.txt"  # what that peer has consumed
ls -la "$HOME/.claude/mas-state/" | grep "$ISSUE"      # TWO files for one agent = orphaned
```

> ⚠️ **An absent watermark file means "I cannot tell" — never "they are not listening."**
> Agents on separate machines, containers or cloud sessions do not share
> `~/.claude/mas-state/`, so every healthy peer would look deaf.

> **⚠️ Reading the thread by hand? Always pass `--paginate`.**
> `gh api .../issues/N/comments` returns only the **first 30** comments, so a message that
> exists looks missing and you can "confirm" a problem that was already fixed.
> ```
> gh api "repos/$REPO/issues/$ISSUE/comments" --paginate
> ```
> `watch`, `peek` and `audit` are safe. **Only your ad-hoc commands are exposed.**
> And `--paginate --jq 'max_by(…)'` applies the filter **per page** — collect to a file, then `jq`.

**Verify before you accuse.** Read the two watermark files and the message timestamp yourself,
even if a peer hands you the diagnosis.

## Sharing a working tree

If several agents run against the **same checkout**, you share one git working tree:

- **Commit only your own paths:** `git add <your files>`. **Never `git add -A` or `git add .`** —
  a broad add sweeps a peer's **uncommitted, half-finished** work into your commit.
- A pushed shared-branch commit is **hard to reverse.** Flag a mix-up on the thread and let the
  human decide — do **not** force-push or rewrite shared history alone, and **supersede a
  commit rather than amend it** while a peer is reading the tree.
- **A measurement from a shared tree must record the tree's state.**
- **Pushing a branch you do not have checked out leaves your LOCAL ref stale.**
  `git push origin <sha>:main` from another branch updates the remote and `origin/main`, but
  local `main` does not move — so the next session sees the old commit and concludes prod is
  behind. After any such push:
  ```
  git fetch origin
  git rev-parse main origin/main         # must match
  git ls-remote origin main              # and match GitHub
  git update-ref refs/heads/main origin/main   # if it does not
  ```
  Nothing needs pushing — the remote was already right.

(Structural alternative: give each agent its own **git worktree**.)

## Keep watching until told to stop

A quiet thread is **NOT** a stop signal. These sessions run for **hours** — a long build, a
slow deploy, or a human testing can leave the thread silent for a very long stretch, and that
is normal. Keep re-running `watch` on every `exit 10`, indefinitely.

**You stop for exactly two reasons:** a stop token on the thread, or the human tells you to.
Not one hour of quiet, not several, not a hunch that it looks done or looks dead, not a wish to
save resources. **Silence means keep listening.**

If you genuinely think the session should end, that is the human's call — ask on the thread and
wait.

## Closing the session — drain the thread first

With several agents writing at once, **a close always races them.** Someone is usually mid-post
when you decide it is over, and their comment lands after your close comment — unread and
looking ignored. Ten seconds is enough for it to happen.

1. **Post a last call** — `[all] closing in ~60s unless someone objects` — then `watch`
   through it. One cheap round trip lets in-flight work land.
2. **An objection BLOCKS the close until you state its disposition.** Precedence, not timing —
   a `peek` "immediately before" cannot work when the close comment takes minutes to write.
   - **An objection must be declared: `OBJECT:` as the first thing in the comment.** The closer
     matches a token, not prose.
   - **A named limitation is not an objection.** Otherwise every honest caveat blocks forever.
   - **Answered = you state the disposition:** applied, or "raised and consciously deferred."
     The objector confirming is better, never required — one idle agent must not stall a close.
3. **Name an OWNER for every open item.** `item → owner → done/deferred`. Two agents each
   declining to touch a shared file, to avoid racing a peer, is indistinguishable from nobody
   noticing it.
4. **Read the thread AFTER the close comment is written, not before.** The writing is where the
   race lives.
5. **FILO signs off LAST and owns the endgame.** FILO without a wait is only a preference. The
   procedure:
   1. **Release the team** — post the stop token and say plainly that they are released, that
      nothing is assigned to them, and that they need not wait for you.
   2. **Build the roster from the thread**, not from memory:
      ```
      gh api "repos/$REPO/issues/$ISSUE/comments" --paginate -q '.[].body' \
        | grep -oE '^[A-Za-z][A-Za-z0-9_-]*:' | tr -d ':' | sort -u
      ```
   3. **Wait for every roster name to sign off, and CHECK — do not assume.** Poll with
      **`peek`**, matching one signature per name — **not `watch`**, which returns only mail
      addressed to you, and a sign-off is addressed to nobody. **Silence is not consent.**
   4. **If someone has not signed off after about one watch cycle, tell your human** — name who
      is missing and that you are holding. Do **not** close over a silent agent: their session
      is live and their terminal is the only place anyone can see it. **This is the one endgame
      step that needs a person.**
   5. **Do a final read immediately before your own sign-off.** Writing it is itself a window.
   6. **Then sign off, then close, then verify the close.**
6. **Verify the close actually closed it.** `gh issue close` **exits 0 on an already-closed
   issue**, so you can announce "closing now" about something closed hours earlier and nothing
   contradicts you.
   ```
   gh issue view "$ISSUE" --repo "$REPO" --json state,closedAt
   ```
   A `closedAt` earlier than your own close means somebody beat you to it — most often a commit
   trailer, which fires on **push**, therefore before any verification. Say what actually
   happened instead of claiming the close.
7. **Verify YOUR OWN item landed.** The closer drains the thread; nobody else is told to confirm
   their item was applied. **A line moving down a file looks exactly like a file that changed.**
8. **Verify each peer's tick still applies to the artifact it ticked**, and that the
   independent confirmation named at setup exists.

Remember golden rule 9: closing the issue does not end the session, and it does not mean the
sprint is complete. **Closing must not silence the thread.** The most valuable finding of a
sprint can arrive after the close.

## Rejoining after you have stopped

**On rejoin, do NOT run `init`.** `init` re-baselines to the newest comment, so it is a
guaranteed silent-loss mode for a returning agent — the one path where unread mail certainly
exists.

- Watermark still exists? **Read from it forward**, then watch.
- No watermark? **Read the whole thread**, then watch.

## Common mistakes

| Mistake | Fix |
|---|---|
| Replying to every "ok / thanks" | Only reply if action is needed. Kill the echo. |
| Forgetting to sign or address | Every comment starts `Me:` and names `[who]`. |
| Addressing an agent with `@` | Use brackets. `@` is for real accounts; agent names collide with strangers' handles. |
| Re-answering old comments | Run `init` once at start; trust the watermark. |
| Polling with a tight loop in the LLM | Never. Use `watch` — it blocks in bash, not in tokens. |
| Guessing your identity or the issue | Ask the user. |
| Everyone listens, nobody starts | The agent with the first move acts BEFORE listening (Step 3). |
| First agent jumping into setup | FILO aligns with the human and waits for an explicit go. |
| Later agent syncing with the human | Only the FIRST agent talks to the human. Read your lane from the thread. |
| Doing another lane's work | The issue assigned one lane. Two agents on one lane is not thoroughness. |
| Goal met but nobody closes | Post the stop token. Agreement is not a silent ack. |
| Letting the record go stale | Post at each boundary — start / finish / decide / block. |
| Going heads-down silently | Say what you are doing and when you resurface. |
| Asking the human out-of-band only | Post it on the thread too — your window is invisible to the team. |
| Reaching a peer with a direct message | The issue is the only channel. |
| Guessing the human's handle | `HUMAN=$(gh api user -q .login)`. A guess usually names a real stranger. |
| Building against stale instructions | `peek` before you commit/deploy. |
| Pushing a branch you are not standing on | Local ref stays stale. `git fetch`, then compare `main` / `origin/main` / `ls-remote`. |
| `git add -A` on a shared tree | Commit only your own paths. |
| Pausing on a quiet thread | Long silence is NOT a stop signal. You stop only on the stop token or the human. |
| Writing the bracketed stop token in prose | It triggers **anywhere**. Write it unbracketed to discuss it. |
| **Relative watermark path** | Use an absolute `$HOME/...` path. One `cd` orphans it and mail vanishes with no error. |
| Ignoring `NO WATERMARK FOUND` | It means mail was probably lost. Read the thread by hand. |
| Copying a broken watermark to the fixed path | Copying keeps the value that caused the loss. **Rewind** instead. |
| Re-sending only the trigger after lost mail | Re-post the **full** message. A bare "go" strips every bound that rode with it. |
| Acting on the first message in a batch | Read them all — a later one may change an earlier one. |
| Assuming a silent agent is busy | `peek` the thread and compare it against that agent's watermark. |
| No lead line on a comment | Open with one line: evidence, decision, next. A thread nobody can scan is how a close runs over an objection. |
| Closing over a silent agent | Silence is not consent. Check every roster signature; escalate a missing one. |
| FILO signing off first | FILO is last out, or it strands decisions and orphans open items. |
| Treating a caveat as an objection, or missing a real one | An objection says `OBJECT:` first. A named limitation is not one. |
| Leaving a last-call item unowned | `item → owner → done/deferred`. |
| Running `init` on rejoin | It swallows the mail you came back for. Read from your watermark forward. |
| Relaying authority for a one-way action | Get the human to post it on the thread, addressed to the actor. |
| Standing down because the issue closed | Golden rule 9. The tracker's state is not the session's state. |
| **Answering only the agent who asked** | Address **the doer too**, or `[all]`. |
| Closing while peers are mid-post | Post a last call and `watch` through it. |
| Trusting `gh issue close` to have closed it | It exits 0 on an already-closed issue. Check `state` **and** `closedAt`. |
| Reading the thread with `gh api` and no `--paginate` | You only see the first 30 comments. |
| Polling in the foreground | Background via the harness flag. Foreground makes you unreachable ~9 min, and a prompt then makes you deaf. |
| **Backgrounding with `&` or redirecting output** | The poller eats your mail, advances the watermark and bins it — silently. The output IS the mail. |
| Calling a watermark "ahead of my reading" lost mail | It advances over others' comments — normal. The test is a comment **addressed to you** never printed. |
| **Arming the watcher without the backup wake** | Arm both, every time. The watcher reaches you only by exiting. |
| Auditing with `watch` | It discards everything not addressed to you. Observers use `audit`. |
| **A modal ask while your only watcher is in the foreground** | It freezes your session while the thread says you are watching. Background first (rule 8). |
| Posting "parked, watching" and then not watching | A false status stops peers looking for the problem. |
| Assuming only the human can unblock you | State the blocker and the options. A peer often answers first. |
| Escalating without re-reading | `peek` first. The answer may already be there. |

## Notes

- The watcher blocks up to ~9 min per call, then exits 10 so you re-run it. **Keep re-running —
  for hours if the task takes that long.** Only the stop token or the human ends the watch.
- All agents share one GitHub login, so mail is matched by TEXT (`[name]` / `[all]`), not by
  author. That is why signing and addressing are mandatory.
- Modes: `init` (mark history seen) · `peek` (read without consuming) · `watch` (block for your
  mail) · `audit` (block for all traffic — observers).
- Every call prints the **resolved absolute** watermark path as its first line. If that path
  changes between calls, your cwd moved and your mail is at risk.
- Edit detection: `watch` uses GitHub's `includesCreatedEdit` flag and reports the **first**
  edit to a comment. `audit` uses the REST API's `updated_at` and catches every edit.
- The stop token matches anywhere in a comment. A bare unbracketed form stops nothing, but
  `watch` shouts if it sees one, because a live session may be running older skill text.
- **Silent failure is the enemy here.** Every serious bug this skill has had was a message that
  went missing with no error. **When something has not happened, look for an absence — do not
  wait for a failure.**
