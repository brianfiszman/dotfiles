"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const {
  evaluateNeovimRun,
  matchesPullRequestRun,
  selectLatestMatchingRun,
} = require("../../scripts/ci/neovim-integration-gate.cjs");

const BASE_SHA = "b".repeat(40);
const HEAD_SHA = "a".repeat(40);
const TESTED_SHA = "c".repeat(40);
const IDENTITY = { prNumber: 125, headSha: HEAD_SHA, baseSha: BASE_SHA };

function workflowRun(overrides = {}) {
  return {
    id: 101, run_number: 101, event: "pull_request", head_sha: HEAD_SHA,
    display_title: "Neovim headless smoke test [nvim-ci-baseline base=" +
      BASE_SHA + " pr_head=" + HEAD_SHA + " tested=" + TESTED_SHA + "]",
    status: "completed", conclusion: "success", created_at: "2026-11-26T16:00:00Z",
    pull_requests: [{ number: 125 }],
    ...overrides,
  };
}

function jobs({ decision = "success", fast = "success", linux = ["success"] } = {}) {
  return [
    { name: "Decide whether full integration is required", conclusion: decision },
    { name: "Fast shell and lockfile checks", conclusion: fast },
    ...linux.map((conclusion, index) => ({
      name: "Fresh install and headless startup (Neovim v0.12." + (6 + index) + ")",
      conclusion,
    })),
  ];
}

test("run selection requires the exact PR association, head SHA, and immutable base SHA", () => {
  const older = workflowRun({ id: 100, run_number: 100, created_at: "2026-11-25T16:00:00Z" });
  const latest = workflowRun({ id: 102, run_number: 102, created_at: "2026-11-26T17:00:00Z" });
  const candidates = [
    workflowRun({ id: 201, head_sha: "d".repeat(40) }),
    workflowRun({ id: 202, display_title: "Neovim [nvim-ci-baseline base=" +
      "e".repeat(40) + " pr_head=" + HEAD_SHA + " tested=" + TESTED_SHA + "]" }),
    workflowRun({ id: 203, pull_requests: [{ number: 124 }] }),
    workflowRun({ id: 204, event: "push" }),
    older, latest,
  ];
  assert.equal(matchesPullRequestRun(latest, IDENTITY), true);
  assert.equal(selectLatestMatchingRun(candidates, IDENTITY).id, 102);
  assert.equal(selectLatestMatchingRun([], IDENTITY), null);
});

test("full integration passes only when decision, fast checks, and every Linux matrix cell pass", () => {
  const result = evaluateNeovimRun(workflowRun(), jobs({ linux: ["success", "success"] }), IDENTITY);
  assert.equal(result.passed, true);
  assert.equal(result.mode, "full-integration");
});

test("process-only changes may skip runtime integration only when all Linux matrix cells are skipped", () => {
  const result = evaluateNeovimRun(workflowRun(), jobs({
    linux: ["skipped", "skipped"],
  }), IDENTITY);
  assert.equal(result.passed, true);
  assert.equal(result.mode, "process-only-skip");
});

test("mixed success and skipped runtime results fail closed", () => {
  for (const runtime of [
    { linux: ["success", "skipped"] },
    { linux: ["failure", "success"] },
    { linux: ["cancelled", "success"] },
  ]) {
    const result = evaluateNeovimRun(workflowRun(), jobs(runtime), IDENTITY);
    assert.equal(result.passed, false);
    assert.match(result.reason, /Runtime integration results must be all success or all skipped/);
  }
});

test("decision and fast checks are mandatory even when runtime jobs are skipped", () => {
  const decisionFailure = evaluateNeovimRun(workflowRun(), jobs({
    decision: "failure", linux: ["skipped"],
  }), IDENTITY);
  assert.equal(decisionFailure.passed, false);
  assert.match(decisionFailure.reason, /Integration decision did not succeed/);

  const fastFailure = evaluateNeovimRun(workflowRun(), jobs({
    fast: "failure", linux: ["skipped"],
  }), IDENTITY);
  assert.equal(fastFailure.passed, false);
  assert.match(fastFailure.reason, /Fast shell and lockfile checks did not succeed/);
});

