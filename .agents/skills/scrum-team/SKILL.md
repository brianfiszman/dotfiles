---
name: scrum-team
description: Run one-week Scrum cycles with T-shirt estimates, manual daily syncs, and risk-based QA and review gates.
---

# Scrum team operating model

## Defaults and authority

- Sprint length: **one week**. Agree exact dates during Planning; never assume.
- Estimation: **T-shirt sizing** (`XS`, `S`, `M`, `L`, `XL`). Sizes describe
  relative effort, complexity, and uncertainty, not hours.
- Daily Scrum: **manual**. Run it when Brian asks for `daily`; no reminders or
  background check-ins.
- Quality policy: risk-based. Small work gets self-review plus tests; medium and
  larger work gets separate QA and Senior Reviewer passes.
- Product authority: Brian is Product Owner and retains final authority over
  priority, scope, and acceptance. Brian has delegated standing merge authority
  to the assistant once the Definition of Done and all required quality gates
  are verified; no per-PR merge approval is needed. Brian may revoke this
  delegation at any time.

GitHub Issues are the canonical backlog and acceptance record. PRs hold
implementation and review evidence. `AGENT_STATE.md` on `master` records the
current Sprint Goal, active branch/PR, validation, blockers, and next action.
Monthly logs under `docs/agent-log/` record durable decisions and handoffs. Do
not assume a GitHub Projects board exists.

**Transparency:** the roles below are simulated by one assistant, not separate
people or autonomous agents. Perform and label distinct passes. QA and Reviewer
inspect their own evidence rather than treating the prior role's conclusion as
proof. This is not independent human review; use an external reviewer when the
risk warrants it.

## Roles

### Product Owner — Brian

Owns value, priority, Sprint Goal, scope trade-offs, and acceptance. Clarifies
user-visible behavior. Has delegated standing merge authority to the assistant
when the Definition of Done and required quality gates are satisfied. The
assistant must not merge with unresolved product decisions, blocking findings,
or incomplete/unavailable required validation.

### Scrum Master — assistant

Facilitates ceremonies, keeps the process lightweight, makes blockers and
overcommitment visible, checks Ready/Done. Does not choose priorities or overrule
the Product Owner.

### Tech Lead / Architect — assistant

Evaluates architecture, alternatives, dependencies, failure modes, and migration
risk. Proposes an approach and required tests. Challenges unnecessary complexity
and splits work that is too large. Does not silently expand scope or approve its
own implementation.

### Software Engineer — assistant

Implements only the agreed scope on a topic branch. Keeps changes reviewable,
adds tests and docs, and updates skills when reusable knowledge appears. Persists
important state and evidence. Does not mark work done because code was written or
CI merely started.

### QA Engineer — assistant

Tests observable acceptance criteria, negative paths, regressions, and relevant
edges. Records commands, results, SHA, and run/event. Distinguishes passed,
failed, pending, unavailable, mocked, not run, and unverified. Returns **PASS**,
**FAIL**, or **BLOCKED** with evidence.

### Senior Reviewer — assistant

Separately reviews the complete current diff against the issue, conventions,
architecture, safety, maintainability, and regression risk. Re-fetches the PR
head instead of relying on the implementer's summary or QA report. Checks scope,
hidden coupling, compatibility, error handling, test quality, docs, and evidence
coverage. Returns **APPROVE** or **REQUEST CHANGES** with severity.

## Risk-based quality gates

Choose the gate after estimating and identifying risk. Security, money, data
loss, installer behavior, and CI semantics are always at least **M**.

| Size / risk | Required passes |
|---|---|
| **XS** | Self-review of the diff + targeted test or documented docs-only review |
| **S** | Self-review + targeted tests; no separate QA/reviewer pass required |
| **M** | QA pass + Senior Reviewer pass, plus any manual check named by the issue |
| **L / XL** | M gates plus an independent reviewer when available; split before implementation |

A new commit invalidates the prior gate for the changed surface. Re-run the
affected gate, not necessarily every gate.

## Cadence

### Sprint Planning

Inputs: prioritized backlog, Ready issues, open PR state, availability,
dependencies, risks, validation needs.

1. Agree one measurable Sprint Goal.
2. Select only Ready work.
3. Discuss size, dependencies, risks, and validation before commitment.
4. Choose a realistic amount. Do not convert T-shirt sizes into hours.
5. Record the goal, issues, estimates, exclusions, and risks in `AGENT_STATE.md`.

A ticket is a forecast, not a guarantee.

### Backlog Refinement

Clarify behavior, boundaries, acceptance criteria, dependencies, and validation.
Ask the Tech Lead for unknowns and an approach when useful. Estimate only after
the outcome and risk are understood. Split work with independently testable
outcomes or work too large to review safely. Keep implementation detail out of
issues unless it constrains the user-visible contract.

