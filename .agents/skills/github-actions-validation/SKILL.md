---
name: github-actions-validation
description: Inspect, diagnose, and report GitHub Actions results by exact commit and event without confusing missing checks, runner failures, dependency failures, or application failures.
---

# GitHub Actions validation

## Goal

Use CI as evidence about a specific repository snapshot, not as a vague green/red badge. Find the actual failing step, understand which layer failed, preserve the normal application configuration, and report exactly what was proved.

## Recover the exact state first

Before interpreting a check:

1. Fetch the current PR state and identify its base branch, head branch, and exact head SHA.
2. Inspect the workflow file at that SHA. Do not assume the workflow currently on the branch is the one an older run executed.
3. Query checks and statuses for that exact SHA.
4. Enumerate workflow runs for that SHA across all relevant events: `push`, `pull_request`, and `workflow_dispatch`. Record each run ID, event, workflow name, conclusion, and head SHA.
5. Inspect the job list, step summaries, and logs for every failed or ambiguous run.
6. Re-check the PR head SHA before reporting. A run for an older SHA is historical evidence, not validation of the current head.

A commit may have both push and pull-request runs. Do not treat one as a substitute for the other when the workflow is configured for both.

## Discover runs without blind spots

- Do not assume a connector helper returns every run. Some integrations intentionally filter by event or return only the first page.
- In this repository, `mcp__GitHub__fetch_commit_workflow_runs` was observed to return only pull-request-triggered runs. It omitted the corresponding `push` run. Never use that helper alone to conclude that no push run exists.
- Cross-check with a complete workflow-run listing or the GitHub Actions UI/API, and include the event and SHA in the handoff.
- A missing run is **not run / pending**, not passed. An empty status list is not proof that Actions succeeded.
- If job logs are unavailable while a job is still running, use step summaries for the current state. A temporary log-download 404 is not evidence that the job failed.

## Diagnose by pipeline layer

Read the failed step and the surrounding log lines before changing anything. Classify the failure:

1. **Workflow definition / expression evaluation** — the workflow cannot be parsed or an expression is unavailable in that context. The runner never reached the job steps.
2. **Runner provisioning / checkout** — the job cannot start, fetch the repository, or resolve an action.
3. **System prerequisites** — package installation or required executables, headers, compilers, or SDKs are missing.
4. **Network / dependency fetch** — GitHub, a package registry, or an upstream Git service is unavailable or rate-limited.
5. **Plugin manager / dependency restore** — repositories or locked versions cannot be restored.
6. **Native plugin build** — a dependency's compiler, Lua interpreter, headers, or build toolchain is missing or incompatible.
7. **Application bootstrap / startup** — Neovim starts but its real configuration or plugin setup reports errors.
8. **Behavioral assertion** — startup succeeds but an explicit user-facing behavior check fails.

Do not label a failure as a Neovim configuration bug when the editor never reached configuration startup. Do not label it an environment issue without log evidence either.

## Fix the cause without weakening the test

- Preserve the application's normal plugin specs, lockfile, build hooks, and startup behavior.
- Fix CI prerequisites in the workflow when CI lacks a system dependency; do not make the dotfiles installer install OS packages.
- Do not disable native builds, bypass a plugin's configured build, remove a dependency, or turn off a normal setup path solely to obtain a green check.
- Keep dependency versions locked. Do not run a broad plugin update while diagnosing a build prerequisite.
- Distinguish a plausible mitigation from a proven fix. A dependency package being added successfully does not prove that plugin restoration or startup now works.
- After a change, wait for the new exact-SHA runs to finish and inspect their results. A green job must include the steps that matter; skipped or absent steps do not count as passing.
- Preserve failure logs or artifacts when possible, but do not claim that artifacts exist until the upload step confirms success.

## Workflow expression placement

An expression can be valid in one workflow context and invalid in another. When GitHub reports an unrecognized context such as `runner`, check the exact expression context allowed at that YAML level. Move the expression to a supported step-level field only when that is the correct scope; do not guess or broadly relocate environment variables.

## Incident fingerprints — 2026-11-13

These are repository-specific observations, not universal rules:

- **Workflow parse failure:** the Neovim workflow initially set `NVIM_TEST_DIR: ${{ runner.temp }}/...` in the job-level `env`. GitHub rejected the workflow before execution with `Unrecognized named-value: 'runner'`. It was moved to the test step's `env`. Incident run: [43475125584](https://github.com/brianfiszman/dotfiles/actions/runs/43475125584).
- **Neorg / LuaRocks build failure:** run [43476234303](https://github.com/brianfiszman/dotfiles/actions/runs/43476234303) passed runner setup, system package installation, and pinned Neovim installation, then failed while restoring Neorg's `tree-sitter-norg` and `tree-sitter-norg-meta` dependencies. Hererocks reported that Lua 5.1 was not installed. The repository's `.config/nvim/lua/plugins.lua` deliberately sets `rocks = { hererocks = true }`; do not switch this off as a CI shortcut.
- Commit [9d12427](https://github.com/brianfiszman/dotfiles/commit/9d124270ce393fa07ce3498b21c5503a4d2400fd) added `lua5.1` and `liblua5.1-0-dev` to the CI system prerequisites. This is a targeted mitigation, **not a confirmed fix** until the fresh plugin restore and subsequent normal headless startup pass.
- The follow-up runs are [push 43476997602](https://github.com/brianfiszman/dotfiles/actions/runs/43476997602) and [pull_request 43477005808](https://github.com/brianfiszman/dotfiles/actions/runs/43477005808). Their exact-SHA result must be checked before changing the incident status.

## Completion report

Report, at minimum:

- PR and exact SHA validated.
- Workflow run IDs and events checked.
- The failing/passing job and relevant step.
- Whether validation reached plugin restore, normal startup, and any explicit behavior assertions.
- What changed, what remains unverified, and the next concrete action.

Use these labels accurately: **not run**, **pending**, **failed**, **passed**, **unavailable**, and **mocked**. Never collapse them into a generic "CI is fine".
