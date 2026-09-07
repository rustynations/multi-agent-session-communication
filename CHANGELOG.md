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

## 2026-09-07.4 — 🔴 ACTION REQUIRED

**Four rules that existed only as one project's private notes.** Each was learned in a real sprint,
written into a project-local memory file, and therefore never reached this skill or anyone else.
They are protocol, not project detail, so they belong here.

**1. 🔴 NEVER `gh issue comment --edit-last`.** It means *the last comment by the authenticated
user*, and every agent shares one login — **so it edits whoever spoke last.** A `PATCH` is silent
and total, and **GitHub exposes no comment edit history through the API**, so the overwritten text
is gone. Record the id when you post and edit by id. Read a comment before overwriting it.

**2. Verify against a REF, never a SHA** — even one a peer published a minute ago. An **orphaned**
commit is indistinguishable from a current one when addressed by name: `git show <orphan>:<path>`
returns a real file, so a check reads truthfully about a commit that no longer matters.

**3. Report readiness and ASK. Never convert your own green checks into a release.** A green
scorecard is your measure of done; *ship it* is your human's. **And a withdrawal cannot outrun an
instruction already acted on** — the actor peeks immediately before acting, so your `GO` is the
newest instruction and correctly obeyed. The fix is not a faster retraction.

**4. Tell an author when their claim becomes load-bearing for your decision** — *"I am ticking X on
your claim Y"*. **And if you are the author, on hearing it run a CHECK, do not re-read.** Check the
method, not the conclusion: a right answer resting on a proof that cannot establish it is the
dangerous kind, because nothing forces a re-check. In one sprint five claims went load-bearing, two
were wrong, and none was caught by its author re-reading.

### Why this entry exists at all

A project-local memory that carries protocol rules **forks this skill for one project on one
machine.** It does not travel, other projects never get it, and it silently overrides the real rule
when the two disagree. Eighteen such files — 8,100 words — were found in one project, including one
that contradicted this skill's posting rules and one asserting a gap this skill had already closed.
**If the skill misbehaves, fix the skill.**

## 2026-09-07.3 — 🔴 ACTION REQUIRED

**The close-out roster command harvested prose as agent names.** It ran
`grep -oE '^[A-Za-z][A-Za-z0-9_-]*:'` over **whole comment bodies**, so any body line beginning
`Word:` became an agent. On a real thread it returned **25 names, 22 of them prose** — `Budget`,
`MISSING`, `Authorization`, `PREFLIGHT`, `uncommitted`.

FILO is told to wait for every roster name to sign off and to escalate a missing signature to its
human. **So FILO would hold the close waiting for a word, then report a word as a silent agent.**

**Fixed with the same first-line anchor `OBJECT:` already required** — golden rule 1 puts the
signature at byte zero, so a first-line match cannot pick up prose. **The command also drops your
human**, who signs comments as a participant but is not an agent awaiting release. Run rule 10's
control on it: your own identity must appear in the output.

This shipped one release late. `2026-09-07.2` fixed the `OBJECT:` matcher and left its twin in
place, in the same file, four paragraphs apart.

## 2026-09-07.2 — 🔴 ACTION REQUIRED

**Address hygiene, both directions. Under-addressing loses mail silently; over-addressing wakes
agents who then re-litigate settled things. Both are addressing bugs and the skill only warned
about one.**

### 🔴 What you must change

**1. The address goes on the FIRST LINE, after your signature and before any headline.**
`Frank: [Builder] — **finding**…`. A bold headline first feels like a well-formed comment and is
how the address gets dropped.

**2. Never zero addresses.** No bracket means nobody receives it and nothing reports that. If
nobody must act, address the ledger owner alone.

**3. `[all]` is for what changes what a peer must DO** — a release, an authorization, a stop, a
frozen list. **A ruling that only changes one agent's work goes to that agent alone.** This
replaces *"Announcing a decision, release or authorization? `[all]`. A decision is never
private."*, which made a broadcast the compliant reading of every ruling.

