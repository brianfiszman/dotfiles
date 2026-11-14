# Agent work log

This file is append-only. Add concise entries for meaningful discoveries,
decisions, failures, mitigations, and handoffs. Keep detailed implementation
and review discussion in its canonical issue, PR, commit, or CI run; link it
here rather than copying it.

---

## 2026-11-13 — Recover DAP investigation and begin execution continuity (#78)

### Recovered DAP/Mason finding

- The interrupted run's scheduler trace showed scheduled callbacks executing
  and Mason directory creation completing. Callback 60 entered but did not
  return for more than four minutes; no stack trace identified the blocking
  function. The exact cause therefore remains unknown.
- The headless test was polling `Package:is_installed()` while Mason was
  installing adapters. This caused repeated synchronous scans of the shared
  installation directory and was not a sound async completion signal.
- The test was changed to observe package handles and terminal
  `package:install:success` / `package:install:failed` events. Run
  [#43525656228](https://github.com/brianfiszman/dotfiles/actions/runs/43525656228)
  passed the five adapter installations.
- A later first-use regression test covered `:DapInstall` with a clean
  registry. Final validation passed on exact PR head
  `73b4bf80f811667a778f2105dfd9516aae3bfce4` in
  [run #43530295202](https://github.com/brianfiszman/dotfiles/actions/runs/43530295202).
- PR #77 was squash-merged as
  [`b30cf6f`](https://github.com/brianfiszman/dotfiles/commit/b30cf6f87dc1a8adbd573a25c712f540db2e548a);
  issue #75 was then closed. No interactive macOS or live TypeScript session
  was performed.

### Continuity work started

- Began issue [#78](https://github.com/brianfiszman/dotfiles/issues/78) on
  branch `docs/agent-session-continuity-pr78`, based on the merged #77
  commit above.
- The recovery protocol will treat GitHub's current branch/PR/CI state as
  authoritative and the checkpoint as a navigation aid that must be verified.
- The continuity skill will coordinate existing specialist skills rather than
  duplicate Neovim, project-management, or Actions procedures.
- Next: review the complete documentation diff, simulate a fresh-session
  recovery, and open the separate documentation PR.


## 2026-11-13 — Documentation review and simulated recovery passed

- Reviewed the five changed files on `docs/agent-session-continuity-pr78`.
  Corrected literal escaped Markdown code delimiters and reconciled the stale
  #75 backlog entry.
- Verified the branch contains only `AGENTS.md`, `AGENT_STATE.md`,
  `AGENT_WORKLOG.md`, `.agents/skills/execution-continuity/SKILL.md`,
  and `docs/neovim-modernization-backlog.md`; no runtime or workflow files.
- Checked balanced fenced code blocks, absence of escaped backticks, and
  repository path references.
- Simulated recovery without conversation history: the instructions led to
  the checkpoint, work log, live branch, issue #78, merged PR #77, exact
  validation SHA, and next concrete action. The checkpoint matched the
  authoritative GitHub state.
- Next: open the separate documentation PR and inspect its exact-head checks.


---

## 2026-11-14 — Restore append-only work log and reconcile PR #79

- Recovery inspection found that commit `721a078` accidentally replaced `AGENT_WORKLOG.md` with a copy of the checkpoint, despite the file's append-only contract.
- Restored the original chronological work log from commit `4994f6d`, preserving the DAP/Mason investigation and the documentation-review/recovery-simulation entry.
- This correction is appended after the restored history; it does not silently erase or rewrite the earlier entries.
- PR [#79](https://github.com/brianfiszman/dotfiles/pull/79) remained open on exact head `721a07819de395527ffe86fc6b0830f2be54702f`; pull-request run [#43531552732](https://github.com/brianfiszman/dotfiles/actions/runs/43531552732) completed successfully for that exact SHA, including preparation, locked plugin restore/build hooks, and normal headless startup.
- The five-file PR scope was reviewed against issue #78. QA passed for recovery sequence, exact evidence, linked paths, Markdown structure, and documentation-only scope. Senior Reviewer approved consistency with the repository safety and project-management rules.
- No local macOS interactive session was performed. Issue #78 remains open until the PR is merged; merge authorization remains with Brian.


---

## 2026-11-14 — PR #79 restored-worklog head validation passed

- Pull-request run [#43534384968](https://github.com/brianfiszman/dotfiles/actions/runs/43534384968) completed successfully for exact PR #79 head `0d006c2af97137adc8f9a189d6aa2280a59dcdd2`.
- All job steps passed: prerequisites, pinned Neovim, isolated workspace, installer safety, locked plugin restore/build, normal startup, and log upload.
- This run includes the append-only work-log restoration and checkpoint/work-log reconciliation.
- The following checkpoint commit advances the branch again; inspect the workflow run associated with that resulting exact head before treating the PR as fully validated.


---

## 2026-11-14 — Complete Scrum PR after continuity parent merge

- Brian authorized merging parent PR #79. It was squash-merged into `master` as [`a006c8a`](https://github.com/brianfiszman/dotfiles/commit/a006c8afb84518098009e4bd8da4436c8e926aa4); issue #78 is closed.
- Retargeted child PR [#81](https://github.com/brianfiszman/dotfiles/pull/81) to `master`. Its prior head `fb5dd83c1a066a191980be4eb53af375592dd866` had passed [run #43535300671](https://github.com/brianfiszman/dotfiles/actions/runs/43535300671), but retargeting initially displayed the squash-merged parent's changes again because the child history did not contain the squash commit.
- Preserved the child tree and added the exact current master commit as a second parent so GitHub's merge base advances to master. This changes ancestry, not the intended Scrum content.
- The next exact-head run is required. Verify the PR diff is only the four Scrum documentation files, then QA and Senior Review.
- No merge of PR #81 is authorized yet; Brian's explicit approval is still required.


---

## 2026-11-14 — PR #81 retargeted and master-based diff reviewed

- Parent PR #79 is merged to `master` at `a006c8afb84518098009e4bd8da4436c8e926aa4`; issue #78 is closed.
- Retargeted PR #81 to `master`. The squash merge meant the child branch did not inherit the parent squash commit as an ancestor, so GitHub initially showed the parent documentation again in the child diff.
- Added the exact master merge commit as an ancestor of the child branch while preserving the Scrum tree. The resulting merge base is exactly `a006c8a`, and comparison reports zero commits behind.
- Rechecked the diff: only `.agents/skills/scrum-team/SKILL.md`, `AGENTS.md`, `AGENT_STATE.md`, and `AGENT_WORKLOG.md` are changed. The parent continuity skill and backlog are not duplicated.
- QA PASS and Senior Reviewer APPROVE on the final master-based four-file diff. Exact-head CI remains pending: run #43535300671 validates the superseded pre-retarget head only; no run has yet registered for `1e38e71dbc07a4f6202322c5cc8afbdc61e9d863`.
- PR #81 remains open. No merge has been authorized.


---

## 2026-11-13 — Scrum operating model merged; reconcile post-merge checkpoint

- Brian explicitly authorized merging PR [#81](https://github.com/brianfiszman/dotfiles/pull/81). GitHub confirmed a squash merge as [`e43ce86`](https://github.com/brianfiszman/dotfiles/commit/e43ce86e98344094021421cbe789df5e956b8982); `master` now points to that commit.
- The exact source head `62718319fa8e2ad121a9b2b48276c8218ef508e3` passed pull-request run [#43536799096](https://github.com/brianfiszman/dotfiles/actions/runs/43536799096). All job steps passed: checkout, system tools, pinned Neovim, isolated workspace, installer safety, locked plugin restore/build hooks, normal headless startup, and log upload.
- Final review before merge was QA PASS and Senior Reviewer APPROVE. The merged PR contained exactly four documentation paths: `.agents/skills/scrum-team/SKILL.md`, `AGENTS.md`, `AGENT_STATE.md`, and `AGENT_WORKLOG.md`. It changed no Neovim runtime configuration or workflow definitions.
- Issue [#80](https://github.com/brianfiszman/dotfiles/issues/80) was explicitly closed as completed after the merge. Parent PR [#79](https://github.com/brianfiszman/dotfiles/pull/79) is also merged as `a006c8a`; issue #78 is closed.
- Post-merge recovery audit found that the checkpoint shipped by PR #81 still described that PR as open and its exact-head CI as pending. This is stale operational state, not a code defect. Reconcile `AGENT_STATE.md` and this append-only log in a follow-up docs-only branch/PR based on the new master; do not edit master directly.
- Next: validate the final checkpoint-reconciliation PR on its exact head, then request Brian's explicit merge authorization. No additional merge is authorized by the #81 approval.


## 2026-11-13 — Classify CI applicability for checkpoint-only PR #82

- Inspected the live `.github/workflows/neovim-headless.yml` trigger configuration. Its `pull_request.paths` filter includes Neovim config, skill files, installer/test scripts, the workflow itself, and README, but excludes `AGENT_STATE.md` and `AGENT_WORKLOG.md`.
- PR #82 changes only those two excluded documentation files. Therefore no Neovim headless run is expected or required for this PR; zero check runs is not a failure and must not be described as pending CI.
- Validation for #82 is the exact two-file diff review, Markdown/link consistency, QA, and a separate Senior Reviewer pass. The successful #81 run remains evidence for #81's different source SHA, not for #82.


## 2026-11-13 — PR #82 documentation QA and Senior Reviewer pass

- Reviewed the PR #82 diff against current `master` at source head `0010f29d6e1afdf59e7bab66195b262c3dbae4ab`. The scope is exactly `AGENT_STATE.md` and `AGENT_WORKLOG.md`; no runtime, plugin, installer, or workflow files are changed.
- **QA PASS:** verified the live merge state for PRs #79/#81 and issues #78/#80, the exact successful #81 run and SHA, checkpoint next steps, internal links/evidence, workflow path-filter applicability, and preservation of the original work-log history. The work log is append-only; this result is a new entry.
- **Senior Reviewer APPROVE:** confirmed the checkpoint no longer presents #81 or its CI as pending, does not misrepresent absent Actions checks as failures, preserves the separate merge-authorization rule for #82, and adds no unrelated implementation scope.
- The Neovim headless Actions workflow is **not required** for this two-file PR because both changed paths are excluded by its `pull_request.paths` filter. This is not a passing runtime test; no runtime test was run or needed.
- PR #82 remains open. Its merge requires Brian's separate explicit authorization; authorization for PR #81 does not carry over.


## 2026-11-13 — Begin Sprint 1 Neotest lazy-loading implementation (#74)

- Branch: `feat/neotest-lazy-loading`, based on current `master` at `c203afd4256398ac003a28abc211cd4f8c376f19`.
- Verified #75 is complete in merged PR #77, so the Neotest spec no longer needs to own DAP activation.
- The existing Neotest module is imported while assembling `plugins.lua`; its setup registers six which-key mappings and eagerly requires the configured adapters. The plugin spec had no lazy trigger.
- Added `lazy = true` and lazy.nvim key triggers for the six existing mappings without changing their user-facing mapping definitions.
- Added `tests/nvim/neotest-lazy-loading.lua`. It checks idle startup, dispatches the existing Test Stop action (which does not start a suite), verifies Neotest/vim-test and configured adapter modules load, and checks that ordinary testing leaves DAP unloaded.
- Added the scenario to `scripts/test-nvim-headless.sh`. No lockfile changes.
- At this checkpoint the implementation is committed, but no Neovim runtime test has run. The trigger-to-which-key handoff and adapter assertions remain unverified until a real headless run.
- Next: inspect the exact diff, open the focused #74 PR, and use its exact-head CI as runtime evidence. Keep QA and Senior Review separate; do not merge without Brian's explicit authorization.


## 2026-11-13 — Open PR #84 and begin exact-head validation

- Opened [PR #84](https://github.com/brianfiszman/dotfiles/pull/84) from `feat/neotest-lazy-loading` to `master`, linking issue #74.
- PR head at creation: `156270eaa2c4e439e03050f22183d6e393ecdc8f`; base: `c203afd4256398ac003a28abc211cd4f8c376f19`.
- The PR contains the Neotest lazy spec, the new headless regression scenario, its runner integration, and checkpoint/work-log updates. It does not change `lazy-lock.json`.
- Initial lookup of workflow runs for the exact head returned no run. This is **not run / not yet observed**, not a pass or failure. Recheck the PR event before deciding whether the workflow is pending or was not triggered.
- Next: inspect the exact PR head and workflow event, then run QA and Senior Reviewer only after the relevant behavior check completes.



## 2026-11-13 — Fix Neotest lazy-trigger headless assertion (#74 / PR #84)

- The pull-request run [#43540903350](https://github.com/brianfiszman/dotfiles/actions/runs/43540903350) failed on source SHA `d06626861f88d61a3ca1d47f7a2ae409c3f51db3` after preparation, locked plugin restore/build hooks, and normal startup had passed.
- The failing assertion compared `mapping.lhs` byte-for-byte with the requested leader sequence. The subsequent successful trace established why that was invalid: the lookup key is `" ts"`, while Neovim reports the normalized `mapping.lhs` as `"<Space>ts"`; the mapping had a Lua callback and no string rhs.
- Commit [`4ca54c5`](https://github.com/brianfiszman/dotfiles/commit/4ca54c598b55f9129f15130eabe37c5e804ea691) corrected the test to accept callback-backed or rhs-backed mapping metadata, log the normalized lhs, and still dispatch the actual key before asserting Neotest and vim-test setup.
- Pull-request run [#43541470634](https://github.com/brianfiszman/dotfiles/actions/runs/43541470634) passed for exact source SHA `4ca54c598b55f9129f15130eabe37c5e804ea691`: isolated prepare, locked restore/build hooks, normal startup, Neotest lazy loading, Go lazy-loading regressions, Mason/DAP lazy-loading, and the Debug Test mapping all passed.
- Next: validate the branch after this checkpoint/work-log update, then complete QA PASS and a separate Senior Reviewer APPROVE. Interactive macOS behavior and a representative project test suite remain unverified.



## 2026-11-13 — Final PR #84 validation and review gates (#74)

- Final reviewed source snapshot: `8c1f99a07ddf17cfa839c954817d23f87e6705be` on `feat/neotest-lazy-loading`, base `master` at `c203afd4256398ac003a28abc211cd4f8c376f19`.
- Exact-head pull-request run [#43541878359](https://github.com/brianfiszman/dotfiles/actions/runs/43541878359) completed successfully. Preparation, installer safety, locked plugin restore/build hooks, normal headless startup, Neotest lazy-loading, Go lazy-loading, Mason/DAP lazy-loading, and Debug Test behavior all passed. The log shows `<Space>ts` as a callback-backed lazy mapping; dispatching it loads Neotest, vim-test and all configured adapters while leaving DAP unloaded.
- **QA PASS:** verified all #74 acceptance criteria. The six original key triggers and their which-key mappings remain; idle startup is clean; the first test action loads the testing integration; ordinary tests do not load DAP; Debug Test does; discovery remains disabled; no lockfile or plugin version changes. The headless test deliberately uses Test Stop so it can exercise first-use loading without starting a real project suite.
- **Senior Reviewer APPROVE:** separate complete-diff review found no blocking correctness, scope, architecture, compatibility or test-quality issue. No lockfile or unrelated plugin changes.
- The Scrum role passes are simulated by one assistant, not genuinely independent human reviewers. A representative project-level test run and interactive use on Brian's Mac remain unverified.
- PR [#84](https://github.com/brianfiszman/dotfiles/pull/84) remains open and unmerged; issue [#74](https://github.com/brianfiszman/dotfiles/issues/74) remains open pending Product Owner acceptance and merge. No merge was authorized.
- Next: Brian reviews the PR and gives or withholds explicit merge authorization.


## 2026-11-13 — Merge Neotest lazy-loading and reconcile the backlog (#74 / PR #84)

- Brian explicitly authorized the merge after exact-head verification. PR [#84](https://github.com/brianfiszman/dotfiles/pull/84) was squash-merged into `master` as [`110c365`](https://github.com/brianfiszman/dotfiles/commit/110c3658085c4c23d847de361a08b5e15e72b605). GitHub then closed issue [#74](https://github.com/brianfiszman/dotfiles/issues/74) with state reason `completed`; its body was updated with the merge and validation record.
- Exact source head `f4b9f2744e65a23cbf8a6600abfefcc4ca75bf12` passed pull-request run [#43542407243](https://github.com/brianfiszman/dotfiles/actions/runs/43542407243). Logs show successful isolated preparation, locked plugin restore/build hooks, normal startup, Neotest lazy-loading, Go, Mason/DAP, and Debug Test regression checks.
- **QA PASS** and **Senior Reviewer APPROVE** were recorded against the final PR snapshot. The Scrum roles were performed sequentially by one assistant, not separate people or independent human reviewers. Test Stop and Debug Test were dispatched in headless checks; the other four preserved mappings were statically checked. A representative project test suite and interactive macOS behavior remain unverified.
- Updated parent [#43](https://github.com/brianfiszman/dotfiles/issues/43) to show #74 and #75 complete and #76 still open. #76 was not part of Sprint 1 and was not automatically pulled into the sprint.
- The PR #84 checkpoint shipped with pre-merge state, so a documentation-only reconciliation branch `docs/neotest-merge-reconciliation` was created from merge commit `110c365`. Its scope is the canonical backlog, execution checkpoint, and this append-only work log; no Neovim runtime files or workflows change.


## 2026-11-13 — PR #85 documentation QA and Senior Reviewer pass

- Reviewed PR [#85](https://github.com/brianfiszman/dotfiles/pull/85) at source head `0208c0bdb26fb1575510f2fb63c4da0c3f864f4c`, based on master merge commit `110c3658085c4c23d847de361a08b5e15e72b605`. The complete diff contains only `AGENT_STATE.md`, `AGENT_WORKLOG.md`, and `docs/neovim-modernization-backlog.md`; it is zero commits behind master.
- **QA PASS:** verified PR #84's merge state and exact-head Actions run, issue #74's `completed` closure, parent #43 remaining open, child #76 remaining open, and PR #83 remaining open/unmerged. Checked the checkpoint, append-only work-log entry, backlog active/completed lists, exact SHA/run references, Markdown fence balance, and absence of stale #74/#84 pre-merge claims in the current checkpoint.
- Confirmed the Neovim workflow's path filters exclude all three changed documents. No Neovim runtime workflow is expected; no runtime test was run or claimed for this documentation-only PR.
- **Senior Reviewer APPROVE:** inspected the complete three-file diff for stale handoffs, contradictory states, lost work-log history, incorrect validation claims, and accidental runtime scope. No blocking findings. QA and Reviewer are simulated Scrum role passes performed sequentially by one assistant, not independent human reviews.
- PR #85 remains open. Its merge requires Brian's separate explicit authorization; PR #84's authorization does not carry over.


## 2026-11-13 — Merge post-Neotest documentation reconciliation (#85)

- Brian separately authorized the squash merge of documentation PR [#85](https://github.com/brianfiszman/dotfiles/pull/85). GitHub confirmed merge commit [`3c3abc6`](https://github.com/brianfiszman/dotfiles/commit/3c3abc65432d8b00bc4272866f49d000dc703eb5) for exact reviewed PR head `025d29625dad4631ef0efe690b3e24bc701a432d`.
- PR #85's three-file docs-only diff had QA PASS and Senior Reviewer APPROVE; the Neovim runtime workflow was not applicable because its path filter excludes the three changed documentation files.
- Verified after merge: PRs #84 and #85 are merged; issue #74 is closed as completed; parent #43 remains open; #76 remains open; PR #83 remains open/unmerged.
- The checkpoint merged by #85 necessarily described #85 as awaiting authorization. Created follow-up docs-only branch `docs/post-pr85-merge-checkpoint` from `3c3abc6` to reconcile `AGENT_STATE.md` and append this event to the work log. No runtime code, plugin lockfile, installer, tests, backlog, or workflow files are changed.
- PR #86 will carry that checkpoint update. It requires its own QA/reviewer pass and Brian's separate merge authorization; authorization for #85 does not carry over.


## 2026-11-13 — PR #86 checkpoint reconciliation QA and Senior Reviewer pass

- Reviewed PR [#86](https://github.com/brianfiszman/dotfiles/pull/86) at source head `0c9d2bb3f57ef28df4a7338d96875d0bd7d9d032`, based on PR #85 merge commit `3c3abc65432d8b00bc4272866f49d000dc703eb5`. The diff contains only `AGENT_STATE.md` and `AGENT_WORKLOG.md`; it is two commits ahead and zero behind master.
- **QA PASS:** verified PRs #84/#85 merged, issue #74 completed, parent #43 and child #76 open, PR #83 open/unmerged, exact merge SHAs, post-merge checkpoint content, append-only history, balanced Markdown fences, and no runtime/config/test paths.
- Confirmed the Neovim headless workflow filters out these two documentation files. No runtime workflow is expected; no runtime test was run or claimed.
- **Senior Reviewer APPROVE:** the complete two-file patch was checked for stale PR #85 pending claims, incorrect issue/PR states, broken handoff, accidental loss of prior work-log history, and scope expansion. No blocking findings. These are sequential simulated Scrum role passes, not independent human reviews.
- PR #86 remains open. Brian's authorization for PR #85 does not authorize PR #86; a separate explicit merge decision is required.


## 2026-11-14 — Sprint 2 planning and native LSP migration (#41)

- Brian approved reprioritizing Sprint 2 from Telescope lazy-loading to the LSP foundation. Sprint dates: 2026-11-14 through 2026-11-20. Sprint Goal: move to one explicit native LSP configuration/activation path per server while preserving supported workflows. Issue [#41](https://github.com/brianfiszman/dotfiles/issues/41) is the sole committed functional issue (T-shirt size M); #42, #44, #76, and a full plugin inventory update remain later work.
- Recovered the actual post-PR-86 state: PR [#86](https://github.com/brianfiszman/dotfiles/pull/86) is merged as `c587c8854faf2e99770ca6f30a51a529a38140bb`. The old checkpoint still described it as open; this entry and the active checkpoint reconcile that stale handoff. PR #83 remains open/unmerged.
- Audited the LSP setup. The old path had lsp-zero v3.x, Mason-LSPConfig v1-style `handlers`, direct `require("lspconfig").setup()` calls, duplicated generic/special server setup, and TypeScript Tools. The exact locked TypeScript Tools revision calls `require("lspconfig")` internally, so the chosen migration is native `ts_ls`, preserving complete-function-call completions and references/implementations CodeLens.
- **Correction:** an earlier response called lsp-zero officially dead. Its upstream README still describes a v4 branch; that claim was too strong. The reason for removing the repository's v3.x integration is architectural simplification and moving to native Neovim APIs, not a verified declaration that the entire project is dead.
- Selected compatible released dependencies: nvim-lspconfig v2.12.0 (`4d363f93c3581b9212a24f7a830d7590b3f050af`), Mason-LSPConfig v2.3.0 (`a5671269a1ddfa7790cdf97c14e600e269da550f`), and Mason v2.3.1 (`2a6940af80375532e5e9e7c1f2fc6319a1b7a69d`). The nvim-lspconfig release requires Neovim 0.11.3+, so CI's pinned version was raised from v0.11.0 to v0.11.3. This is a targeted LSP compatibility update, not a mass plugin update.
- Implementation branch: `feat/lsp-native-setup-41`, created from master after PR #86. Changes so far replace lsp-zero with native `vim.lsp.config()` / `vim.lsp.enable()`, set Mason-LSPConfig `automatic_enable=false`, consolidate each server's configuration into one override table/loop, move completion mappings off lsp-zero, migrate TypeScript to `ts_ls`, update Mason's repository namespace in DAP, update only the LSP lock entries, and add headless assertions plus a script phase.
- Neodev is deliberately retained for #42. Its `before_init` helper still imports `lspconfig.util`; this is a known transitional compatibility path to remove when lazydev replaces neodev. No direct legacy `require("lspconfig").<server>.setup()` calls remain in the new LSP module.
- Validation status at this checkpoint: **not run**. The real plugin restore, native startup, and LSP assertions are pending a PR-triggered Actions run. No QA PASS, Senior Reviewer APPROVE, issue closure, or merge is claimed.
- Next: inspect the complete branch diff and test harness carefully, open the PR for #41, then run and inspect the exact-head Actions workflow before separate QA and Senior Reviewer passes. Merge still requires Brian's explicit authorization.


## 2026-11-14 — Open PR #87 and start exact-head validation

- Opened [PR #87](https://github.com/brianfiszman/dotfiles/pull/87) for issue #41. Base is master at `c587c8854faf2e99770ca6f30a51a529a38140bb`; the branch head at first review was `09d59bf996bdd9e117ae3148c645c9030af2a2bb`.
- Reviewed the changed-file list and key diffs. Reduced the lockfile to the repository's existing compact format so only the intended LSP dependency changes appear. Corrected the new shell test phase to use single-line continuations.
- Further review found that the original Svelte notification autocmd combined `buffer` and `pattern`, which are mutually exclusive in Neovim's autocmd API and would also have changed the original project-wide JS/TS save behavior. Reworked it to register one project-wide JS/TS watcher per Svelte LSP client and send a proper file URI.
- Confirmed every configured server name exists in the selected nvim-lspconfig v2.12.0 release, including native `ts_ls`.
- Exact-head PR workflow [#43551881373](https://github.com/brianfiszman/dotfiles/actions/runs/43551881373) was observed for the reviewed head and is **queued**. Its job has not started; no runtime validation is claimed yet.
- The PR's current head advanced after the reviewed snapshot due to the Svelte autocmd fix. Re-fetch the PR head and confirm the workflow is for the latest SHA before treating any result as validation.
- Next: update the checkpoint/backlog to the live PR state, then inspect the queued run's jobs and steps until it completes. QA and Senior Reviewer remain separate pending gates; merge requires Brian's explicit authorization.


## 2026-11-14 — CI cancellation and rerun for PR #87

- Run [#43551881373](https://github.com/brianfiszman/dotfiles/actions/runs/43551881373) for code SHA `09d59bf996bdd9e117ae3148c645c9030af2a2bb` was cancelled during the first system-tools installation step. Neovim installation, isolated workspace preparation, plugin restore/build hooks, normal startup, and tests were all skipped; this is not a test failure and provides no runtime evidence.
- The PR had advanced to `70cb57792a3fe9e395295d3a9b2ec2a6d08d819b` through documentation-only checkpoint/worklog updates after the code snapshot. The path-filtered runtime workflow did not produce a run for that docs-only head. The implementation code was unchanged.
- Explicitly re-ran the cancelled workflow job. GitHub accepted the rerun; the run is pending again for the original code SHA. The final review must separately inspect the documentation-only commits at the current PR head.
- Next: monitor the rerun through plugin restore and all test phases. Do not call the cancelled attempt a failure or a pass.


## 2026-11-14 — Fresh PR #87 workflow triggered on latest head

- The rerun of [#43551881373](https://github.com/brianfiszman/dotfiles/actions/runs/43551881373) was also cancelled at job setup before any test phase. No validation evidence was produced by either attempt.
- Added a small, relevant CI check to the workflow: parse `.config/nvim/lazy-lock.json` with Python before plugin restore. This both validates the changed lockfile and causes the path-filtered runtime workflow to run on the current PR snapshot.
- GitHub created new PR workflow [#43552051042](https://github.com/brianfiszman/dotfiles/actions/runs/43552051042) for current head `6c359e4ea597842479badf0f4c827244b9629ca4`, based on master `c587c8854faf2e99770ca6f30a51a529a38140bb`. The run is **pending**; its job has not yet been observed.
- Next: inspect run #43552051042 through completion. The previous cancelled runs are not failures of the Neovim config and are not passes.


## 2026-11-14 — Final LSP compatibility refinements before CI

- Updated the Neovim version guard in `.config/nvim/init.lua` and the README requirement to **0.11.3+**, matching the selected nvim-lspconfig v2.12.0 minimum. The CI baseline is also v0.11.3.
- Preserved the actual diagnostics behavior from the old cmp config: virtual text remains disabled; signs, severity sorting, and rounded diagnostic floats remain configured.
- Preserved Neodev's `.luarc.json` / `.luarc.jsonc` JSON schema behavior directly in native `jsonls` settings while retaining Neodev's `before_init` integration for lua_ls. Neodev remains a transitional dependency until #42.
- Separated the Mason-managed server list from the enabled server list: the previous Svelte install policy is unchanged (Svelte remains explicitly enabled but is not added to Mason's install list); native `ts_ls` is added to Mason installs.
- Replaced the TypeScript root markers with a native `root_dir(bufnr, on_dir)` callback because nvim-lspconfig's built-in `ts_ls` config already defines a `root_dir`; `root_markers` alone would not override it. This preserves the old yarn.lock/package-lock.json workspace policy.
- Added native CodeLens refresh on TypeScript buffer enter/hold/insert-leave. The TypeScript language server's documented settings support function-call completions and references/implementations CodeLens. Its documented API has no direct equivalent for TypeScript Tools' member-specific CodeLens toggle; that limitation is called out in the PR. Proprietary `:TSTools*` commands are also not mapped in this repository and are called out as a possible manual-use loss.
- Final exact code/README head before this checkpoint update: `7d8bd3ecb64408f3b538f2efdec27f11bd5c4ff3`. PR [#87](https://github.com/brianfiszman/dotfiles/pull/87) is open.
- Current workflow [#43552641966](https://github.com/brianfiszman/dotfiles/actions/runs/43552641966) is **in progress** on that head. The system-tools installation step is running; Neovim installation, lockfile validation, plugin restore/build hooks, startup, and LSP assertions have not run yet.
- Earlier workflow attempts were cancelled as code commits superseded their heads; none produced runtime validation. Do not count them as failures of the LSP config or as passes.
- Next: monitor #43552641966 through completion, then run separate QA and Senior Reviewer passes against the exact PR diff. Merge still requires Brian's explicit authorization.


## 2026-11-14 — Make LSP diagnostics visible inline (#41 / PR #87)

- Brian's manual smoke test confirmed completion and `K` hover work. He reported that errors were represented by a red sign but their message was not visible unless explicitly opened.
- Traced this to the intentional `virtual_text = false` setting. Updated diagnostics to `virtual_text = { spacing = 2, source = "if_many" }`, retaining signs, underline, severity sorting, and the detailed float/navigation mappings.
- Updated `tests/nvim/lsp-native-setup.lua` to assert that inline diagnostic virtual text is enabled.
- Current code/test head: `dd801182126c65a01123c65daf72a43220243e22`. Exact-head workflow [#43600006360](https://github.com/brianfiszman/dotfiles/actions/runs/43600006360) is in progress; no result is claimed yet.
- Brian does not recall using proprietary `:TSTools*` commands. No repository mappings/configuration for them were found; no compatibility shim is planned.
- Earlier exact-head CI, QA, and Senior Reviewer gates passed on the predecessor implementation. Repeat CI, QA, and Senior Reviewer against the final PR head after this adjustment. F3 formatting and the inline diagnostic display still need manual validation. PR #87 remains open and unmerged; no merge authorization was given.


## 2026-11-14 — Final inline diagnostics validation and review gates (#41 / PR #87)

- The diagnostic visibility change is `virtual_text = { spacing = 2, source = "if_many" }`; it keeps gutter signs and detailed floats while showing messages inline.
- The first headless run after that change found that the new LSP module redundantly set `update_in_insert = false`, conflicting with the existing global setting in `.config/nvim/lua/navigation/bufferline.lua` (`true`). Removed the LSP-level assignment and removed the test's incorrect expectation. Bufferline remains the owner; the diagnostic change itself stays in place.
- Final code/test head `380e35d0960aad312d23c2cd8509c42fb4f6d721` passed exact-head Actions run [#43600645750](https://github.com/brianfiszman/dotfiles/actions/runs/43600645750): isolated preparation, Neovim v0.11.3, lockfile validation, plugin restore/build hooks, normal startup, native LSP assertions, Neotest, Go, and DAP checks.
- **QA PASS:** issue #41 acceptance criteria and final PR diff checked, including single server ownership/activation, native `ts_ls`, preserved server settings and custom hooks, diagnostic display, keymaps, formatting, lockfile scope, and CI evidence.
- **Senior Reviewer APPROVE:** separate complete-diff pass found no blocking correctness, architectural, compatibility, test, or scope issues. These are sequential simulated role passes by the assistant, not independent human reviews.
- Brian confirmed completion and `K` hover work. He does not recall using `:TSTools*` commands; no proprietary-command compatibility layer is planned. Manual confirmation of `F3` formatting and inline messages in a representative local project remains pending; so do representative TypeScript/ESLint attachment and interactive macOS checks.
- PR #87 remains open and unmerged; issue #41 remains open pending Product Owner acceptance. No merge authorization has been given.

## 2026-11-14 — Consolidate formatting and JavaScript/TypeScript ESLint ownership (#41 / PR #87)

- Brian reported that the Conform Ctrl+F action produced the expected formatting, while the LSP F3 path produced a different result. Inspected the actual keymaps: Ctrl+F runs Conform's :Format (JS/TS uses prettierd if available, otherwise prettier); F3 and Ctrl+Shift+F called vim.lsp.buf.format() directly. Removed those competing LSP formatter mappings so the shared Conform path is canonical. Prettier uses Prettier configuration; it is not an ESLint --fix invocation. ESLint's existing EslintFixAll remains on save.
- Brian's screenshot showed a diagnostic labelled eslint: Parsing error: ',' expected. The repo configured ESLint diagnostics through the ESLint LSP and also ran both eslint and eslint_d from nvim-lint on JS/TS read/write/insert-leave events. This is credible overlapping asynchronous diagnostic ownership, but the screenshot alone does not prove that it caused the exact stale result.
- Removed JS/TS/JSX/TSX ESLint entries from nvim-lint; the ESLint language server now owns those diagnostics. Other nvim-lint filetype configurations remain. Kept ESLint's save-time fix action.
- Added headless assertions that the normal-mode Ctrl+F mapping and :Format exist, and nvim-lint does not run eslint / eslint_d for JS/TS. Documented the canonical workflow in README and the reusable single-owner rule in .agents/skills/neovim-maintenance/SKILL.md.
- Updated issue #41 acceptance criteria and PR #87 description.
- Implementation snapshot before this checkpoint update: 1b8bfbf87bec7e36582fff131a280be0f8d35b3e. Run #43602089534 was in progress on that snapshot; the checkpoint/skill/worklog updates may supersede it. Validate the final branch head and repeat QA and Senior Reviewer on the complete current diff.
- Manual validation still pending: restart Neovim after update, check that inline ESLint diagnostics no longer reappear after undo, and confirm Ctrl+F is the only formatting behavior in normal mode. PR #87 remains open/unmerged; no merge authorization.

## 2026-11-14 — Make Conform Ctrl+F mapping deterministic and testable (#41 / PR #87)

- Run #43602089534 failed at the new assertion using vim.fn.maparg("<C-f>", "n"). The same run had already passed preparation, plugin restore/build hooks, normal startup, and the :Format command existence check. The failing check was a false negative: this mapping had been registered through WhichKey v3's legacy register() queue and was not visible to maparg() at that test point.
- Switched the primary Conform Ctrl+F mapping to a direct vim.keymap.set("n", "<C-f>", "<cmd>Format<cr>", { desc = "Format", silent = true }). This makes the normal-mode mapping explicit and inspectable. Restored the maparg assertion; it now tests a direct Neovim mapping rather than deferred WhichKey state.
- Current implementation/test snapshot: 3334b4b9cdf0b22de0990e4def6ff298f4a40bd0. Validate this exact head. Prior run failure was test-timing/registration observability, not a Conform formatting failure.
- The same change set makes ESLint LSP the only JS/TS ESLint diagnostic publisher by removing eslint/eslint_d from nvim-lint's JS/TS filetype list. The screenshot's stale message remains unproven but duplicate asynchronous ownership is removed.
- Manual follow-up: Brian should restart Neovim after updating, use Ctrl+F in a TypeScript file, and check whether the old ESLint diagnostic still reappears after undo. PR #87 remains open/unmerged; no merge authorization.

## 2026-11-14 — Preserve native ESLint save fix, complete QA and Senior Review (#41 / PR #87)

- Final review against the pinned nvim-lspconfig v2.12.0 source found that the native ESLint config creates the buffer-local command `LspEslintFixAll`, not the legacy `EslintFixAll`. The migration had overridden the native ESLint `on_attach`, then invoked the old command name on save. That would break ESLint auto-fixes on save.
- Fixed the custom ESLint attach hook to compose the pinned nvim-lspconfig default `on_attach`, preserving creation of `:LspEslintFixAll`, then adds shared keymaps and a `BufWritePre` autocmd that invokes `LspEslintFixAll`.
- Added a headless regression that uses a stub ESLint client, calls the configured attach hook, verifies the buffer-local command exists, executes `BufWritePre`, and asserts the client receives `workspace/executeCommand` with `eslint.applyAllFixes`. The test also asserts the deprecated `:EslintFixAll` command is not being used.
- Updated README and PR description to use the native `:LspEslintFixAll` command name.
- Exact implementation/test head `facec29efbe2c7628cb68e077afc27d8c06c3613` passed Actions run [#43603153115](https://github.com/brianfiszman/dotfiles/actions/runs/43603153115): isolated preparation, Neovim v0.11.3, lockfile validation, real locked plugin restore/build hooks, normal startup, native LSP tests (including the ESLint save-fix simulation), and Neotest/Go/DAP regression checks.
- **QA PASS:** reviewed every issue #41 acceptance criterion against the final diff and exact-head evidence, including formatter ownership, diagnostic ownership, inline diagnostics, native ESLint save fixes, server activation, dependency scope, and existing workflows.
- **Senior Reviewer APPROVE:** separate final-diff review found no blocking correctness, architecture, compatibility, test, or scope issues. QA and Senior Reviewer are simulated sequential passes by one assistant, not independent human reviewers.
- Manual checks still pending: Brian should confirm Ctrl+F behavior and whether the stale ESLint diagnostic remains gone after restart and undo in a representative TypeScript project. Headless tests cannot prove project-specific attachment or interactive macOS behavior. PR #87 remains open/unmerged; no merge authorization has been given.


## 2026-11-14 — Recover PR #87 exact-head state and tighten the diagnostic handoff

- Recovered live state for [PR #87](https://github.com/brianfiszman/dotfiles/pull/87): branch `feat/lsp-native-setup-41`, base `master` at `c587c8854faf2e99770ca6f30a51a529a38140bb`, PR head before this checkpoint update `3b7def57ed417a94278255357e5ad2381b917b62`. [Issue #41](https://github.com/brianfiszman/dotfiles/issues/41) and PR #87 are still open; no merge was performed or authorized.
- Compared the current PR head with code/test SHA `facec29efbe2c7628cb68e077afc27d8c06c3613`: two commits ahead, zero behind, and only checkpoint/work-log documentation paths changed. The implementation and test files are unchanged.
- Exact current PR-head pull-request run [#43603478475](https://github.com/brianfiszman/dotfiles/actions/runs/43603478475) completed successfully on `3b7def57ed417a94278255357e5ad2381b917b62`. All job steps passed, including isolated preparation, Neovim v0.11.3 installation, lockfile validation, locked plugin restore/build hooks, normal headless startup, and the startup script's behavioral regression scenarios. The earlier implementation/test run [#43603153115](https://github.com/brianfiszman/dotfiles/actions/runs/43603153115) additionally exercises the native LSP, Ctrl+F, duplicate-linter, and mocked ESLint save-fix assertions on exact code/test SHA `facec29`.
- Reconfirmed the formatting contract: Normal-mode Ctrl+F maps directly to Conform `:Format`; JS/TS chooses `prettierd` or `prettier`. It follows Prettier configuration and is **not** ESLint `--fix`. The LSP attach path has no competing F3 / Ctrl+Shift+F formatter mapping. ESLint's `:LspEslintFixAll` remains a separate save-time action.
- Reconfirmed diagnostic ownership: `nvim-lint` no longer launches `eslint` / `eslint_d` for JS/TS/JSX/TSX, leaving the ESLint LSP as the configured ESLint diagnostics owner. The headless assertion verifies this configuration boundary; it does not reproduce out-of-order server messages or prove that duplicate publishers caused Brian's exact stale diagnostic.
- Additional diagnostic investigation: Neovim v0.11.3's default *push* `publishDiagnostics` handler applies the notification without comparing its optional document version to the buffer's current version. This is only a potential stale-result mechanism if the actual server uses push diagnostics and delivers an older version late; the available evidence does not establish that this is the ESLint path in Brian's project. Do not add a global diagnostic-handler override without capturing the actual diagnostic source/client and LSP log first.
- **QA PASS (simulated):** rechecked issue #41 acceptance criteria, the exact implementation/test files, and the exact current-head workflow evidence. **Senior Reviewer APPROVE (simulated):** inspected the current implementation diff and the two later documentation-only commits; no new blocking finding. These are sequential roles performed by one assistant, not independent human reviews.
- Still pending: local representative TS/ESLint attachment and Ctrl+F check; reproduce edit → fix → undo with the diagnostic visible and capture `:lua vim.print(vim.diagnostic.get(0))` plus the relevant `:LspLog` lines so the publishing client/path can be identified. Keep PR #87 and issue #41 open until Brian accepts the result. Merge requires his explicit authorization.


## 2026-11-14 — Merge native LSP ownership and begin Lazydev migration (#41 → #42)

- Brian explicitly authorized merging [PR #87](https://github.com/brianfiszman/dotfiles/pull/87). GitHub confirmed the squash merge into `master` as [`a743684`](https://github.com/brianfiszman/dotfiles/commit/a74368456f9c829197aa7569d6cf720b1bc7d9d5); issue [#41](https://github.com/brianfiszman/dotfiles/issues/41) was closed as completed.
- Exact PR-head run [#43604418747](https://github.com/brianfiszman/dotfiles/actions/runs/43604418747) passed on `f2abaeca1e5f9e9adaa08b867461b9c1632bfecc`. Post-merge push run [#43604690496](https://github.com/brianfiszman/dotfiles/actions/runs/43604690496) also passed on merge commit `a743684`, including isolated preparation, locked plugin restore/build hooks, normal startup, and artifact upload.
- The original JS/TS diagnostic reappearing after edit/undo remains unverified in Brian's real project. The configuration removes competing nvim-lint ESLint publishers, but the precise reported race was not reproduced; retain it as a manual follow-up, not a proven root-cause resolution.
- Began [#42 — Replace Neodev with Lazydev](https://github.com/brianfiszman/dotfiles/issues/42) on branch `feat/lazydev-42`, based on the #87 merge commit. Opened [PR #88](https://github.com/brianfiszman/dotfiles/pull/88), head `360ed9b5df6d1d61a723a2287c6a4024917b6141`, base `master` at `a743684`.
- The migration uses a separate `ft = "lua"` Lazydev spec, native LSP and nvim-cmp integrations, and preserves the five prior plugin type libraries (Neotest, nvim-dap-ui, Treesitter, Plenary, Telescope). Explicit LuaJIT runtime paths, LuaLS global/function completion settings, runtime/config libraries, and the jsonls `.luarc` schema remain. The lockfile swaps only Neodev for pinned Lazydev commit `ff2cbcba459b637ec3fd165a2be59b7bbaeedf0d`.
- Added a dedicated headless test for non-Lua idle state, Lua filetype activation, `:LazyDev`, preserved libraries, nvim-cmp source registration, and native LuaLS integration. The first test draft checked the cmp source immediately; source inspection showed Lazydev defers integration setup with `vim.schedule`, so the test now waits for the registered source before asserting it.
- Confirmed the locked nvim-cmp revision `a1d504892f2bc56c2e79b65c6faded2fd21f3eca` provides `cmp.get_registered_sources()`, and inspected Lazydev's pinned integration APIs before configuring it.
- Exact PR-head workflow [#43605503484](https://github.com/brianfiszman/dotfiles/actions/runs/43605503484) was created for source/test SHA `360ed9b` and is **in progress** at this checkpoint. QA and Senior Reviewer gates remain pending until that run completes and the exact diff is rechecked. PR #88 has not been merged; explicit authorization is still required.


## 2026-11-14 — Preserve Neodev strict path semantics and rerun Lazydev CI (#42 / PR #88)

- Compared the recorded code/test SHA `360ed9b5df6d1d61a723a2287c6a4024917b6141` with the prior Neodev implementation at its locked revision. The old top-level `pathStrict = true` option is mapped by Neodev to `Lua.runtime.pathStrict = true` and to strict `?.lua` / `?/init.lua` paths. Added both the runtime flag and a headless assertion so the migration preserves the actual server setting, not just the path list.
- The first PR run [#43605503484](https://github.com/brianfiszman/dotfiles/actions/runs/43605503484) was cancelled while the plugin-restore/build step was actively cloning/building dependencies. Preparation and lockfile validation passed, but restore did not complete and normal startup plus all behavior tests were skipped. The log shows runner cancellation during a build, not a configuration assertion or compile failure; classify as **cancelled / inconclusive**, not test failure and not pass.
- The implementation/test head is now `56e054a93086b116a031fb829eed8e7b2699f592`. A fresh pull-request run [#43605709646](https://github.com/brianfiszman/dotfiles/actions/runs/43605709646) was created for this exact SHA and is **pending** at this checkpoint.
- PR #88 remains open and unmerged. QA and Senior Reviewer gates remain pending until the exact-head run finishes and the final diff is rechecked. Brian's explicit authorization is required before merging this PR.


## 2026-11-14 — Fix Lazydev behavior assertion after full integration reached the final check (#42 / PR #88)

- Run [#43605876070](https://github.com/brianfiszman/dotfiles/actions/runs/43605876070), exact PR source/test SHA `43fb08c5455003d4c716435265908ec1cd30e6c2`, completed real isolated preparation, lockfile validation, plugin restore/build hooks, and normal startup. The new `lazydev-lazy-loading.lua` scenario progressed through the lazy-only activation, LuaLS settings, all five plugin libraries, nvim-cmp source registration, and native LSP integration assertions, then failed at the last lazy.nvim plugin-spec filetype assertion.
- Root cause: lazy.nvim retains a string `ft = "lua"` in the plugin spec; the new assertion incorrectly passed that string to `vim.tbl_contains()`, which requires a table. This was a test defect, not a plugin configuration failure.
- Corrected the test to accept either the string `"lua"` or a list containing `"lua"`, matching the accepted lazy.nvim plugin-spec shapes. Fix commit [`ff5e1e5`](https://github.com/brianfiszman/dotfiles/commit/ff5e1e5ca1358516dfd1757c9ada173220a45540).
- Earlier attempts #43605503484 and #43605709646 were cancelled during runner setup/restore after newer commits superseded their heads; they did not reach the relevant behavior assertions and are not counted as code failures or passes.
- Fresh exact-head pull-request run [#43606069295](https://github.com/brianfiszman/dotfiles/actions/runs/43606069295) was created for `ff5e1e5ca1358516dfd1757c9ada173220a45540` and is **in progress**. At this checkpoint it is still in system-tools installation; plugin restore and behavior checks have not yet run for the corrected SHA.
- PR #88 remains open/unmerged. QA and Senior Reviewer remain pending until run #43606069295 finishes and the full diff is reviewed again. Merge requires Brian's separate explicit authorization.


## 2026-11-14 — Lazydev migration passes exact-head CI and review gates (#42 / PR #88)

- The corrected implementation/test snapshot is `ff5e1e5ca1358516dfd1757c9ada173220a45540`. Current PR head [`f472500d`](https://github.com/brianfiszman/dotfiles/commit/f472500d8bd79da0ad6eae559291e4fdc7aed745) is three documentation-only commits ahead. Comparing the exact test snapshot with the live branch confirms only `AGENT_STATE.md`, `AGENT_WORKLOG.md`, and `docs/neovim-modernization-backlog.md` changed afterward.
- Exact current-head pull-request run [#43606193476](https://github.com/brianfiszman/dotfiles/actions/runs/43606193476) completed successfully on `f472500d8bd79da0ad6eae559291e4fdc7aed745`. Every step passed: system packages, Neovim v0.11.3, lockfile validation, isolated installer preparation, locked plugin restore/build hooks, normal startup, native LSP assertions, dedicated Lazydev filetype assertions, Neotest, Go, DAP/Mason adapter installs, and artifact upload.
- The dedicated Lazydev log printed all expected markers: unloaded during unrelated startup; loaded for Lua and registered `:LazyDev`; preserved LuaLS runtime/config settings and all five plugin API libraries; nvim-cmp and native LSP integrations enabled.
- The earlier run [#43605876070](https://github.com/brianfiszman/dotfiles/actions/runs/43605876070) on predecessor SHA `43fb08c` failed only in the last assertion because lazy.nvim kept `ft = "lua"` as a valid string, not a list. Commit `ff5e1e5` corrected the assertion to accept either form; the current exact-head run passed.
- Earlier runs #43605503484 and #43605709646 were cancelled during runner setup/restore as newer commits superseded their heads. Run #43606069295 completed plugin restore successfully but was cancelled when documentation commits to the same PR branch triggered another pull-request workflow. These are cancellation/continuity events, not code/test failures.
- **QA PASS (simulated):** verified all issue #42 acceptance criteria against the full diff, the exact current-head CI evidence, and the dedicated Lazydev test output. **Senior Reviewer APPROVE (simulated):** separately inspected the code, lockfile, tests, script wiring, README, and maintenance skill; no blocking findings. These are sequential roles performed by one assistant, not independent human reviewers.
- Local Lua config completion/hover and plugin API resolution remain **unverified** until Brian tests a representative Lua project on macOS. PR #88 remains open and unmerged; this task has not received merge authorization.
