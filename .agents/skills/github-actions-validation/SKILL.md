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
- **Neorg / LuaRocks build prerequisite:** the original restore failure was caused by the Hererocks environment lacking Lua 5.1. The runner was updated with `lua5.1` and `liblua5.1-0-dev` while retaining `rocks = { hererocks = true }`. Later fresh restores installed both Neorg parser rocks successfully; do not disable Hererocks or skip native parser builds as a CI shortcut.
- **Neorg parser discovery:** successful rock installation alone was insufficient because the `lazy-rocks` parser directories were not on Neovim's runtimepath. PR #71 now declares `tree-sitter-norg` and `tree-sitter-norg-meta` as dependencies, prepends their Lua 5.1 runtime directories before calling `neorg.setup()`, and explicitly asserts that both parsers are discoverable and loadable.
- **Go helper false green:** run [43490592093](https://github.com/brianfiszman/dotfiles/actions/runs/43490592093) passed while logging `Vim:install golines failed:`; `go.nvim`'s bulk `update_all_sync()` hook attempted to install optional binaries, and the plugin notification did not make Neovim exit nonzero. PR #71 removes that bulk hook from default setup and makes the smoke test fail on this notification signature during restore.
- **Confirmed full integration:** run [43495833655](https://github.com/brianfiszman/dotfiles/actions/runs/43495833655) passed for exact head `98479d39470e82609402ca30e7f3e363978022b1`. Preparation, locked plugin restore/build hooks, and normal startup passed. Both Neorg parser assertions passed; no Neorg missing-parser warnings or Go helper installation failures appeared. Artifact [14072710167](https://github.com/brianfiszman/dotfiles/actions/runs/43495833655/artifacts/14072710167) preserves the logs.
- **Current next validation:** issue [#70](https://github.com/brianfiszman/dotfiles/issues/70) is being added to the same PR as a focused lazy-loading regression check. Its fresh exact-head run must prove that a non-Go `CmdlineEnter` does not load `go.nvim`, while `go` and `gomod` filetypes do load it and register `:GoBuild`.

## Incident fingerprint — 2026-11-13: Neovim CLI command limit in lazy-loading test

Run [43499999270](https://github.com/brianfiszman/dotfiles/actions/runs/43499999270)
for exact head `0b4faf4865e98b64a5164ac99f68ba2466d0b18e` passed preparation,
locked plugin restore/build hooks, and normal startup, then failed before the
Go lazy-loading assertions executed. The exact error was:

```
nvim: Too many "+command", "-c command" or "--cmd command" arguments
```

The test had passed each assertion as a separate Neovim `+` CLI argument and
exceeded Neovim's command-option limit. This was a test harness failure, not a
plugin restore or application configuration failure.

Fix: group the related Lua assertions and state transitions into one `+lua`
command per scenario, while retaining separate fresh Neovim processes for the
`go` and `gomod` positive filetype triggers. Each meaningful assertion group
prints a `PASS:` marker into its per-phase log.

Confirmed full validation: run
[43500608304](https://github.com/brianfiszman/dotfiles/actions/runs/43500608304)
passed for exact PR head `f28be42d5b2172aa0ff6c2caa578ef5fd1276e0a`.
Preparation, locked plugin restore/build hooks, normal startup, and both Go
behavior processes passed. The final artifact
[14073049817](https://github.com/brianfiszman/dotfiles/actions/runs/43500608304/artifacts/14073049817)
was downloaded and inspected; it contains:

- `PASS: CmdlineEnter in a text buffer leaves go.nvim unloaded`
- `PASS: Go filetype loads go.nvim and registers :GoBuild`
- `PASS: gomod filetype loads go.nvim and registers :GoBuild`

The exact-head check and artifact are evidence for this snapshot only. Later
commits require their own validation.

## Completion report

Report, at minimum:

- PR and exact SHA validated.
- Workflow run IDs and events checked.
- The failing/passing job and relevant step.
- Whether validation reached plugin restore, normal startup, and any explicit behavior assertions.
- What changed, what remains unverified, and the next concrete action.

Use these labels accurately: **not run**, **pending**, **failed**, **passed**, **unavailable**, and **mocked**. Never collapse them into a generic "CI is fine".


## Long-running headless operations: progress, timeouts, and diagnosis

A workflow step that stays `in_progress` is not automatically hung. Distinguish an operation that is making progress from one that is silent or genuinely blocked.

- Never redirect a long-running command's complete stdout/stderr to a file and show nothing until exit. Stream to the Actions console with `tee` while retaining a complete log artifact.
- Split distinct phases into distinct Actions steps when they have different purposes and failure modes. For this Neovim smoke test, installer preparation, locked plugin restoration/build hooks, and normal startup are separate steps.
- Use per-operation timeouts in addition to the job-level timeout. A timeout should identify which phase exceeded its budget and preserve the last log lines.
- Keep timeouts generous enough for real compilation and network dependency work. A timeout is a failure signal for investigation, not proof that the underlying operation is inherently broken.
- Capture the exit code of the timed command separately from the log-streaming process. Preserve signal/timeout status; do not let a successful `tee` mask a failed Neovim process.
- Keep the full logs as workflow artifacts even on failure. A live job may not yet expose downloadable logs/artifacts; use visible step output while it runs.
- Do not increase a job timeout just because progress is invisible. First improve observability and identify which command/build is consuming time.
- Avoid duplicate expensive runs. Run feature branches through the PR event, run push events on the default branch, and cancel older runs for the same PR when a newer commit supersedes them.

### Incident fingerprint — 2026-11-13

The previous workflow presented install, `Lazy! restore`, and normal startup as one Actions step. The script redirected Neovim output to `plugin-restore.log` and did not print it until the process exited or failed. Therefore the Actions UI showed a static step label during potentially long plugin downloads/build hooks, with no live evidence of which dependency was active. The log-download connector also returned 404 while the job remained in progress; that was not evidence that Neovim itself had failed.

The corrected implementation in PR #71:

- exposes separate `prepare`, `restore`, and `startup` workflow steps;
- streams Neovim output live while saving per-phase logs;
- bounds plugin restoration to 20 minutes and normal startup to 5 minutes, within a 30-minute job limit;
- prints elapsed time and identifies timeout vs process failure;
- runs push CI only on `master` while PRs validate feature branches, avoiding the duplicate push+PR restore on every feature-branch commit;
- cancels superseded runs for the same PR/branch.

The 20-minute restore budget is an initial operational limit, not a measured performance target. Revisit it only from actual run durations and the specific plugin/build log.


### Local macOS portability

GNU `timeout` is not part of the standard macOS userland under the name used by this script. The smoke-test script must therefore remain usable on macOS:

- CI explicitly installs `coreutils` and uses GNU `timeout` for bounded restore/startup phases.
- When run locally without GNU `timeout`, stream output and retain logs as usual, but print an explicit warning that per-phase deadlines are unavailable.
- Do not add a GNU coreutils dependency to the dotfiles installer or make an ordinary Neovim setup depend on it.


### Incident fingerprint — 2026-11-13: workspace preflight ran after initialization

PR run [43481043006](https://github.com/brianfiszman/dotfiles/actions/runs/43481043006) reached the new split workflow, passed runner setup, package installation, pinned Neovim installation, and workspace configuration, then failed in **Prepare isolated install and verify installer safety** before shell-syntax or installer tests ran.

The exact failure was:

```
Error: NVIM_TEST_DIR must be empty before the prepare phase: ...
```

Root cause: the script created `$HOME` and the XDG config/data/state/cache directories inside `NVIM_TEST_DIR` before calling `prepare()`. The `prepare()` function then checked that the same directory was empty. The check was therefore guaranteed to fail on a fresh run; this was a script ordering bug, not a Neovim/plugin failure or runner provisioning issue.

Fix: move the empty-workspace preflight to the top-level setup, before `mkdir -p "$WORK_DIR"` and before any isolated HOME/XDG directories are created. Keep the guard limited to `prepare`/`all`; later `restore` and `startup` invocations must reuse the populated workspace and its marker files. The obsolete in-function check was removed.

Fix commit: [10dfd2d](https://github.com/brianfiszman/dotfiles/commit/10dfd2d3969e9e6ffbdd03bbbc67668c4ad7f778).

Do not call the issue resolved until a fresh run for the updated PR head passes the preparation phase, locked plugin restore/build hooks, and normal startup.

### Incident fingerprint — 2026-11-13: clean-start timeout in Codeium's first-run bootstrap

Run [43485726816](https://github.com/brianfiszman/dotfiles/actions/runs/43485726816), exact head `2b4c56f3daa165b9696a7bab20abb8c14f941292`, passed preparation and locked plugin restoration but failed the normal-startup step after the 5-minute timeout (the process was killed after the additional 30-second grace period).

The uploaded startup trace established the following sequence:

- Neovim reached its `--- NVIM STARTED ---` startup marker at approximately 212.9 seconds.
- The Codeium plugin was configured to load on `BufEnter`. Opening the initial headless buffer therefore initialized Codeium automatically.
- Codeium then attempted its first language-server bootstrap. The trace ended inside its synchronous `system('gzip -d .../language_server_linux_x64.gz')` call in `codeium.vim` after the asynchronous download callback. The hidden `.codeium` data directory is excluded by the artifact uploader's default hidden-file policy, so the language-server binary itself was not in the artifact.
- This is a first-run external-service bootstrap, not a lazy.nvim restore failure. The prior run's restore step had already passed.

The configuration already had functional issue [#69](https://github.com/brianfiszman/dotfiles/issues/69) to defer Codeium until Insert mode. The implementation in [076dc75](https://github.com/brianfiszman/dotfiles/commit/076dc75a417d04bca992025b0e8b461c367a7051) changes its lazy event to `InsertEnter` and explicitly calls `codeium#command#StartLanguageServer()` from the plugin config, because Codeium's own `BufEnter` autocmd is registered after the first buffer-enter event has already happened. This preserves the actual user behavior and avoids starting/downloading the external server on an empty/read-only startup.

The same trace surfaced stale `repeat#set` usage in `core.general.lua`; there was no matching repeat mapping or plugin dependency, so the dead call was removed in [be4293e](https://github.com/brianfiszman/dotfiles/commit/be4293e81c587b45e8cbbc4707b47bc8427c18a5).

The trace also reports `E216: No such group or event: FileExplorer *` from the locked NvimTree 1.18.0 implementation's `silent! autocmd! FileExplorer *` compatibility cleanup. This is upstream plugin output, not a repository autocmd. The smoke script records this exact signature as known compatibility noise while treating other Vimscript error codes in the verbose startup trace as failures.

The smoke harness now inspects the verbose trace as well as stderr, so Vimscript errors cannot be silently missed. The follow-up validation must prove that a clean headless startup does not initialize Codeium, that the editor exits normally, and that no unexpected Vimscript errors remain. Codeium's actual language-server bootstrap is deferred to the user's first Insert-mode entry and remains covered by issue #69.

Current fix/test commits: Codeium [076dc75](https://github.com/brianfiszman/dotfiles/commit/076dc75a417d04bca992025b0e8b461c367a7051), stale repeat call [be4293e](https://github.com/brianfiszman/dotfiles/commit/be4293e81c587b45e8cbbc4707b47bc8427c18a5), startup trace error detection [225b47c](https://github.com/brianfiszman/dotfiles/commit/225b47c73bfc7ef00f6684393cc335e377dfdc4e). Do not mark #30 complete until a fresh run for the current PR head passes all three phases.


### Successful clean startup after deferring Codeium — 2026-11-13

Pull-request run [43489296551](https://github.com/brianfiszman/dotfiles/actions/runs/43489296551) passed all three phases for exact PR head `c955789428c1f565272fbcd80fe9582dd0f2a01a`:

- isolated preparation/installer safety: passed;
- locked plugin restore plus configured build hooks: passed (45 seconds);
- normal empty-buffer startup: passed.

The uploaded artifact [14068693030](https://github.com/brianfiszman/dotfiles/actions/runs/43489296551/artifacts/14068693030) was inspected. The startup timing profile ends at approximately 253.660 ms. The verbose trace contains the single expected NvimTree 1.18.0 message `E216: No such group or event: FileExplorer *` from its silent compatibility cleanup, and no other Vimscript error code. It contains no Codeium or Codeium language-server startup references. The removed stale `repeat#set` call is absent from the current config.

This validates the smoke-test scope: clean install, locked plugin restore/build, and normal startup with an empty buffer. It does not validate Codeium's first Insert-mode activation or external server bootstrap; those remain tracked separately in [issue #69](https://github.com/brianfiszman/dotfiles/issues/69).