**4. New exit code `4`** — `watch` refuses to arm when your own last comment carried no address,
and tells you to re-post it. It refuses rather than warning because this script's output is only
read when it exits, so a warning would surface up to `MAX_WAIT` later.

### `poll-issue.sh` — `watch` now checks your own last comment for an address

The poster is the only agent who can fix an unaddressed comment and the only agent `watch` never
shows it to, so the check runs on the poster's own next arm. It requires a `[bracket]` on the
first line, which is what golden rule 2 already said.

**An earlier version of this check also accepted a bare `@handle`, so that a human-only ask would
not be flagged. Tested against a real thread it let through a comment whose first line merely
*mentioned* an `@handle` in prose — a false negative on one of the five it was written to catch.**
A human is addressed as `[@handle]`, so the bracket is the only test needed.

## 2026-09-07.1 — 🔴 ACTION REQUIRED

**Rationale moves out of `SKILL.md`. Rules stay.** From here, `SKILL.md` carries orders, this
file carries what changed, and the reasoning lives with the work that produced it. No agent ever
loaded a justification paragraph and behaved better for it.

### 🔴 What you must change

**1. `sleep 300` → `sleep 1200`.** It is a heartbeat, not a net, and shortening it is now listed
as a mistake. Correct any running session.

**2. Golden rule 10 is new — prove a check can FIRE before you trust it to say something is
clean.** This is instrument-trust, not method, so it applies in every lane, including the greps
this skill tells you to run. **Pair every absence check with a positive control in the same
command.** Restores a rule `2026-09-06.3` removed.

**3. Match `OBJECT:` on a comment's FIRST LINE, not anywhere in the body and not at byte zero.**
Golden rule 1 puts your identity at byte zero, so a byte-zero anchor matches no compliant
objection at all, and a whole-body grep matches every comment that merely discusses the token.

**4. The ledger is a PULL surface.** Only its first edit notifies anyone. Read it when you need
state, and put anything a peer must act on in a new comment too.

**5. Announce it when you stop listening.** Silence looks identical to work.

**6. `Edit`, not `Write`, on any file a peer can reach** — including shared auto-memory. `Edit`
fails loudly when its anchor has moved; `Write` reports success over the top of a peer's work.

### Also added

- **Never format a figure you did not produce as your own command output.** A relayed number
  reads like corroboration and cannot disagree.
- **Hand over the key with a raw-artifact ask** — what separates pass from fail, and which wrong
  reading you are guarding against.
- **Ask for acknowledgement at a boundary, not when you suspect loss.** Suspicion never fires: a
  lost message has no symptom. The trigger is a peer acting on the topic of your correction
  without mentioning it.
- **Place one check inside the risk window, not two before it.**
- FILO's own comments are not exempt from the one-line rule.

### `poll-issue.sh` — `init` on an empty thread no longer writes an empty watermark

`init` wrote `""` when there were no comments, and `watch` could not tell that from a **missing**
file. So the first agent on a thread — always FILO — got `NO WATERMARK FOUND` on its first
listen, every session, with nothing lost. That branch also re-baselines to newest, so a comment
arriving between `init` and the first `watch` was genuinely discarded.

It now baselines to `1970-01-01T00:00:00Z`. There are zero comments to replay and every real
timestamp sorts above it, so everything since is delivered. **Not the local clock** — that is
compared against GitHub's, and skew drops mail silently.

## 2026-09-06.3 — 🔴 ACTION REQUIRED

**A rewrite, not an addition. `SKILL.md` goes from 835 lines to 602, and about 200 of the removed
lines were the skill telling every agent how to do its work.**

### The premise, now stated

> **The issue owns the work. This skill owns the talking.**

What to build, who does which part, and how much the job is worth are decided **on the issue**.
This skill tells you how to sign, address, listen, recover lost mail and close. It never tells you
how to do your lane's work, and **it never assigns you a second lane.** If it is not on the thread,
it is not your job.

### 🔴 What you must change

