# multi-agent-session-communication

Let two or more **independent, live Claude Code sessions** collaborate by talking through a
shared **GitHub issue**. The issue is the message bus: each agent listens by polling the
issue and speaks by commenting. Any agent, on any machine, that can see the issue can join —
and so can a human.

This is **not** subagents. There is no parent/orchestrator; these are peer sessions that
cannot see each other directly. Coordination lives in the durable issue thread, not in any
one agent's context — so agents are disposable, a fresh one can take over from the record,
and a human is just another voice on the thread.

> The skill's invocation name stays `multi-agent-session` (that's what agents trigger on);
> this repo is its home.

## Files

- **`SKILL.md`** — the instructions the agent follows (loaded by Claude Code). Written for the
  agent, not for you.
- **`CHANGELOG.md`** — what changed in each version, and **whether it needs anything from you**.
  Read it after a `git pull`: entries marked 🔴 ACTION REQUIRED mean a habit to change, not just
  new code. Versions match the `<!-- Version: -->` comment at the top of `SKILL.md`, so you can
  see which release your copy is on.
- **`poll-issue.sh`** — the "radio." A blocking poller with four modes:
  - `init  <issue> <identity> <repo> <watermark_file>` — mark existing comments as seen.
  - `peek  <issue> <identity> <repo> <watermark_file> [count]` — print the recent thread
    **without** moving the watermark. For the "re-read before you commit" rule.
  - `watch <issue> <identity> <repo> <watermark_file> [interval_s] [max_wait_s]` — block and
    poll; returns only on mail for you (exit 0), a stop signal (exit 42), or timeout
    (exit 10 → just run it again). Spends zero LLM tokens while waiting. See the script header
    for details.
  - `audit <issue> <identity> <repo> <state_file> [interval_s] [max_wait_s]` — same blocking
    contract, but returns **every** new or edited comment instead of only yours. For an
    observer watching the session itself; your own comments never wake you.

  **The watermark path must be absolute.** Bash cwd persists between tool calls, so a relative
  path follows the agent around: one `cd` points it at a different, empty file, and an empty
  watermark baselines to the newest comment — silently swallowing every message waiting for
  you. That failure mode deadlocked a live three-agent sprint on 2026-09-05 (a `go` was lost,
  and all three agents stopped with nothing on the thread to show why). The script now prints
  the resolved absolute path on every call and shouts if the watermark is missing.

## Install

Skills load from `~/.claude/skills/`. Symlink this repo in under the skill's functional name:

```bash
git clone git@github.com:rustynations/multi-agent-session-communication.git
ln -s "$PWD/multi-agent-session-communication" ~/.claude/skills/multi-agent-session
```

(A `git pull` updates everyone who symlinks.)

## Use

In each session, run:

```
/multi-agent-session <issue> <identity>
```

Same issue number in every session, a distinct name each (e.g. `Architect`, `Builder`,
`Reviewer`). Miss an argument and the skill asks for it. Roles are yours to define — the
skill is role-agnostic.

## How it behaves (the rules, in brief)

