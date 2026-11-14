"use strict";
const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  determineIntegrationRequirement,
  isIntegrationPath,
} = require("../../scripts/ci/neovim-integration-decision.cjs");

function makeContext(overrides = {}) {
  return {
    eventName: "pull_request",
    runId: 999,
    repo: { owner: "brianfiszman", repo: "dotfiles" },
    payload: { pull_request: {
      number: 92,
      head: { ref: "feat/ci-feedback-91", sha: "current-head" },
    } },
    ...overrides,
  };
}

function baseline(overrides = {}) {
  return {
    id: 123,
    head_sha: "previous-green-head",
    head_branch: "feat/ci-feedback-91",
    conclusion: "success",
    created_at: "2026-11-14T18:00:00Z",
    pull_requests: [{ number: 92 }],
    ...overrides,
  };
}

function fakeGithub(options = {}) {
  const calls = { runs: [], jobs: [], comparisons: [] };
  const runs = options.runs === undefined ? [baseline()] : options.runs;
  const jobsByRun = options.jobsByRun === undefined
    ? { 123: [{ name: "Fresh install and headless startup", conclusion: "success" }] }
    : options.jobsByRun;
  return {
    calls,
    rest: { actions: {
      async listWorkflowRuns(args) {
        calls.runs.push(args);
        if (options.error === "runs") throw new Error("runs unavailable");
        if (options.incomplete === "runs") return { data: {} };
        return { data: { workflow_runs: runs } };
      },
      async listJobsForWorkflowRun(args) {
        calls.jobs.push(args);
        if (options.error === "jobs") throw new Error("jobs unavailable");
        if (options.incomplete === "jobs") return { data: {} };
        return { data: { jobs: jobsByRun[args.run_id] || [] } };
      },
    } },
    async request(route, args) {
      calls.comparisons.push({ route, args });
      if (options.error === "compare") throw new Error("compare unavailable");
      return { data: options.comparison === undefined ? {
        status: "ahead",
        total_commits: 1,
        files: [{ filename: "AGENT_WORKLOG.md" }],
      } : options.comparison };
    },
  };
}

test("schedule, push and manual events always require the cold path", async () => {
  for (const eventName of ["schedule", "push", "workflow_dispatch"]) {
    const github = fakeGithub();
    const result = await determineIntegrationRequirement({ context: makeContext({ eventName }), github });
    assert.equal(result.required, true);
    assert.equal(github.calls.runs.length, 0);
  }
});

test("incomplete PR payload fails open", async () => {
  const result = await determineIntegrationRequirement({
    context: makeContext({ payload: { pull_request: { number: 92 } } }),
    github: fakeGithub(),
  });
  assert.equal(result.required, true);
  assert.match(result.reason, /payload is incomplete/);
});

test("no successful same-PR integration baseline fails open", async () => {
  const result = await determineIntegrationRequirement({
    context: makeContext(),
    github: fakeGithub({ runs: [] }),
  });
  assert.equal(result.required, true);
  assert.match(result.reason, /no previous successful full integration/);
});

test("different PRs and missing PR associations cannot provide a baseline", async () => {
  for (const run of [
    baseline({ pull_requests: [{ number: 90 }] }),
    baseline({ pull_requests: [] }),
    baseline({ pull_requests: undefined }),
  ]) {
    const github = fakeGithub({ runs: [run] });
    const result = await determineIntegrationRequirement({ context: makeContext(), github });
    assert.equal(result.required, true);
    assert.equal(github.calls.comparisons.length, 0);
  }
});

test("skipped, failed and cancelled integration runs cannot provide a baseline", async () => {
  for (const conclusion of ["skipped", "failure", "cancelled"]) {
    const github = fakeGithub({
      jobsByRun: { 123: [{ name: "Fresh install and headless startup", conclusion }] },
    });
    const result = await determineIntegrationRequirement({ context: makeContext(), github });
    assert.equal(result.required, true);
    assert.equal(github.calls.comparisons.length, 0);
  }
});

test("documentation-only delta skips integration after a successful baseline", async () => {
  const github = fakeGithub({
    comparison: { status: "ahead", total_commits: 1, files: [{ filename: "AGENT_WORKLOG.md" }] },
  });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, false);
  assert.match(result.reason, /only non-integration files changed/);
});