**1. If you are the first agent on an empty thread, you are FILO — and FILO now has 14 written
duties.** They are a new section, placed before start-up. FILO is the only agent that talks to the
human, sizes the sprint, writes the work order, rules disputes and closes, so a FILO mistake is
the session's mistake multiplied by every agent that correctly obeyed it. The four that change
behaviour most:

- **Bring your human a question, not a work order.** The job as you read it, what already does this
  job, the smallest change you can see, one larger option and what it buys, your recommendation.
  Your human is the cheapest reviewer of the requirement — do not spend them at the end.
- **Test the issue. It is an input, not an instruction.** In particular: **an acceptance criterion
  that names an artifact — "route X exists", "file Y is added" — makes that design compulsory,**
  because no agent can pass it with a cheaper correct fix. Rewrite it as observable behaviour or
  get a ruling. And if the issue's framing and its prescription disagree, stop and say so: detail
  beats a one-sentence framing, so a prescription wins by default.
- **Say the size out loud in one line**, then size the session to that number rather than to the
  issue's plan. Two agents on a small job is a good session.
- **Set a check budget before work starts.** The plan is a floor, not a ceiling — agents generate
  checks beyond it wherever the design is closed and the verification is left open. An unbounded
  check budget is a scope decision you make by not making it.

**2. Never write "the design is sound — take it."** It closes the one question worth leaving open.
Agents get creative wherever you leave room, so leave the design open and bound the checking
instead.

**3. "A closed issue is not a completed sprint" is now golden rule 9.** It was one line buried
two-thirds of the way down. The session ends on the stop token plus every sign-off and on nothing
else; an issue's open/closed state starts nothing and ends nothing. Never stand down because a
tracker says you are done — and closing the issue must not silence the thread, because the most
valuable finding of a sprint can arrive after the close.

**4. Do not do another lane's work.** Two agents on one lane is not thoroughness, it is one lane
done twice. If you are not the reviewer, you are not the reviewer.

### What was removed, and why

**Every section that told you how to do work rather than how to talk.** The largest was 118 lines
on checking an alarming verification result, along with pre-registering predictions, proving your
evidence can support your claim, re-checking before a commit, reading the spec against the code,
and numbering-versus-ordering.

They were good paragraphs aimed at the wrong audience. Written as advice to **all** agents, they
quietly gave everyone a reviewer's job on top of the lane the issue had assigned — which is how a
small change ends up with three agents re-deriving each other's claims. The judgement they describe
belongs in the issue, where a lane can own it.

**The war stories went too, and that is not just trimming.** A story is a template: an agent that
reads "six look-alikes, three purpose-built instruments" learns that look-alike hunting is normal
here. Evidence for a rule is for the human deciding whether to adopt it; in the skill it teaches
the behaviour it warns about. **No rule now carries its own evidence.** If a rule is not obviously
right on its own, it should not be a rule.

**Nothing about message delivery was removed.** Absolute watermarks, the two loss mechanisms, one
armed watcher and one output file read, the backup wake beside the watcher, the harness background
flag, `--paginate`, the observer's `audit` mode, the FILO close procedure and the roster wait are
all intact. Those were each found by a live failure and every one of them is transport.

**`poll-issue.sh` is unchanged.**

---

## 2026-09-06.2 — takes effect on a pull

**A watcher that returns is not a watcher that is listening.** Two failures were reported on the
same day from two different sites. One is harmless and was mistaken for the dangerous one; the
other stalled a live sprint and nobody had noticed it.

### The reaper cannot make you deaf — read the guard, not the symptom

An outside user reported Claude Code killing backgrounded pollers about once a minute for two
hours, on a host with 25–30 GiB free. Real, and correctly diagnosed as far as it went: the harness
registers a memory-pressure reaper for background Bash tasks and kills them as a relief valve, and
it is skipped for `kind === "monitor"` and for foreground calls.

What that report missed is the rest of the condition. The reaper only fires when **all** of these
hold:

- the **human** has not interacted for 30 minutes (`Date.now() - lastInteractionTime() >= 1800000`)
- the **main loop is not busy** — the session is idle
- no agent, teammate or workflow task is running

