# Changelog

Versions match the `<!-- Version: YYYY-MM-DD.N -->` comment at the top of `SKILL.md`, so you
can tell at a glance which release your copy is on.

You update by pulling:

```bash
cd <wherever you cloned this>
git pull
```

**Entries marked 🔴 ACTION REQUIRED need something from you beyond a pull** — a habit to change,
or a running session to correct. Everything else takes effect on its own.

---

## 2026-09-05.11 — correction

**A named cause in `.10` was wrong, and the way it was wrong is the useful part.**

`.10` said a human's "old copy on screen" alarm was caused by a cached `index.html` pointing at an
older asset hash. **It was not.** The operator had a page open from before the deploy and had not
reloaded it. Corrected by the operator the same day.

The `curl` check that settled the alarm proved the served bytes were correct — the **conclusion**
(the deploy is fine). It said nothing about the **mechanism**, and the mechanism named was a guess
that happened to be plausible and was never tested. Worse, a corroborating detail (`index.html` does
come back with no `Cache-Control`) made the wrong cause look confirmed.

So the rule now reads: **a discriminating check that confirms your conclusion does not license the
explanation you attach to it.** Say *"the client was stale, cause not established"* rather than
naming a cause you did not test. This is the skill's own *"check that your evidence CAN support your
claim"* rule failing on the agent that had just rewritten it — which is the whole argument for that
rule existing.

The practical fix in the human-handoff guidance is simpler than the one `.10` shipped: **tell them to
reload the page before they read it.**

## 2026-09-05.10 — takes effect on a pull

**One watcher per watermark is now ENFORCED by the script, because the rule was unfollowable.**

`.9` already said, in capitals, *"One at a time. Never arm a second watcher against the same
watermark file."* In the next sprint **all three agents broke it inside one hour** — one ran `init`
and never armed `watch` at all, one binned its poller's output with a shell `&` and `>/dev/null`,
one double-armed. Two of the three did it **minutes after reading a written analysis of someone
else doing it.** A rule that three attentive agents violate while looking directly at it is not
being ignored. It cannot be followed.

So it moved into the machine:

- **`watch` and `audit` refuse to start (exit `3`)** when a live watcher already holds the
  watermark, and tell you to go read the output of the one you already armed.
- **The lock honours only a LIVE poller.** It stores a PID, verifies that process exists *and* is
  actually a poller, and takes over a stale lock loudly. This matters more than the feature: a lock
  that outlived a crashed poller would refuse forever, turning a harmless duplicate delivery into
  **total silent deafness** — strictly worse than the problem. Tested against `SIGKILL`, against a
  recycled PID held by an unrelated process, and against a corrupt lock file.
- **`init` and `peek` are never blocked.** `peek` consumes nothing and is the recovery tool you
  reach for *while* a watcher is armed — an agent used it to catch a superseded work item before
  anything was staged.

**`init` now shouts that you are not listening yet.** It succeeds, prints a watermark, and feels
like a finished setup step. One agent stopped there, went heads-down for ten minutes, and a spec
correction addressed straight to it could not arrive — nothing errored, and the watermark file on
disk looked perfectly healthy. In that agent's words: *"init felt like setup done."*

**Lost mail is now described as TWO mechanisms, not a growing list of modes.** Seven incidents
across three sprints all reduce to: the message **never entered your output** (wrong watermark
file, wrong addressee, misspelled name, no watcher armed), or it **entered and nobody read it**
(`&`, `/dev/null`, a second watcher whose output went unread). The split is the point — only the
reading side yields to discipline; the delivery side needs the machine to shout. The old table also
claimed "four ways" while listing two rows and calling them three; that is fixed.

New guidance, each earned in one sprint:

- **Is a peer listening?** Their acknowledgement is the rule; reading their watermark is a
  same-filesystem shortcut. **Consumed is not delivered** — a poller binning its output consumes
  identically. An absent watermark file means *"I cannot tell"*, never *"they are not listening"*.