test("configuration and test changes require integration", async () => {
  for (const filename of [
    ".config/nvim/lua/lsp/native.lua",
    "tests/nvim/lazydev-lazy-loading.lua",
    "scripts/ci/neovim-integration-decision.cjs",
  ]) {
    const github = fakeGithub({
      comparison: { status: "ahead", total_commits: 1, files: [{ filename }] },
    });
    const result = await determineIntegrationRequirement({ context: makeContext(), github });
    assert.equal(result.required, true, filename);
    assert.match(result.reason, /integration-relevant files changed/);
  }
});

test("renaming a relevant file out of the watched tree still requires integration", async () => {
  const github = fakeGithub({
    comparison: { status: "ahead", total_commits: 1, files: [{
      filename: "docs/native-lsp.md",
      previous_filename: ".config/nvim/lua/lsp/native.lua",
    }] },
  });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, true);
});

test("current-head, failed, cancelled and unrelated-PR runs are excluded", async () => {
  const github = fakeGithub({ runs: [
    baseline({ id: 999, head_sha: "current-head" }),
    baseline({ id: 124, conclusion: "failure" }),
    baseline({ id: 125, conclusion: "cancelled" }),
    baseline({ id: 126, pull_requests: [{ number: 90 }] }),
  ] });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, true);
  assert.equal(github.calls.jobs.length, 0);
});

test("diverged, incomplete and API-capped comparisons fail open", async () => {
  const comparisons = [
    { status: "diverged", total_commits: 2, files: [{ filename: "AGENT_WORKLOG.md" }] },
    { status: "behind", total_commits: 2, files: [{ filename: "AGENT_WORKLOG.md" }] },
    { status: "ahead", total_commits: 2 },
    { status: "ahead", total_commits: 2, files: [] },
    { status: "ahead", total_commits: 2, files: Array.from({ length: 300 }, (_, i) => ({ filename: "docs/" + i })) },
    { status: "ahead", total_commits: 250, files: [{ filename: "AGENT_WORKLOG.md" }] },
    { status: "ahead", files: [{ filename: "AGENT_WORKLOG.md" }] },
  ];
  for (const comparison of comparisons) {
    const result = await determineIntegrationRequirement({
      context: makeContext(),
      github: fakeGithub({ comparison }),
    });
    assert.equal(result.required, true);
    assert.match(result.reason, /comparison may be incomplete/);
  }
});

test("workflow API failures fail open", async () => {
  for (const error of ["runs", "jobs", "compare"]) {
    const result = await determineIntegrationRequirement({
      context: makeContext(),
      github: fakeGithub({ error }),
    });
    assert.equal(result.required, true);
    assert.match(result.reason, /fail open to the full suite/);
  }
});


test("incomplete workflow-run and job-list API responses fail open", async () => {
  for (const incomplete of ["runs", "jobs"]) {
    const result = await determineIntegrationRequirement({
      context: makeContext(),
      github: fakeGithub({ incomplete }),
    });
    assert.equal(result.required, true);
    assert.match(result.reason, /response was incomplete; fail open/);
  }
});

test("integration runs on decision failure but does not outlive a cancelled workflow", () => {
  const workflowPath = resolve(__dirname, "../../.github/workflows/neovim-headless.yml");
  const workflow = readFileSync(workflowPath, "utf8");
  const jobStart = workflow.indexOf("  headless-startup:");
  assert.notEqual(jobStart, -1, "headless-startup job must exist");
  const headlessJob = workflow.slice(jobStart);
  const condition = headlessJob.match(/^    if: (.+)$/m);
  assert.ok(condition, "headless-startup must have an explicit fail-open condition");
  assert.equal(
    condition[1],
    "${{ !cancelled() && (needs.integration-decision.result != 'success' || needs.integration-decision.outputs.required != 'false') }}",
    "integration must run when decision fails, output is missing, or output is anything except the exact string false"
  );
});

test("path classifier includes integration inputs but not continuity-only docs", () => {
  for (const path of [
    ".config/nvim/init.lua",
    "tests/nvim/lazydev-lazy-loading.lua",
    ".agents/skills/neovim-maintenance/SKILL.md",
    "scripts/ci/neovim-integration-decision.cjs",
    "scripts/test-nvim-headless.sh",
    ".github/workflows/neovim-headless.yml",
    "install.sh",
    "README.md",
  ]) assert.equal(isIntegrationPath(path), true, path);
  assert.equal(isIntegrationPath("AGENT_WORKLOG.md"), false);
  assert.equal(isIntegrationPath("docs/neovim-modernization-backlog.md"), false);
});