**So the reaper can never fire while an agent is working.** It fires only when the session is idle,
and an idle session that receives a task notification gets a **fresh turn** — verified directly:
a bare `sleep` armed in the background, the turn ended, and its completion started a new turn.
Every reaper kill therefore wakes the agent, which re-arms. The cost is churn, not deafness.

**And mail was never at risk.** The harness streams a task's stdout to its output file, so anything
printed survives a `SIGTERM` — verified: the marker was in the file after the kill, and the
notification carried the file path. Since `watch` prints before it advances the watermark, a kill
costs a duplicate at worst.

That report shipped a durable-delivery patch series for this — a `.pending` sidecar, a tri-state
replay flag and a new `REPLAY` banner agents must learn. **It solves a window the reaper cannot
reach, and it was not taken.** The evidence against it was in the report's own §2.1, which had
already established that the output file survives.

Also not taken: hosting the poll loop in the harness's Monitor task kind, and
`CLAUDE_CODE_DISABLE_BG_SHELL_PRESSURE_REAP`. Both work. Neither is a fix a skill can ship —
one is not exposed in every session, the other asks a user to change a setting and restart.
**A fix that requires the reader to reconfigure their machine is not a fix to this skill.**

### The failure that actually stalled a sprint: the re-arm lost a race

Same day, a different sprint, no reaper involved. From the transcript:

```
14:57:22.824  REVIEWER arms watcher #25
14:57:25.807  the watcher EXITS 0 — mail delivered      ← 3 seconds later
14:58:01.297  REVIEWER writes its own comment body
14:58:04.207  posts it
14:58:15.673  emits its closing sentence — TURN ENDS
              no arm #26, ever
```

25 arms, **all 25 exited 0.** Nothing was killed, nothing was reaped, no non-zero exit anywhere.
REVIEWER was the only agent allowed to push, so the session stopped. Its human had to type
*"you went deaf"* into that terminal by hand.

Two things stacked. A busy thread makes `watch` return in seconds instead of minutes, so the
re-arm has to win a race against the agent's own outbound work many times a minute — and dropping
it once is permanent. And it happened at the moment re-arming *feels* unnecessary: REVIEWER's last
line was that nothing was blocked on it, which is precisely when mail is the only way to reach it.

A peer named the reason no rule catches this: **"from the inside a finished watcher looks exactly
like a waiting one."** A peer also cannot repair it — *"if I re-armed REVIEWER's watcher, mail
would land in a file no one is reading."* **Arming is not listening.** Listening is a live poller
*plus* an agent turn that reads its output, and only the agent can supply the second half.

### Why the fix is a second task and not a better rule

Golden rule 7 already made this a completion condition — *a notification anywhere in a turn means
the turn is not over until you have armed and read* — and it still failed. The reason is
structural, and it is the constraint nobody in either report had named:

> **The watcher can only reach you by EXITING. Exiting is the wake. So the instant it delivers,
> nothing is listening — and a notification that arrives during a turn does not create a turn, it
> is only text appended to work already in flight.**

One task cannot both listen and wake. The harness notifies on **completion** only.

So Step 4 now arms two background tasks together: the watcher, and a bare `sleep 300`. The sleep
holds no watermark, consumes no mail and can lose nothing. **Its whole value is that it cannot
return early**, so it is still pending when a turn ends, and it fires while the agent is idle —
the one state in which a notification does start a fresh turn. Forget the watcher and the sleep
recovers you; forget the sleep and the watcher's return recovers you. Today one dropped call is
fatal.

It is not a timeout. It stands nobody down; it only guarantees another turn.

### The self-check was a false-alarm generator

`cat "$WM"` was documented as **proof** that mail had been consumed and discarded. It is not.
`poll-issue.sh` advances the watermark silently over comments addressed to **other** agents, so
"ahead of my reading" is the normal state on any busy thread. That wording produced three false
*"mail was lost"* reports in one sprint — and a false alarm on this detector is what leads an agent
to the destructive remedy, which is the mechanism `.10` catalogued as a healthy state diagnosed and
destroyed. The test is now narrower: **a comment addressed to you that was never printed**, confirmed
in `peek` first.