- **Issue status is not session status.** A session ends on the stop token plus every sign-off.
  Open or closed is bookkeeping; a closed issue still accepts comments and every watcher still
  reads them. Do not stand down because a tracker says you are done.
- **When you correct one work item, re-check the FINISHED ones.** *The edit that goes stale is not
  the one you are editing.* A correction moved a rationale between docs and left an
  already-signed-off pointer aimed at the doc it had just been deleted from.
- **Predict the benign-but-alarming result when you hand a check to your HUMAN.** They report what
  they see, without your context. A cached `index.html` showed the old copy and read as "it did not
  ship". Also: do not redeploy or invalidate to make an alarm go away — it looks like a fix and
  destroys the evidence.
- **To prove an edit applied, count the ABSENCE of the old form**, not the presence of the new one —
  both can sit in the same file. And verify from the **pushed refs**, since a correct disk and a
  wrong remote are indistinguishable locally.
- **If the last open item belongs to your human, post a heartbeat** — frozen state table, the one
  open item and its owner, *"quiet is not a stop signal"*. Sixty-five minutes of silence became a
  legible hold for the cost of one comment. **Not** a timeout: standing agents down on a clock is
  the judgment call reserved for the human.

## 2026-09-05.9 — 🟡 recommended change

**FILO now has a procedure. Without one it was only a preference.**

`.8` said the opener signs off last. It did not say the opener has to **wait**, **check**, or
**escalate** — so "last out" could still mean closing while an agent sat live and silent.

The endgame the coordinator owns:

1. **Release the team** — stop token, plus "nothing is assigned to you, do not wait for me".
2. **Build the roster from the thread**, not from memory — everyone who signed a comment is playing.
3. **Wait for every agent on that roster to sign off, and check.** Silence is not consent: a missing
   sign-off can mean a dead session, a watcher whose output was discarded, or an agent that never
   received the release.
4. **If one is still missing after about a watch cycle, tell your human** — name who, and say you
   are holding the close. Do not close over a silent agent; their terminal is the only place anyone
   can see it. **This is the one endgame step that needs a person.**
5. **Final read immediately before your own sign-off** — writing it is itself a window.
6. **Sign off, close, verify the close.**

---

## 2026-09-05.8 — 🔴 ACTION REQUIRED

Everything here comes from a **structured debrief with the three agents that ran the sprints**
(`claude-skills-project#3`). They reviewed the proposed rules and rejected or amended four of them,
so several entries below are *their* wording rather than mine.

### 🔴 What you must change

**1. Open every comment with ONE line: evidence, decision, what happens next.** Detail below it.
All three agents independently named thread volume as the top problem: *"an omission gets called
out, length never does."* One thread ran ~25 comments, several over 5,000 characters, and **the
coordinator closed over a builder's objection because it was buried in volume.** A length ceiling
was proposed and rejected — it is the same blunt shape as the reverted naming rule. A *lead* is
checkable. Bound the narrative, not the evidence.

**2. FILO — the agent that opened the session signs off LAST.** A coordinator posting the stop
token while two agents still had open items orphaned a finding, left a reviewer holding an offer
nobody could answer, and killed an observer's watcher. *"That one act caused every failure of the
endgame."*

**3. Declare an objection with `OBJECT:` as the first thing in the comment.** An objection blocks
the close until the coordinator states the disposition — applied, or "raised and consciously
deferred." A named limitation is **not** an objection. Why the token: one last-call comment opened
*"NO OBJECTION to closing"* and then said a line must be fixed before the close. Both, in one
comment.

**4. Authorization must be readable by the agent taking the action.** Not relayed, not quoted —
a faithful quote and a mistaken one are indistinguishable to the receiver. **A coordinator cannot
relay authority for a one-way action at all.** Narrow exception: if you pre-announce the gate, the
human clearing that named gate is authorization.

**5. On rejoin, do NOT run `init`.** It re-baselines to newest, so the documented setup step is a
guaranteed silent-loss mode for a returning agent. Read from your watermark forward; with no
watermark, read the whole thread.

### Changed — the stop token is now safe to quote

