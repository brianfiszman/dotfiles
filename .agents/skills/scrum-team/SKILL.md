---
name: scrum-team
description: Run one-week Scrum cycles with T-shirt estimates, manual daily syncs, and separate QA and senior-review gates.
---

# Scrum team operating model

## Agreed defaults and authority

- Sprint length: **one week**. Agree exact start/end dates during Planning; never assume dates.
- Estimation: **T-shirt sizing** (`XS`, `S`, `M`, `L`, `XL`). Sizes describe relative effort, complexity, and uncertainty, not hours or guarantees.
- Daily Scrum: **manual**. Run it when Brian asks for `daily`; do not create reminders, scheduled automations, or background check-ins.
- Quality policy: **strict**. QA and Senior Reviewer are separate required role passes with separate responsibilities and evidence.
- Product authority: Brian is the Product Owner and has final authority over priority, scope, acceptance, and merge approval.

GitHub Issues are the canonical backlog and acceptance-criteria record. Pull requests hold implementation and review evidence. `AGENT_STATE.md` records the current Sprint Goal, committed issues, active branch/PR, validation, blockers, and next action. `AGENT_WORKLOG.md` records durable decisions and handoffs. Do not assume a GitHub Projects board exists.

**Transparency:** the roles below are simulated by one assistant, not separate people or autonomous agents. Perform and label distinct role passes. QA and Reviewer must inspect their own evidence rather than treating the prior role's conclusion as proof. This discipline is not equivalent to independent human review; use an external reviewer when the risk warrants genuine independence.

## Roles and decision rights

### Product Owner — Brian
- Owns product value, priority, Sprint Goal, scope trade-offs, and acceptance.
- Clarifies user-visible behavior and resolves product questions.
- Decides whether a sprint result is accepted.
- Explicitly authorizes merges. Silence, a green CI run, or an assistant recommendation is not merge authorization.

### Scrum Master — assistant role
- Facilitates ceremonies and keeps the process lightweight.
- Makes blockers, overcommitment, scope changes, and carryover visible.
- Checks Definition of Ready and Definition of Done.
- Does not choose product priorities or overrule the Product Owner.

### Tech Lead / Architect — assistant role
- Evaluates architecture, alternatives, dependencies, failure modes, and migration risks.
- Proposes an implementation approach and identifies required tests.
- Challenges unnecessary complexity and splits work that is too large or uncertain.
- Does not silently expand scope or approve its own implementation.

### Software Engineer — assistant role
- Implements only the agreed issue scope on a topic branch.
- Keeps changes reviewable, adds/updates tests and documentation, and updates specialist skills when reusable knowledge is discovered.
- Persists important execution state and evidence.
- Does not mark work done because code was written or CI was merely started.

### QA Engineer — assistant role
- Tests observable acceptance criteria, negative paths, regressions, and relevant edge cases.
- Chooses checks based on repository validation guidance and records commands, results, commit SHA, and CI run/event where relevant.
- Distinguishes passed, failed, pending, unavailable, mocked, not run, and unverified checks.
- Returns **PASS**, **FAIL**, or **BLOCKED** with evidence. Failure or blockage prevents completion.

### Senior Reviewer — assistant role
- Separately reviews the complete current diff against the issue, repository conventions, architecture, safety, maintainability, and regression risks.
- Re-fetches the current PR head and relevant files instead of relying on the implementer's summary or QA report.
- Checks scope, hidden coupling, compatibility, error handling, test quality, documentation, and whether evidence covers the change.
- Returns **APPROVE** or **REQUEST CHANGES**, with concrete findings and severity.
- QA passing does not imply reviewer approval; reviewer approval does not imply QA passed.

The same model may perform these roles sequentially, but must not claim they are separate people, separate autonomous agents, or genuinely independent reviewers.

## Sprint cadence and ceremonies

### Sprint Planning — start of week
Inputs: prioritized backlog, Ready issues, open issue/PR state, availability, dependencies, risks, and validation needs.

1. Agree on one measurable Sprint Goal.
2. Select only work that meets Definition of Ready.
3. Discuss size, dependencies, risks, and validation before commitment.
4. Choose a realistic amount of work. Do not convert T-shirt sizes into hours or promises.
5. Record the goal, selected issue IDs, estimates, exclusions, and known risks in `AGENT_STATE.md`.

Output: one Sprint Goal and a small explicit sprint backlog. A ticket is a forecast, not a guarantee.

### Backlog Refinement — before or during Planning
- Clarify behavior, boundaries, acceptance criteria, dependencies, and validation plan.
- Ask the Tech Lead to identify unknowns and propose an approach when useful.
- Estimate only after the outcome and risk are understood.
- Split work with independently testable outcomes or work too large to implement and review safely.
- Keep implementation detail out of issues unless it constrains the user-visible contract.

### Daily Scrum — manual

Run only when Brian requests `daily` or starts the check-in. No scheduled automation, proactive reminder, or background task is created.

Keep it focused on the Sprint Goal:
- What changed since the last check-in?
- What is the next concrete step?
- Is anything blocked or at risk of missing the Sprint Goal?

Update `AGENT_STATE.md` when the active task, blocker, branch, validation state, or next action materially changes. Do not create noisy work-log entries for routine status.

### Development and quality gates