### `poll-issue.sh` — the edit notice was at-most-once delivery

`write_edit_sidecar` ran at the top of the watch loop, about a hundred lines above the print that
consumes it. A poller killed in between consumed the flag and delivered nothing, and no later run
could re-derive it — the sidecar is the only record that the edit was reported.

The main mail path was already safe. This was the one place the order was inverted, and the edit
path is where it hurts, because an edited spec is invisible without the notice. Now: catch up
immediately only when there is nothing to deliver, otherwise catch up on the path that has just
printed it.

Verified against the previous revision with a stubbed `gh` and `SIGKILL` inside the window — old:
watermark advanced, re-watch reported "no mail", edit gone. New: watermark held, re-watch delivered
the edit. Both arms confirmed the notice had not printed before the kill, so the window was real in
each.

The same test was run against the outside report's patch series applied to `eecfab9`: **it does not
close this window either.** Its own code comment identifies the hazard — *"the edit sidecar already
caught up above, so this is the only copy: persist it"* — and persists the text without moving the
catch-up, leaving 123 lines between them.

### What changed, concretely

**Net: `SKILL.md` 835 → 835 lines.** G2 held, and G2 binds a fix exactly as it binds a debrief —
it is about what the file costs to load every session, and a fix costs the same as a rule.

`SKILL.md`:

- **Step 4 arms two tasks**, with the exit-is-the-wake reason in one paragraph
- **a new exit-code case:** anything outside `0 / 10 / 42 / 3` means the host killed your watcher —
  nothing broken, nothing lost, read the output file and arm a new pair
- **the watermark self-check corrected** in both places it appeared, including the mistakes-table row
- paid for by three deletions under G1/G3: the founding-sprint foreground anecdote, the `&`
  narration, and a dead example line

`poll-issue.sh`:

- the edit sidecar is never advanced before the edit has been printed

**No tag and no GitHub release.** A `git pull` delivers everything here.

---

## 2026-09-06.1 — takes effect on a pull

**A debrief left the skill SHORTER for the first time.** It added 24 rules and the file still
lost lines, because four blocks of accumulated justification came out and every new rule ships as its
imperative alone.

Three governance rules now bind every future debrief:

- **G1. A rule ships as its imperative. Its case study goes here, in the CHANGELOG.** `SKILL.md`
  is loaded into context every session, forever. This file is not loaded at all.
- **G2. A debrief may not increase the skill's net length.** And its other half, which now lives in
  the debrief skill: **a debrief that finds nothing worth adding is a success, and the deletion
  budget is not a quota to spend.**
- **G3. A finding earns a line. Only a rule agents keep breaking after being told earns a story.**
- **Mechanical self-test:** an added line carrying a date, an agent name or an issue number is
  evidence in the wrong file.

That self-test is why this entry is long. **Everything below was either cut out of `SKILL.md` or
deliberately kept out of it.**

### Nine watcher-failure mechanisms, four agents, one evening

The human caught **seven**. The duplicate-watcher lock shipped in `.10` caught **two**. **No other
tooling caught any.**

| | Mechanism |
|---|---|
| 1 | lapse between cycles while heads-down |
| 2 | lapse after posting |
| 3 | two watchers on one watermark — *caught by the lock* |
| 4 | arming made conditional with `&&` |
| 5 | a turn with no tool calls at all (×3) |
| 6 | `&` plus output to `/dev/null` — *the lock fired into `/dev/null`* |
| 7 | a healthy state mis-diagnosed and destroyed |
| 8 | a turn full of tool calls, none of them the watcher |
| 9 | the closer's own stop token killed its own watcher |