test("missing or duplicate required jobs fail closed", () => {
  const valid = jobs();
  for (const invalid of [
    valid.filter((job) => !job.name.startsWith("Fresh install and headless startup")),
    valid.concat(valid[0]),
    valid.concat(valid[2]),
  ]) {
    assert.equal(evaluateNeovimRun(workflowRun(), invalid, IDENTITY).passed, false);
  }
});

test("a failed newest run is selected instead of falling back to an older green run", () => {
  const olderSuccess = workflowRun({ id: 301, run_number: 301, created_at: "2026-11-25T16:00:00Z" });
  const newerFailure = workflowRun({
    id: 302, run_number: 302, created_at: "2026-11-26T17:00:00Z", conclusion: "failure",
  });
  const selected = selectLatestMatchingRun([olderSuccess, newerFailure], IDENTITY);
  assert.equal(selected.id, 302);
  const result = evaluateNeovimRun(selected, jobs(), IDENTITY);
  assert.equal(result.passed, false);
  assert.match(result.reason, /concluded failure/);
});

test("pending, cancelled, and malformed runs do not pass", () => {
  for (const run of [
    workflowRun({ status: "in_progress", conclusion: null }),
    workflowRun({ status: "completed", conclusion: "cancelled" }),
    workflowRun({ display_title: "missing immutable base metadata" }),
  ]) assert.equal(evaluateNeovimRun(run, jobs(), IDENTITY).passed, false);
});

test("runtime jobs are skipped only under the same explicit process-only decision condition", () => {
  const workflow = fs.readFileSync(
    path.resolve(__dirname, "../../.github/workflows/neovim-headless.yml"), "utf8"
  );
  const expectedCondition = "$" +
    "{{ !cancelled() && (needs.integration-decision.result != 'success' || needs.integration-decision.outputs.required != 'false') }}";
  for (const jobName of ["headless-startup"]) {
    const start = workflow.indexOf("  " + jobName + ":\n");
    assert.notEqual(start, -1, "missing runtime job: " + jobName);
    const tail = workflow.slice(start + ("  " + jobName + ":\n").length);
    const nextJob = tail.search(/\n  [a-z][a-z0-9_-]*:\n/);
    const block = nextJob < 0 ? tail : tail.slice(0, nextJob);
    const condition = block.match(/^    if: (.+)$/m);
    assert.ok(condition, "runtime job has no explicit condition: " + jobName);
    assert.equal(condition[1], expectedCondition, jobName);
  }
  assert.match(workflow, /Verify native Linux xterm focus reaches Neovim through a real PTY/);
  assert.match(workflow, /Run isolated real Python provider provisioning and fresh-start checks/);
  assert.doesNotMatch(workflow, /macos-15|iTerm2|python-provider-macos/);
  assert.doesNotMatch(workflow, /^  integration-gate:/m);
  assert.doesNotMatch(workflow, /name: Neovim integration gate/);
});

test("the stable check context is supplied by the dedicated agent-preflight workflow", () => {
  const workflow = fs.readFileSync(
    path.resolve(__dirname, "../../.github/workflows/agent-preflight.yml"), "utf8"
  );
  assert.match(workflow, /name: Neovim integration gate/);
  assert.match(workflow, /^jobs:$/m);
  assert.match(workflow, /^  integration-gate:$/m);
  assert.doesNotMatch(workflow, /^integration-gate:$/m);
  assert.match(workflow, /actions: read/);
  assert.match(workflow, /workflow_id: NEOVIM_WORKFLOW_ID/);
  assert.match(workflow, /evaluateNeovimRun/);
});