- **First agent aligns with the human** on the issue + the sprint shape, then waits for a go; **later agents** get their role from the thread and just start.
- **Sign + address** every comment (`Me:` … `[who]` / `[all]`); act only if it's for you and needs action (kills echo loops).
- **Brackets, not `@`** — agents are addressed as `[Reviewer]`. `@` is reserved for real GitHub accounts, because any obvious agent name is also somebody's real GitHub handle, and mentioning one on a public issue notifies a stranger. No prefix is safe; brackets own no namespace.
- **Gated start** — an agent can join and hold, acting only when told (e.g. `[B2] go`).
- **Keep the record current** — post at each boundary (start / finish-with-evidence / decide / block), fire-and-continue.
- **Blockers go on the thread** — including "waiting on the human," not just in your own window.
- **Re-check before you commit** — read the thread before shipping, so you build current instructions.
- **Shared working tree?** Commit only your own paths — never `git add -A` (it sweeps a peer's in-flight work).
- **Address the agent who ACTS**, not just the one who asked — a decision sent only to the asker never reaches whoever has to act on it, and nothing errors.
- **Authority scales with reversibility** — a relayed approval is fine for a preference, never for a prod push or a delete. Ask the owner directly.
- **Keep watching until told to stop** — long silence is normal; stop only on `[SESSION DONE]` or the human.
- **Silent failure is the enemy.** Every serious bug this skill has had was a message that vanished with no error — an orphaned watermark, a decision addressed to the wrong agent, a mistyped name. When something has not happened, go looking for an absence rather than waiting for a failure.

## See it in action

A full run, public and unedited: three agents built a small full-stack app — a React
frontend and a Node/Express backend — coordinating only through **one GitHub issue**. A
human-in-the-loop (HITL) — a person working the same thread alongside the agents — joined
as a peer, ran the app, and approved it. No agent could see another's screen; the issue
comments were the only channel.

- **The thread** — read the whole run: [`multi-agent-session-demo#1`](https://github.com/rustynations/multi-agent-session-demo/issues/1)
- **The app they built**: [`rustynations/multi-agent-session-demo`](https://github.com/rustynations/multi-agent-session-demo)

![Three terminals, three roles — Architect, Backend, Frontend. Separate live agents on the same issue, not subagents of one session.](https://github.com/rustynations/multi-agent-session-communication/releases/download/demo-assets/1-three-agents.png)

*Three terminals, three roles — separate live agents on one issue, not subagents.*

![The Architect posts the plan on the issue — the team, the folders, a frozen API contract. Every agent and the HITL read the same source of truth.](https://github.com/rustynations/multi-agent-session-communication/releases/download/demo-assets/2-plan-on-the-issue.png)

*The Architect posts the plan on the issue: the team, the folders, and a frozen API contract.*

### What the run showed

**A frozen contract meant the two halves fit on the first try.** The Architect pinned the
API shape before either side was written. Backend and Frontend built in parallel, never
blocked on each other, and the two halves integrated with no round trip.

**An idle agent caught a mistake no one assigned it to catch.** The HITL changed the
scope while the Frontend was mid-writing "building to the old plan." The Backend — which
had no task in that exchange — read the timestamps and flagged the crossed message on the
thread twelve seconds later, before a bad commit landed. Coordination living in the open
thread, not in one orchestrator's context, is what made that possible.

![The Backend flags the crossed message on the thread, with timestamps.](https://github.com/rustynations/multi-agent-session-communication/releases/download/demo-assets/3-catch-on-the-thread.png)

*The idle Backend flags the crossed message — with timestamps — on the thread.*

![The same moment from the Backend's own terminal — an idle agent reading the thread catches a race and warns before a bad commit.](https://github.com/rustynations/multi-agent-session-communication/releases/download/demo-assets/4-catch-in-the-terminal.png)

*The same catch from the Backend's own terminal.*

**Nobody claimed what they hadn't measured.** The Backend proved the endpoint with `curl`
and said plainly which path was code-only. The Frontend drove a real browser for a
theme truth table instead of reasoning about the CSS cascade, then found three
accessibility failures in its own already-shipped work. The Architect reproduced all
fourteen contrast numbers with its own script rather than trusting the table.

**Three agents, one shared checkout, five commits, zero collisions.** Each commit staged
only its own paths — never `git add -A` — so no agent's in-flight work was ever swept into
another's commit.

![The shipped app, light theme — valid ZIP returns temperature, conditions, and city. The API key stays on the server.](https://github.com/rustynations/multi-agent-session-communication/releases/download/demo-assets/5-result-light.png)

*The shipped app, light theme.*

![Dark theme with a manual toggle — a scope change the HITL added mid-session, delivered and reviewed in both modes.](https://github.com/rustynations/multi-agent-session-communication/releases/download/demo-assets/6-result-dark.png)

*Dark theme with the manual toggle — the scope the HITL added mid-session.*

## Requirements / notes

- **Claude Code specific.** Relies on `~/.claude/skills/`, the `SKILL.md` format, the `/`-slash
  invocation, and the harness re-invoking on background-task completion. The `poll-issue.sh` +
  `gh` core is portable; the skill wrapper is not.
- **`gh` (GitHub CLI) authenticated.** Agents comment via `gh`, so **every comment posts under
  your GitHub identity** — all participating sessions share one login (that is why comments are
  addressed by text, `[name]`, not by author).
- **Cost:** several agents polling and working for a long session consumes real tokens. The
  poller itself is free while blocked (zero tokens), but the agents are not.

## Provenance

Not designed in the abstract — every rule was added after a real multi-agent run surfaced the
failure it prevents, across a multi-week production build (a framework extraction, a recovery
from a fouled deploy, and several feature phases), including a single coordinated session that
ran for 50+ hours. Battle-tested, then written down.

## License

MIT — see [LICENSE](LICENSE).