**Mechanisms 1, 2, 5 and 8 are one failure wearing four costumes: the turn ended and nobody
re-armed.** Two positional fixes had already failed on it, because some turns *begin* with a
notification and others *end* with one. So golden rule 7 is now a **completion condition** rather
than a position: *a notification present anywhere in a turn means the turn is not over until you
have armed and read.*

**Mechanism 6 is the whole justification for the refusal sidecar.** The lock refused a duplicate
watcher, printed a correct explanation of why — and printed it down the channel the agent had just
broken. The one output that would have prevented the incident was the one that was discarded. A
refusal delivered into `/dev/null` is not a refusal. And a file nobody reads is not a channel
either, so the sidecar ships **with a consumer**: the next successful `watch`/`audit` prints any
unread refusal at the top of its output and deletes it.

**Mechanism 7 is why the three-step recovery procedure is gone.** An agent found a watermark that
had lost nothing, applied the documented recovery to it, and thereby killed a live watcher and
rewound good state. **A recovery procedure that fires on a non-incident is worse than no procedure,
because a non-incident is the common case.** One gate survives it: confirm the loss in `peek`
before you remedy it — the diagnostic is non-destructive and the remedy is not. It is placed
between the diagnosis and everything downstream, because the diagnosis did not cause that
incident; its *adjacency* to the remedy did.

**Mechanism 9 is a protocol defect, not an agent error.** Authorship is not filtered, so a closer's
own release stops its own watcher. The obvious fix does not work: `watch` returns only mail
addressed to you, and a sign-off is addressed to nobody. **So the closer polls with `peek`, matching
one signature per roster name.**

**And the honest reading of seven-of-nine:** nothing inside a stopped process can detect that it
stopped. Liveness is an **external** check, and without a runner the human is the detector.

### 108 comments in one evening — one every 81 seconds

35 of them contained a self-correction. **Every one was justified by a rule in this skill**, and
together they built a thread the human could not read. A coordinator closed over a builder's
objection specifically because the objection was buried in volume.

> **The skill had a completeness model and no rate model.**

The fix is neither a length budget nor an exhortation to be brief:

> **The thread was doing two jobs and only one of them needs to be append-only. A ledger is
> EDITED; a conversation is APPENDED.**

One ledger comment — `item → owner → state` — owned by the **gate-holder**, not the coordinator.
The coordinator is the agent most likely to go deaf, and a stale ledger that reads as current is
worse than none. Alongside it: agreement that changes a **row** is silent, agreement that changes
only a **belief** costs one line, `peek` before anything long, and a retraction is one line plus
the corrected claim.

### The human is an instrument, not a fallback

Three decisive discriminations came from a human's screenshots, and **all three were incidental to
what was asked** — a `101 Switching Protocols` that retroactively licensed a replay test, the
wording *"by an administrator"* that separated two code paths, and an `Account Disabled` screen
that separated a 403 from a 401.

> **Ask for the raw artifact, never a verdict.** *"Did it connect?"* returns `yes` and teaches
> nothing. A human's artifact is wide-spectrum; an agent's check is narrowband and aimed only at
> what the agent already suspects.

Four agents each became an unmanaged channel at the same person, none by design and every one
helpful — hence: exactly one agent issues asks, and every other reports state and names who to
take instructions from. **Report freely; order nothing.**

One agent also over-asked and under-asked the same person inside one hour: four parallel asks, and
a required check quietly dropped as a kindness. **Never let your human's fatigue decide what counts
as verified.** State the gap, offer the waiver explicitly, record whichever they choose. Declining
that waiver is what turned 15-of-17 acceptance criteria into 17-of-17.

### The self-catch claim, corrected

`.9` and `.10` recorded that authors catch nothing by re-reading their own words. That was too
strong, and all three agents refined it identically:

> **An author CAN catch themselves — but only with a tool in hand.** Compare two artifacts, or ask
> a tool that produces a number or an event you did not ask for. **Re-reading one artifact for
> sense is the one form that never works** — every stale line read perfectly.

The same correction applies to a changed criterion. The remedy is not *"re-read your finished
work"*: list every artifact that cited the **old** criterion and check those, including verification
records and not only work items.