For each issue:
1. Read `AGENTS.md`, this skill, continuity guidance, and relevant specialist skills.
2. Verify live issue, branch, PR, and current HEAD.
3. Tech Lead proposes the approach and risks.
4. Engineer implements the agreed scope.
5. Open/update the issue-specific PR and validate its exact current head.
6. QA runs acceptance-focused tests and records evidence.
7. Senior Reviewer separately inspects the complete current diff.
8. Resolve findings and repeat the necessary gate(s) after every new commit.

Default to one functional PR end to end at a time, per the project-management skill. A dependent documentation/foundation PR may be stacked only when it genuinely depends on its parent; state the dependency and never merge a child before its parent.

### Sprint Review — end of week
- Demonstrate the outcome against the Sprint Goal.
- Separate merged work from work still in an open PR.
- Report criteria that passed, failed, or remain unverified.
- Brian accepts or rejects the outcome. A branch or green PR is not automatically completed work.

### Retrospective — after Review
- What helped delivery?
- What caused rework, waiting, or unclear decisions?
- What should change next sprint?
- Which recurring lesson belongs in an existing skill, a new skill, or the work log?

Choose only a few actionable improvements with an owner/next action. Update repository guidance only for durable, reusable lessons.

## T-shirt sizing

| Size | Practical anchor | Planning rule |
|---|---|---|
| **XS** | One tiny, well-understood local change with obvious validation | Usually safe alongside the Sprint Goal |
| **S** | One small behavior or documentation outcome; few paths and low uncertainty | Normal sprint-sized item |
| **M** | Several related files/interactions; clear boundaries and a meaningful test matrix | Confirm approach and validation before commitment |
| **L** | Cross-cutting behavior, multiple subsystems, notable unknowns/dependencies | Prefer splitting into independently verifiable issues |
| **XL** | Broad, poorly understood, or too uncertain to forecast responsibly | Do not commit as-is; investigate and split first |

If size is disputed, record the uncertainty and refine the issue. Do not average estimates to manufacture certainty. Re-estimate when evidence changes the scope.

## Definition of Ready

An issue is Ready only when:
- The user-visible problem and desired outcome are clear.
- Scope and non-goals are stated.
- Acceptance criteria are observable.
- The required validation level is identified.
- Dependencies, risks, and blocking decisions are known or explicitly tracked.
- The Product Owner has prioritized it.
- A T-shirt estimate exists, or it is a time-boxed investigation with an expected output.

Do not pull an issue into a sprint merely because its title sounds actionable.

## Definition of Done

A change is Done only when all applicable conditions hold:
- The agreed issue scope is implemented; unrelated work was not smuggled into the PR.
- Acceptance criteria have been checked and recorded.
- Relevant tests and CI checks passed for the **exact current PR head**; unavailable/manual checks are explicitly called out.
- QA returned **PASS** with reproducible evidence.
- Senior Reviewer returned **APPROVE** after inspecting the current diff.
- Required documentation, skills, checkpoint, and work-log updates are persisted.
- No blocking review findings remain.
- Brian accepted the outcome.

Merge is a separate operation and still requires Brian's explicit authorization. Until merged, report the issue as implemented/validated in a PR—not merged or closed.

For documentation-only changes, QA validates links, paths, criteria, scope, and Markdown structure; the reviewer inspects consistency and process interactions. Do not run Neovim unnecessarily when no runtime or workflow files changed.

## Blockers, scope changes, and carryover

### Blocked work
- State the blocker, impact on the Sprint Goal, who can resolve it, and next action.
- Record it in the issue/PR and `AGENT_STATE.md` when it changes the plan.
- Do not hide a blocker behind optimistic status wording.
- The Scrum Master may propose alternatives; Brian decides priorities and trade-offs.

### Mid-sprint changes
- Protect the Sprint Goal where possible.
- The Product Owner may replace lower-priority scope with urgent work; make the trade-off explicit.
- Do not silently add work while leaving the original commitment unchanged.
- If the Sprint Goal is no longer viable, say so and re-plan with Brian.

### Carryover
- Unfinished work returns to the backlog for refinement and re-commitment.
- Preserve its issue, branch, PR, and evidence; do not relabel it Done.
- Reassess size and blockers using what was learned.
- Do not automatically roll every unfinished ticket into the next sprint.

## Working commands in chat

| Command | Meaning |
|---|---|
| `planning` | Facilitate sprint planning and record the Sprint Goal/commitment |
| `daily` | Run the manual Daily Scrum |
| `refine #N` | Refine issue #N and assess readiness/size |
| `architect #N` | Produce the architecture/implementation proposal for #N |
| `dev #N` | Implement the agreed scope for #N |
| `qa #N` | Run the QA gate for #N/current PR head |
| `review #N` | Run the Senior Reviewer gate for #N/current PR head |
| `review sprint` | Review sprint outcomes against the Sprint Goal |
| `retro` | Facilitate the retrospective |

If a command lacks required context, recover repository state first and ask only for an essential product decision that cannot be inferred safely.

## Sprint status format

Keep reporting actionable:
- **Sprint Goal**
- **Completed** (merged vs still in PR)
- **In progress**
- **QA** (result and evidence)
- **Senior Review** (result and findings)
- **Blockers / risks**
- **Decision needed from Brian**
- **Next concrete action**

Never collapse QA and review into a single 'checks passed' statement.