The matcher **ignores anything markdown renders as code or quoted text**: fenced blocks (``` and
~~~), inline code spans, blockquotes, and 4-space/tab indented blocks. The list is closed, not
accumulating — it is "everything that renders as code or a quote".

The token tripped watchers **five times** across two threads and **every trip was a quote**, while
every genuine close was bare prose. Pasting raw evidence verbatim is the *rigorous* instinct, so
discipline failed 5/5 — the fifth time inside the review of this fix, by an agent that had just
read three write-ups of the trap. **You fix an instinct in the parser and a choice in the
instructions.**

**No positional rule, deliberately.** Three narrowing proposals (start-of-comment, own-line,
whole-line) were each raised and each withdrawn on evidence: every real close *appended* the token
to a sign-off, so any positional rule converts a loud false trip into a **silent miss** — and rule
1 requires comments to start with `IDENTITY:`, so a start-anchored token could only fire from a
comment that breaks rule 1. Zero behaviour change for anyone closing a session.

### Changed — rule 7 now leads with backgrounding
Backgrounding the watcher is the structural fix, so it is the rule; the prompt ban is written as
its consequence. It also now carries **requirements**, because three agents broke it three
different ways in one sprint: **its own tool call · read the output every time · one at a time.**

### Added
- **Write predictions BEFORE the run**, marking every expected-but-alarming result as expected.
  Four fired in one sprint and none became a false alarm. Preventive, where the rest of that
  section is reactive.
- **Check that your evidence CAN support your claim.** Every agent had a right conclusion on a
  proof that could not establish it. Written deliberately as *peer review of the method* — **5/5
  real catches came from a peer or a tool, none from an author re-reading their own words.**
  Acceptance does not end scrutiny, bounded to *when your claim becomes load-bearing for someone
  else's decision*.
- **When correcting a peer, give the check, not the coordinates.** Line numbers go stale in a
  minute on a live shared tree.
- **Name an owner for every last-call item** (`item → owner → done/deferred`) and **verify your own
  item landed** — one was acknowledged, implied handled, and not done, because the line had *moved*
  rather than changed.
- **The spec itself is a defect source.** Read it against the code before building; the coordinator
  re-derives a finding before amending the order; read the project's own docs first, because a
  coordinator's unread doc becomes three agents' wrong belief.

---

## 2026-09-05.7 — 🔴 ACTION REQUIRED

**Background the watcher via your HARNESS flag — never with a shell `&`, and never redirect the
output.** `.4` said "background it" without saying how. That was not enough, and it created a new
silent mail-loss mode.

```
"$POLL" watch ... > /dev/null 2>&1 &      # ☠️ DESTROYS YOUR MAIL
"$POLL" watch ... &                       # ☠️ output goes nowhere you will read
"$POLL" watch ...  + run_in_background    # ✅ harness captures it and wakes you
```

A shell `&` detaches the poller. It still runs, still collects your mail, and still **advances
your watermark** — then bins the mail. No error, nothing wrong on the thread, and you look busy.
An agent did exactly this and lost its own human's message (2026-09-05). **The output IS the
mail.**

**New self-check, and it is how that agent caught itself:**

```
cat "$WM"      # what has been consumed
```

A watermark **ahead** of the newest comment you have actually read proves something was delivered
and discarded. Recover with `peek`, then say on the thread that you lost mail so senders re-send.

Added as the **fourth** silent-loss mode alongside the orphaned watermark, the wrong addressee and
the mistyped name.

---

## 2026-09-05.6 — correction

**Reverted the identity-naming guidance added in `.3`.** It told agents to use short names and
offered `ARCH` / `BUILD` / `REV`. That was a whole rule invented from one human typo, it made the
thread harder to read, and it cost context in every session that loaded the skill.

Use readable role names — `ARCHITECT`, `BUILDER`, `REVIEWER`. Nothing further.

The near-miss warning added in `.3` is also **removed** from `poll-issue.sh`. A human mistyping a
name is not the skill's problem to solve, and making an agent stop and interpret a warning about
it was worse than the typo.

---

## 2026-09-05.5 — 🟡 recommended change

**Pushing a branch you do not have checked out leaves your local ref stale.** Caught at the close
of the founding sprint.

The reviewer promoted with `git push origin <sha>:main` while standing on `staging`. That updates
the remote and `origin/main` — but **not** the local `main` pointer. GitHub was correct the whole
time and the working copy was not, so the next session would check out `main`, see the old commit,
and conclude prod was behind.

After any push you did not make from that branch:

```
git fetch origin
git rev-parse main origin/main                 # must match
git ls-remote origin main                      # and match GitHub
git update-ref refs/heads/main origin/main     # only if it does not
```

Purely local. Nothing needs pushing — the remote was already right.

---

## 2026-09-05.4 — 🟡 recommended change

**Run the watcher in the background.** No code changed; this is the best structural finding of
the founding audit, and it is worth acting on.

```
"$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"    # ← run this in the BACKGROUND
```

In Claude Code that is `run_in_background` or `ctrl+b`. You are re-invoked when it returns, so
you lose nothing — and you gain the single best property in the protocol: **you keep listening
AND stay reachable at the same time.**

A foreground watcher makes your session unreachable for ~9 minutes at a stretch. Your human
cannot ask you anything, and if you stop to prompt them you go **deaf** (rule 7).

Measured, not theoretical. In the founding sprint all three working agents polled in the
**foreground**; two went deaf on a prompt and one had to be freed by hand. The observer polled
in the **background**, talked to its human throughout, and never missed a comment — including
one that a foreground watcher had already discarded.

Rule 7 is the seatbelt. Backgrounding is not crashing. **Prefer the structural fix.**

---

## 2026-09-05.3 — 🔴 ACTION REQUIRED

The rest of the findings from the same live audit — a full three-agent sprint watched end to end
by a read-only observer comparing the thread against every agent's local transcript.

### 🔴 What you must change

**1. The stop token is now `[SESSION DONE]` — in brackets, matched anywhere.**

```
[SESSION DONE]        ← ends the session, position does not matter
SESSION DONE          ← no longer does anything (but watch SHOUTS if it sees one)
```

Brackets are already the signal namespace, so a bracketed stop can never be mistaken for prose —
and the bare phrase is now inert, so you can finally discuss the stop word safely. The reverse
also holds: **writing `[SESSION DONE]` in prose will stop everyone**, exactly like a stray
`@handle` pings a stranger.

The old form fails **loudly**, never silently: a session already running holds the previous skill
text in its context even after the repo updates, so an agent can still emit the old form believing
it closed the session.

**2. Address the agent who ACTS, not just the agent who asked.**

A human approved a prod promotion, addressed to the coordinator who had asked. The agent that
actually pushes — the reviewer — was not named, so its `watch` classified the approval as
not-for-it, marked it seen and **discarded it**. It then correctly refused to push, holding for an
approval that already existed and that it could never receive. The sender got no error. Announce
any decision, release or authorization to `[all]`.

**3.** *(This entry originally added identity-naming rules and a near-miss warning. Both were
reverted in `.6` — see above.)*

### Added
- **Loud warning for the old stop format**, so its removal can never be a silent no-op.
- **"Closing the session — drain the thread first."** With several agents writing at once a close
  always races them. Observed inside 14 seconds: a builder raised an unverified check, the
  coordinator closed 4 seconds later, and the reviewer posted the very verification the close
  depended on 10 seconds after that. Post a last call, `watch` through it, `peek` immediately
  before closing, and answer or explicitly defer every open item.
- **`gh issue close` exits 0 on an already-closed issue.** Check `state` **and** `closedAt` —
  a coordinator reported "closing now" when the issue had been closed 12 minutes earlier, before
  the work had even finished.
- **"Authority scales with reversibility."** A relay is fine for a preference, never for a
  one-way action. Also: check whether a push *is* the deploy before you gate it — a pipeline
  watching `main` makes it one.
- **"If you write the spec: numbering is not ordering."** `W1…W6` invites everyone to read the
  numbers as the running order; a verification step often has to run after a later-numbered
  deploy. State the chronology separately.
- **Three proactive verification habits**, all from this sprint: rehearse against the **old**
  build so a broken probe can never look like a broken feature; capture the "before" number
  while it still exists; and read the **uncommitted** tree rather than the diff after the commit.
  Plus: **name the checks you skip on purpose** — a skipped check and a forgotten one look
  identical in the record.
- **`--paginate` warning.** `gh api .../comments` returns only the first **30** comments, so a
  hand-written check silently stops seeing recent ones. This bit the auditor of this very sprint,
  which declared a decision missing from a query structurally unable to see it. `watch`, `peek`
  and `audit` are all safe; only ad-hoc commands are exposed.
- **The `@$HUMAN` ask is invisible** on a shared login — GitHub cannot notify you of your own
  comment. Post it on the thread, *also* say it in your own window as plain text (never a
  prompt), and go straight back to `watch`.
- A three-mode table of how a message vanishes — orphaned watermark, wrong addressee, mistyped
  name — because all three are silent and each needs a different tell.

### Changed
- **Rule 7 corrected.** It banned blocking prompts outright; the FIRST agent's alignment with the
  human happens before any `watch` and is legitimate. The ban now applies from your first `watch`
  onward — including while "idle", because idle means listening.

---

## 2026-09-05.2 — 🔴 ACTION REQUIRED

**A new golden rule (7): never block on a prompt.** Found in the same live audit, later the
same day.

### 🔴 What you must change

**Do not use `AskUserQuestion`** — or anything else that stops and waits for a person — while in
a multi-agent session. A blocking prompt freezes your session, so **you stop polling** while the
thread still says you are watching. You go deaf and you look fine.

```
# WRONG — you are now deaf, and the thread does not show it
AskUserQuestion("the delete was refused, what should I do?")

# RIGHT
"$POLL" peek  "$ISSUE" "$ME" "$REPO" "$WM" 10   # may already be answered
gh issue comment ... --body "$ME: [ARCHITECT] @$HUMAN blocked on X. Options: A / B."
"$POLL" watch "$ISSUE" "$ME" "$REPO" "$WM"      # go back to listening immediately
```

**What happened:** an agent hit a permission refusal, asked the human a modal question, posted
*"Parked, watching"*, and sat frozen. The coordinator answered **55 seconds later** and the agent
could not receive it. No peer could detect the problem — the thread looked healthy. Only the
human watching that terminal could see it, and had to dismiss the prompt by hand.

Rules 6 and 7 are the same mistake wearing two hats: `SendMessage` leaves **no record**, a
blocking prompt leaves you **deaf**. Both route around the bus.

### Changed
- **Blockers:** post the blocker, then go **straight back to `watch`**. Do not wait on a prompt,
  and do not assume only the human can unblock you — state the options you can see, because a
  **peer** often answers before the human reads the thread.
- **`peek` before you escalate.** The answer may already be posted, and a refused step may be
  one you do not actually need.
- New mistakes-table rows for all of the above, including: if you are not in `watch`, do not
  claim you are. A false status is worse than silence, because it stops peers looking for the
  problem.

---

## 2026-09-05.1 — 🔴 ACTION REQUIRED

**Fixes a silent message-loss bug that can deadlock a session with nothing on the thread to
show why.** Found by auditing a real three-agent sprint, which deadlocked four minutes in.

### 🔴 What you must change

**Pass an ABSOLUTE watermark path.** Earlier versions of this skill told you to use a relative
one (`tmp/mas-watermark-...`). That is now wrong.

```bash
# OLD — do not use
WM=tmp/mas-watermark-${ME}-${ISSUE}.txt

# NEW
mkdir -p "$HOME/.claude/mas-state"
WM="$HOME/.claude/mas-state/$(printf '%s' "$REPO" | tr '/' '-')-${ISSUE}-${ME}.txt"
```

**Why:** Bash cwd persists between tool calls, so a relative path follows the agent around. One
`cd` into a subdirectory makes the same argument resolve to a **different, empty file** — and an
empty watermark baselines to the newest comment, silently swallowing every message waiting for
you. No error. No warning.

That is what happened: a BUILDER agent ran `init` from the project root, `cd`-ed into a component
repo to read code, and its next `watch` jumped straight past the `[BUILDER] go` that had landed
in between. BUILDER waited forever for a go it had already been sent, the coordinator believed
BUILDER was building, and the reviewer waited on BUILDER. All three agents stopped.

**If a session is running right now:** check for a duplicate watermark. Two files for one agent
and issue means mail was lost.

```bash
find . -name 'mas-watermark-*' -not -path '*/node_modules/*'
```

### Added
- **`peek` mode** — print the recent thread **without** consuming mail, so your next `watch`
  still delivers everything it would have. The skill already required a re-read before
  committing but shipped no command for it.
  ```
  "$POLL" peek "$ISSUE" "$ME" "$REPO" "$WM" 10
  ```
- **`audit` mode** — returns **every** new or edited comment instead of only yours, for an
  observer watching the session itself. Your own comments never wake you. `watch` cannot do
  this job: it discards anything not addressed to you, which is exactly the agent-to-agent
  traffic an observer exists to see.
- **Observer role** documented in `SKILL.md`: use `audit`, announce once, then stay silent, and
  never post the stop word.
- **"When a message goes missing"** section — how to spot lost mail (two watermark files for one
  agent is the proof) and three recovery rules: **rewind** the watermark rather than copying the
  broken value forward, re-send the **full** message rather than just the trigger word, and say
  on the thread that it was lost, not withheld.

### Changed
- A missing watermark on an issue that already has comments now prints a **loud banner** with
  recovery steps instead of silently baselining to newest.
- Every call prints the **resolved absolute** watermark path as its first line, so a cwd drift
  is visible immediately.
- `watch` now flags a comment `*** EDITED AFTER YOU SAW IT ***`. The watermark only tracked
  `createdAt`, so an edited spec was invisible and every agent kept building from stale text.
- `watch` reminds you to read the **whole** batch: one return can hold several messages, and a
  later one may cancel an earlier one.

### Compatibility
Script changes are **additive**. Exit codes (`0` / `10` / `42`), the watermark file format, and
the `watch` fetch path are unchanged, so a session already in progress picks this up safely —
verified against three live agents mid-sprint.

---

## 2026-09-04.3 — 🔴 ACTION REQUIRED

### 🔴 What you must change

**Address agents in square brackets, never with `@`.** `@` is reserved for real GitHub accounts.

```
[Reviewer] your gate list is right      ← correct
@Reviewer  your gate list is right      ← notifies a stranger
```

Any obvious agent name is also somebody's real GitHub handle, so `@`-mentioning one on a public
issue pings an uninvolved person. No prefix is safe — `agent-` handles are taken too. Brackets
belong to no namespace, so they never collide.

**Derive your human's handle, never guess it:** `HUMAN=$(gh api user -q .login)`. A short nickname
that looks like your human's handle usually belongs to a different real person.

### Changed
- **`SendMessage` is banned.** The issue is the only channel. Direct session-to-session messages
  leave no record: your human cannot read them, a restarted agent cannot recover them, and an
  agent on another machine never sees them. Blocked on a peer? Post the blocker on the thread
  **and** ask your human in your own window.
- The stop word only matches `SESSION DONE` **on its own line**. A mention inside a sentence used
  to false-trigger every watcher.

### Docs
- "See it in action" section with demo screenshots (hosted as release assets, not in the repo).

---

## 2026-09-03.1 — first release

- The skill, the six golden rules, and `poll-issue.sh` with `init` and `watch`.
- Blocking poller: spends zero LLM tokens while waiting, returns only on mail for you (exit `0`),
  a stop signal (exit `42`), or a timeout (exit `10` → just run it again).
- Text-based addressing, because all agents share one GitHub login.
- **"When a verification looks alarming — cheapest check FIRST"** — do the one cheap check that
  could disprove the alarm before anyone theorises. In a multi-agent session, agents amplify each
  other's theories, and two confident wrong reads in a row is the tell.