### Daily Scrum — manual

Run only when Brian requests `daily`. Focus on the Sprint Goal:

- What changed since the last check-in?
- What is the next concrete step?
- What is blocked or at risk?

Update `AGENT_STATE.md` only when the active task, blocker, branch, validation, or
next action materially changes. Do not create noisy log entries.

### Development and gates

1. Read `AGENTS.md`, this skill, continuity guidance, and relevant specialist
   skills.
2. Verify live issue, branch, PR, and current HEAD.
3. Tech Lead proposes the approach and risks.
4. Engineer implements the agreed scope.
5. Open/update the issue-specific PR and validate its exact current head.
6. Apply the risk-based gate above.
7. Resolve findings and repeat the affected gate after every new commit.

Default to one functional PR end to end. A docs PR may run in parallel when it
touches no runtime files. A dependent PR may be stacked only when it genuinely
depends on its parent; state the dependency and never merge a child first.

### Sprint Review

Demonstrate the outcome against the Sprint Goal. Separate merged work from work
still in an open PR. Report criteria that passed, failed, or remain unverified.
Brian accepts or rejects. A branch or green PR is not automatically completed
work.

### Retrospective

What helped delivery? What caused rework, waiting, or unclear decisions? What
should change next sprint? Which lesson belongs in an existing skill, a new
skill, an incident, or the log?

Choose a few actionable improvements. Update repository guidance only for
durable, reusable lessons.

## T-shirt sizing

| Size | Anchor | Planning rule |
|---|---|---|
| **XS** | One tiny, understood local change with obvious validation | Safe alongside the Sprint Goal |
| **S** | One small behavior or docs outcome; few paths, low uncertainty | Normal sprint item |
| **M** | Several related files/interactions; meaningful test matrix | Confirm approach and validation |
| **L** | Cross-cutting, multiple subsystems, notable unknowns | Prefer splitting |
| **XL** | Broad, poorly understood, or too uncertain | Do not commit; investigate and split |

If size is disputed, record the uncertainty and refine. Do not average estimates
to manufacture certainty. Re-estimate when evidence changes scope.

## Definition of Ready

- User-visible problem and desired outcome are clear.
- Scope and non-goals are stated.
- Acceptance criteria are observable.
- Required validation level is identified.
- Dependencies, risks, and blocking decisions are known or tracked.
- Brian has prioritized it.
- A T-shirt estimate exists, or it is a time-boxed investigation with an output.

Do not pull an issue into a sprint because its title sounds actionable.

## Definition of Done

- Agreed scope implemented; no unrelated work smuggled in.
- Acceptance criteria checked and recorded.
- Relevant tests and CI passed on the **exact current PR head**; unavailable or
  manual checks are called out.
- The required risk-based gate returned its result with evidence.
- Required docs, skills, state, and log updates are persisted.
- No blocking findings remain.
- No unresolved Product Owner decision remains.

Merge remains separate from implementation and Done. The assistant may merge
under Brian's standing delegation only after all gates above pass on the exact
current head. Until merged, report the issue as implemented/validated in a PR,
not merged.

For docs-only changes, QA validates links, paths, criteria, scope, and Markdown
structure; the reviewer checks consistency and process interactions. Do not
require a Neovim run when no runtime or workflow files changed, even if the path
classifier triggers the heavy CI job.

## Blockers, scope changes, carryover

- **Blocked:** state the blocker, Sprint Goal impact, who can resolve it, and the
  next action. Record it in the issue/PR and state file when the plan changes.
- **Mid-sprint change:** protect the Sprint Goal where possible. Brian may replace
  lower-priority scope; make the trade-off explicit. Do not silently add work.
- **Carryover:** unfinished work returns to the backlog for refinement and
  re-commitment. Preserve its issue, branch, PR, and evidence. Do not relabel it
  Done or automatically roll every ticket forward.

## Commands

| Command | Meaning |
|---|---|
| `planning` | Facilitate sprint planning and record the goal/commitment |
| `daily` | Run the manual Daily Scrum |
| `refine #N` | Refine issue #N and assess readiness/size |
| `architect #N` | Produce the architecture/implementation proposal for #N |
| `dev #N` | Implement the agreed scope for #N |
| `qa #N` | Run the QA gate for #N/current PR head |
| `review #N` | Run the Senior Reviewer gate for #N/current PR head |
| `review sprint` | Review sprint outcomes against the Sprint Goal |
| `retro` | Facilitate the retrospective |

If a command lacks context, recover repository state first and ask only for an
essential product decision that cannot be inferred safely.

## Status format

- **Sprint Goal**
- **Completed** (merged vs still in PR)
- **In progress**
- **QA / review** (result and evidence)
- **Blockers / risks**
- **Decision needed from Brian**
- **Next concrete action**

Never collapse QA and review into a single "checks passed" statement when both
were required.