### Rule 19's three instances — prove a check can FIRE before you trust it

The rule ships bare in `SKILL.md`, with one worked example. Its evidence is here:

- a closing-keyword pattern that was `^`-anchored and tested against 3 of 9 real forms
- **its replacement, which errored and printed `SAFE`**
- a lint gate that was green because it ran on zero files

The worked example kept in the skill is the one that generalises: **to prove an edit was applied,
count the ABSENCE of the old form, not the presence of the new one.** Both can sit in the same file,
and a half-applied edit then reads as a pass.

Related, and now fixed at authoring time rather than at tick time: **three conjunction-ticks in one
evening**, each ticked while the same comment listed the other half as open. A criterion containing
"and" is written as two ids before anything can be ticked against it.

### Stories that used to be in `SKILL.md` and live here now

- **The frozen-session prompt.** An agent posted *"Parked, watching"*, blocked in a modal prompt,
  and stopped polling; the coordinator's answer landed 55 seconds later and could not be read. The
  blanket ban that anecdote justified is replaced by **golden rule 8's two conditions** — a
  structured question tool is allowed, but never while your only watcher is in the foreground, and
  never as a second outstanding ask. Backgrounding the watcher is what makes the *shape* of an ask
  safe; the ban never addressed the *number* of asks, and the number was the injury. Four
  structured pickers are worse than four prose asks.
- **The heartbeat.** 65 minutes of quiet while a human was away. One heartbeat comment turned
  *"is this dead?"* into a legible hold, for the cost of one comment. A timeout would have been the
  wrong fix — it stands agents down on a clock, which is the one judgement reserved for the human.
- **The orphaned relative watermark.** A `cd` mid-session pointed a watcher at a fresh, empty
  watermark file, which swallowed a `[BUILDER] go` and deadlocked a live three-agent sprint. The
  boxed warning is gone from `SKILL.md` because the workflow snippet three lines above it already
  uses an absolute path and the script prints the resolved path on every call — **a warning whose
  behaviour is guaranteed by the code above it is narration.** It is **not** gone because it stopped
  happening; that argument is survivorship, and it must not become the precedent that deletes a
  load-bearing guard. The durable line lives in `poll-issue.sh`'s header, next to the code it
  constrains.

### What changed, concretely

**Net: `SKILL.md` 868 → 835 lines** — 111 insertions against 144 deletions, so 24 new rules cost
33 fewer lines than the four blocks they replaced.

`SKILL.md`:

- golden rule 5 (the stop word): 21 lines → 3
- golden rule 7 (the watcher): → 3 lines, now a completion condition
- `## The seven golden rules` is now **eight** — the structured-question rule became golden rule 8
- the orphaned-relative-watermark box and the three-step recovery are deleted; the
  **delivery-vs-reading** two-mechanism table survives, and so does *"an absent watermark file
  means I cannot tell, never they are not listening"*
- 24 numbered items from the debrief, **each two lines or fewer**, each placed in the checklist of
  the moment it fires in rather than in a topical section. *A rule whose action happens at a named
  moment must live in that moment's checklist; topical sections are for understanding, checklists
  are for doing.*

`poll-issue.sh`:

- refusal sidecar **plus its consumer**
- the legacy bare-`SESSION DONE` shout is **kept**. The parser fix is what *creates* the
  stale-context window: a live agent whose context predates the change will emit the old form
  believing it closed the session. The prose was redundant; the shout is not.

`mas-audit.sh` (the companion observer tooling, not in this repo):

- flags a watermark that is behind the newest comment when no live poller holds its `.pid`
- surfaces an unread refusal sidecar
- states the limit **in its own output**, not only in its docs: liveness is an external check.

**No tag and no GitHub release.** Nothing in this entry needs a reader to do anything that a
`git pull` will not deliver.

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

Everything here comes from a **structured debrief with the three agents that ran the sprints**.
They reviewed the proposed rules and rejected or amended four of them, so several entries below are
*their* wording rather than mine.

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
