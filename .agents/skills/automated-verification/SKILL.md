---
name: automated-verification
description: Turn every acceptance criterion into an executable reproduction and personally run it; reserve manual checks for behavior that is genuinely impossible to automate.
---

# Automated verification

## Core rule

For every behavior, scenario, or claim that must be reproduced to decide whether a task is complete, build or reuse an automated way to reproduce it and execute that test yourself. Do not leave a feasible reproduction as homework for the maintainer.

Writing a test is not the same as running it. A green unrelated check is not evidence for the behavior under test. A test that exercises only a mock or a lower-level substitute must be labeled with that limitation.

## Required workflow

1. **Translate acceptance criteria into observable outcomes.** State the user action, expected result, failure/edge cases, and the system boundary that owns the behavior.
2. **Find the real trigger.** Trace how the behavior is reached in normal use. Prefer exercising the same public API, UI event, terminal input, protocol message, CLI, worker, or service boundary as the user.
3. **Automate the reproduction.** Reuse the project's test runner first. Otherwise build a small disposable harness with isolated fixtures and controlled dependencies. Drive the application through its real entry point; do not call an internal helper and claim end-to-end coverage.
4. **Execute it yourself.** Run the focused test and the relevant broader suite. When local execution is unavailable, use the project's CI or another available execution environment. Inspect the exact job steps and result; do not merely add a workflow and assume it ran.
5. **Prove the test is meaningful.** Where practical, run it against the pre-fix revision or a controlled mutation and confirm it fails for the regression. Assert observable state, not implementation details alone.
6. **Retain the regression test.** A confirmed reproduction becomes an automated regression test with deterministic setup, useful expected-vs-actual diagnostics, cleanup, and a CI trigger.
7. **Report evidence precisely.** Name the command/harness, environment, exact commit SHA, test scope, and result. Separate tests authored from tests actually executed, and distinguish real integration from mocked coverage.

## Reproduce at the outermost practical boundary

Aim for the closest automated equivalent of the user's real workflow:

- UI behavior: use browser automation, a desktop harness, app-level integration tests, or an emulator rather than testing only a callback.
- Terminal behavior: use a real PTY/TUI and send the actual terminal input/protocol sequence where possible; an RPC-level event is not proof that the terminal emits that event.
- OS/event behavior: use supported virtual devices, event injection, protocol-level input, or a simulator, then assert the application's observable response.
- Service workflows: run the real application components against disposable local databases, containers, queues, and controlled HTTP servers; mock only external systems that cannot safely or reasonably be invoked.
- Filesystem/concurrency behavior: use real temporary files, processes, locks, and concurrent requests instead of stubbing the filesystem or scheduler.
- Performance behavior: collect repeatable measurements with controlled inputs and compare against a recorded baseline.

A mock is useful for isolating an external boundary, but it does not prove that the real adapter, protocol, runtime, or user-facing path works. Add a higher-level test whenever that boundary is available to automate.

## Exhaust automation before asking the maintainer

Before proposing a manual test:

1. Check whether the input can be generated at the protocol boundary (PTY bytes, UI events, HTTP requests, OS notifications, filesystem operations, IPC).
2. Check for an emulator, virtual display/device, headless mode, test server, local service, or CI runner that can execute the same path.
3. Check whether the relevant user action can be driven by browser/desktop automation or a scripted end-to-end harness.
4. If the agent cannot run it locally, move execution to CI or another available runner rather than transferring the test to the user.
5. Keep trying only while each attempt tests a distinct, reasoned approach; follow the project's diagnostic stop rule rather than stacking guesses.

Do not call a test "unautomatable" merely because the agent lacks a local GUI, device, or shell. Environment access is a tooling constraint; first find another execution environment.

## Narrow exception for genuinely irreducible manual checks

Ask the maintainer to perform a manual check only when the required evidence depends on something no available emulator, simulator, protocol injection, controlled integration environment, or CI runner can faithfully reproduce. Examples may include proprietary physical hardware behavior with no virtual equivalent, or a real external account/production condition that cannot safely be synthesized.

When this exception applies:

- Explain the specific technical reason automation cannot prove the behavior, and what alternatives were investigated.
- State exactly which part is already covered automatically and which single fact remains unverified.
- Keep the manual step small and record the exact procedure and expected observation.
- Do not present the task as fully verified, mark a PR ready, or merge while a required acceptance gate remains unverified.

Never ask the user to repeat a scenario merely because writing the harness is inconvenient or because the initial test was too shallow.

## Safety and test quality

- Use disposable data and isolated HOME/XDG/config directories. Do not write to production, real user files, or real external accounts during tests.
- Prefer local controlled services and deterministic fixtures. Never weaken assertions, skip tests, or replace real behavior with mocks just to get a green run.
- Bound waits and subprocesses; clean up processes, servers, temporary files, and state on both pass and failure.
- Keep probes temporary. Once the cause is confirmed, promote the useful reproduction into a focused regression test and remove probe-only code.
- After a fix, run the focused reproduction, relevant integration/end-to-end coverage, and required repository checks on the exact final head. Re-run checks whenever the tested SHA changes.

## Completion checklist

- [ ] Every acceptance criterion has an observable expected result.
- [ ] Every feasible reproduction is automated at the real user-facing boundary.
- [ ] The assistant executed the tests, locally or through an inspected CI run.
- [ ] Important regression tests fail on the old behavior or an equivalent controlled mutation, where practical.
- [ ] Tests are isolated, deterministic, bounded, and retained in CI.
- [ ] Mocked, simulated, and real integration coverage are labeled honestly.
- [ ] Any manual exception is proven irreducible, narrowly scoped, and explicitly left unverified until evidence arrives.
- [ ] The final report names the exact tested SHA and the checks that actually passed.
