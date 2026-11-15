---
name: diagnostic-experiments
description: Bound debugging investigations with one hypothesis, one variable, and a stop rule so probes do not become the product.
---

# Diagnostic experiments

## When to use

Use this when a failure is not understood and you are about to instrument,
probe, or try another fix. It applies to editor behavior, CI, installers, and
scripted workflows. It is especially important after one fix attempt already
failed.

## Confirm the active artifact

Before stating the observation:

- Confirm the issue/PR is open and record the active branch and head SHA.
- If it is closed or superseded, follow its disposition/replacement link. Its
  runs describe the old artifact, not current behavior.
- Match the run's `head_sha` to the active head. An archive branch, alias
  branch, or older run is historical evidence.
- If GitHub cannot be reached, label the state **Unavailable** and stop. Do not
  substitute memory or a stale checkpoint.

Diagnosing a superseded artifact produces a confident fix for a bug that is no
longer active.

## Hard limits

- **Two attempts per symptom.** If two changes do not explain or fix the same
  symptom, stop changing the implementation. Write down what was ruled out and
  move one layer down or out.
- **One variable per experiment.** Change one option, version, fixture property,
  or code path at a time.
- **Timebox.** If an experiment cannot produce a decision within the current
  work slice, record the open question and ask before expanding.
- **No committed probe files or debug prints.** Use the temporary directory or a
  disposable change that is removed before review.

## Protocol

1. **State the observation.** One sentence, with the exact command, file, and
   expected vs actual result.
2. **State the hypothesis.** One sentence that could be false.
3. **Predict the result.** What will the experiment show if the hypothesis is
   true? What will falsify it?
4. **Run the smallest experiment.** Prefer reading the code or one command over a
   harness. Prefer a single assertion over a notebook.
5. **Record the result.** Link the exact output or run. Update the hypothesis.
6. **Decide:** confirmed, rejected, or inconclusive. Do not slide into another
   fix without naming the new hypothesis.

## Experiment ladder

Go down this list before building anything:

1. Read the actual code path and the configuration that remains active.
2. Reproduce the failure in the smallest real environment.
3. Prove the fixture's starting state (options, cwd, filetype, versions).
4. Compare against a pinned environment or known-good revision.
5. Inspect the upstream contract or issue tracker.
6. Add one temporary assertion that prints the disputed value.
7. Only then build a larger harness.

## Anti-patterns

- Adding lifecycle machinery (`InsertEnter`, `startinsert!`, custom state) before
  proving native behavior is insufficient.
- Committing a probe notebook, a child-Neovim probe, or debug prints.
- Changing the test expectation to match unexplained behavior.
- Treating a test failure as proof about production without isolating the
  fixture.
- Diagnosing a closed/superseded PR, an archive branch, or an old head as if it
  were the active artifact.
- Running the full integration suite repeatedly while the failing layer is still
  unknown.
- Stacking fixes: each new patch makes it harder to know which change mattered.

## Cleanup

Before review:

- Remove probes, debug prints, and temporary files.
- Convert the confirmed repro into one focused regression test.
- Record the root cause and the rejected alternatives in the worklog and, when
  durable, an incident or ADR.
- State what was not proven.

## When you cannot run locally

Some agents, including Codex, have no local Neovim or shell runtime. CI is then
the only execution environment, and every run is slow and expensive.

- Do not push a fix to learn what happens. Read the code, trace the path, and
  write the root-cause sentence before changing anything.
- Use the failing test's existing output. If it is not enough, add assertions
  that print expected vs actual, the relevant options, filetype, versions, and
  fold state. Keep them as assertions in the regression test; remove temporary
  probes before review.
- Batch related questions into one run. One run should answer the whole
  hypothesis, not one assertion at a time.
- Change one variable per run. Do not combine a fixture fix, a mapping change,
  and a version bump.
- After two failed CI runs on the same symptom, stop. Record the diagnosis,
  ruled-out layers, and the next question in the issue/PR, then hand off. Ask for
  a local reproduction or a targeted maintainer check.
- Never claim local verification. Report “not run locally” and cite the exact
  run and SHA.
- Prefer a test that fails with a precise message over one that fails on a line
  number.

## Worked example — #89/#90

The test failed at a line position. Two attempts added lifecycle machinery.
The experiment that resolved it was smaller: print `foldclosed(2)`, then run
native `o` with `foldenable=false` and with folds enabled. The fixture inherited
`foldmethod=syntax`; the source line was in a closed fold, so native `o`
correctly opened at row 4. The production mapping was not broken.

Lesson: prove the fixture's starting state before changing the implementation.
See `docs/incidents/2026-11-14-pr90-fold-test-failure.md`.

After #90 was closed and replaced by #93, a follow-up diagnosis cited #90's
failing run on `85f1ec7` as proof that current CI was broken. #93's active head
`77b0dad` had its own green run. The cited failure was historical evidence for a
closed PR. Resolve the active artifact before interpreting any run.
