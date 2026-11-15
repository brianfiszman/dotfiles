---
name: github-actions-validation
description: Inspect, diagnose, and report GitHub Actions results by exact commit and event without confusing missing checks, runner failures, dependency failures, or application failures.
---

# GitHub Actions validation

## Goal

Use CI as evidence about a specific repository snapshot, not as a vague green/red
badge. Find the actual failing step, understand which layer failed, preserve the
normal configuration, and report exactly what was proved.

## Recover the exact state first

1. Fetch the PR state: base branch, head branch, exact head SHA, Draft/Ready.
2. Inspect the workflow file at that SHA. Do not assume an older run used the
   current workflow.
3. Query checks and statuses for that exact SHA.
4. Enumerate runs for that SHA across every relevant event: `push`,
   `pull_request`, and `workflow_dispatch`. Record run ID, event, workflow,
   conclusion, and head SHA.
5. Inspect jobs, step summaries, and logs for every failed or ambiguous run.
6. Re-check the PR head before reporting. A run for an older SHA is historical
   evidence, not validation of the current head.

A commit may have both push and pull-request runs. Do not treat one as a
substitute for the other.

## Discover runs without blind spots

- Do not assume a connector helper returns every run. Some integrations filter by
  event or return only the first page.
- In this repository, `fetch_commit_workflow_runs` returned only pull-request
  runs and omitted the corresponding push run. Never use it alone to conclude
  that no push run exists.
- Cross-check with a complete run listing or the GitHub UI/API. Include the event
  and SHA in the handoff.
- A missing run is **not run / pending**, not passed. An empty status list is not
  proof of success.
- If logs are unavailable while a job is running, use step summaries. A log
  download 404 during a running job is not evidence of failure.

## Diagnose by pipeline layer

Read the failed step and surrounding log lines before changing anything:

1. **Workflow definition / expression evaluation** — the workflow never reached
   the steps.
2. **Runner provisioning / checkout** — the job cannot start or fetch actions.
3. **System prerequisites** — packages, executables, headers, compilers, or SDKs
   are missing.
4. **Network / dependency fetch** — registries or upstream Git services are
   unavailable or rate-limited.
5. **Plugin manager / dependency restore** — repositories or locked versions
   cannot be restored.
6. **Native plugin build** — a compiler, interpreter, header, or toolchain is
   missing or incompatible.
7. **Application bootstrap / startup** — Neovim starts but the real configuration
   or plugin setup errors.
8. **Behavioral assertion** — startup succeeds but an explicit behavior check
   fails.

Do not label a failure as a Neovim configuration bug when the editor never
reached configuration startup. Do not label it an environment issue without log
evidence either.

## Fix the cause without weakening the test

- Preserve normal plugin specs, lockfile, build hooks, and startup behavior.
- Fix CI prerequisites in the workflow; do not make the dotfiles installer
  install OS packages.
- Do not disable native builds, bypass a configured build, remove a dependency,
  or turn off a normal setup path solely for a green check.
- Keep dependency versions locked. Do not run a broad plugin update while
  diagnosing a build prerequisite.
- Distinguish a plausible mitigation from a proven fix. Installing a package
  does not prove restore or startup works.
- After a change, wait for the new exact-SHA run and inspect it. Skipped or absent
  steps do not count as passing.
- Preserve failure logs or artifacts, but do not claim an artifact exists until
  its upload step succeeds.

## Workflow expression placement

An expression can be valid in one context and invalid in another. When GitHub
reports an unrecognized context such as `runner`, check the context allowed at
that YAML level. Move the expression to a supported step-level field only when
that is the correct scope; do not guess or broadly relocate variables.

## Long-running headless operations

- A step that stays `in_progress` is not automatically hung. Distinguish progress
  from silence.
- Stream output live with `tee` while retaining a complete log artifact. Do not
  redirect everything to a file and show nothing until exit.
- Split phases with different failure modes into separate steps: preparation,
  plugin restore/build, normal startup, behavior suite.
- Use per-operation timeouts with a job-level limit. A timeout identifies the
  phase and preserves the last lines.
- Keep timeouts generous enough for real compilation and network work. A timeout
  is an investigation signal, not proof the operation is broken.
- Capture the timed command's exit code separately from `tee`; a successful `tee`
  must not mask a failed Neovim process.
- Do not increase a timeout just because progress is invisible. Improve
  observability first.

## CI budget and duplicate runs

- Run feature branches through the PR event; run push events on the default
  branch.
- Cancel superseded runs for the same PR.
- Do not re-run heavy integration for prose-only changes to `AGENTS.md`,
  `AGENT_STATE.md`, logs, or `docs/**`.
- A docs-only PR touching `.agents/skills/**` may still trigger integration
  because the decision script classifies skills as runtime-relevant. Accept one
  run; do not push after every edit.
- Report a skipped job as skipped, not passed.

## Artifact hygiene

Upload root-level phase logs and relevant XDG state logs only:

```yaml
path: |
  ${{ runner.temp }}/nvim-headless-smoke/*.log
  ${{ runner.temp }}/nvim-headless-smoke/state/nvim/*.log
```

Exclude `data/`, `cache/`, plugin checkouts, Mason packages, and downloaded
binaries. A full-workspace upload once produced a 271 MB ZIP with only a few
useful log files.

## Completion report

Report at minimum:

- PR and exact SHA validated.
- Run IDs and events checked.
- The failing/passing job and relevant step.
- Whether validation reached plugin restore, normal startup, and behavior
  assertions.
- What changed, what remains unverified, and the next action.

Use **not run**, **pending**, **failed**, **passed**, **unavailable**, and
**mocked** accurately. Never collapse them into "CI is fine".

Historical failure signatures live in
[`docs/incidents/ci-failure-fingerprints.md`](../../../docs/incidents/ci-failure-fingerprints.md).
