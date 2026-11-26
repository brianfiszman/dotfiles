"use strict";
const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  determineIntegrationRequirement,
  isAgentProcessOnlyPath,
  isIntegrationPath,
  parseIntegrationBaseline,
} = require("../../scripts/ci/neovim-integration-decision.cjs");

const BASE_SHA = "a".repeat(40);
const PREVIOUS_HEAD_SHA = "b".repeat(40);
const CURRENT_HEAD_SHA = "c".repeat(40);
const TESTED_SHA = "d".repeat(40);

function makeContext(overrides = {}) {
  return {
    eventName: "pull_request",
    runId: 999,
    repo: { owner: "brianfiszman", repo: "dotfiles" },
    payload: { pull_request: {
      number: 92,
      base: { ref: "master", sha: BASE_SHA },
      head: { ref: "feat/ci-feedback-91", sha: CURRENT_HEAD_SHA },
    } },
    ...overrides,
  };
}

function baselineDisplayTitle({ baseSha = BASE_SHA, prHeadSha = PREVIOUS_HEAD_SHA, testedSha = TESTED_SHA } = {}) {
  return "PR #92 [nvim-ci-baseline base=" + baseSha +
    " pr_head=" + prHeadSha + " tested=" + testedSha + "]";
}

function baseline(overrides = {}) {
  return {
    id: 123,
    head_sha: PREVIOUS_HEAD_SHA,
    head_branch: "feat/ci-feedback-91",
    conclusion: "success",
    display_title: baselineDisplayTitle(),
    created_at: "2026-11-14T18:00:00Z",
    pull_requests: [{ number: 92 }],
    ...overrides,
  };
}

function fakeGithub(options = {}) {
  const calls = { runs: [], jobs: [], comparisons: [] };
  const runs = options.runs === undefined ? [baseline({
    display_title: options.displayTitle === undefined
      ? baselineDisplayTitle({
        baseSha: options.baselineBaseSha || BASE_SHA,
        prHeadSha: options.baselinePrHeadSha || PREVIOUS_HEAD_SHA,
      })
      : options.displayTitle,
  })] : options.runs;
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

test("baseline metadata parser requires three complete SHA values", () => {
  assert.deepEqual(parseIntegrationBaseline(baselineDisplayTitle()), {
    baseSha: BASE_SHA,
    prHeadSha: PREVIOUS_HEAD_SHA,
    testedSha: TESTED_SHA,
  });
  assert.equal(parseIntegrationBaseline("no baseline metadata"), null);
  assert.equal(parseIntegrationBaseline("PR #92 [nvim-ci-baseline base=abc pr_head=def tested=ghi]"), null);
});

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
    context: makeContext({ payload: { pull_request: { number: 92, head: { sha: CURRENT_HEAD_SHA, ref: "feat/ci-feedback-91" } } } }),
    github: fakeGithub(),
  });
  assert.equal(result.required, true);
  assert.match(result.reason, /payload is incomplete/);
});

test("no successful same-PR integration baseline requires runtime integration for runtime changes", async () => {
  const result = await determineIntegrationRequirement({
    context: makeContext(),
    github: fakeGithub({
      runs: [],
      comparison: {
        status: "ahead",
        total_commits: 1,
        files: [{ filename: ".config/nvim/init.lua" }],
      },
    }),
  });
  assert.equal(result.required, true);
  assert.match(result.reason, /no previous successful full integration/);
  assert.match(result.reason, /process-only exception does not apply/);
});

test("no baseline skips runtime integration only for an entirely allowlisted agent-process diff", async () => {
  const changedFiles = [
    "AGENTS.md",
    ".github/pull_request_template.md",
    ".github/workflows/agent-preflight.yml",
    "AGENT_STATE.md",
    "AGENT_WORKLOG.md",
    "docs/agent-log/2026-11.md",
    "scripts/ci/neovim-integration-decision.cjs",
    "tests/ci/neovim-integration-decision.test.cjs",
    "scripts/ci/validate-agent-preflight.cjs",
    "tests/ci/agent-process-contract.test.cjs",
  ];
  const github = fakeGithub({
    runs: [],
    comparison: {
      status: "ahead",
      total_commits: 2,
      files: changedFiles.map((filename) => ({ filename })),
    },
  });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, false);
  assert.match(result.reason, /explicitly allowlisted agent-process/);
  assert.equal(github.calls.comparisons.length, 1);
  assert.equal(github.calls.comparisons[0].args.base, BASE_SHA);
  assert.equal(github.calls.comparisons[0].args.head, CURRENT_HEAD_SHA);
});

test("a mixed agent-process and runtime diff still requires full integration without a baseline", async () => {
  const github = fakeGithub({
    runs: [],
    comparison: {
      status: "ahead",
      total_commits: 2,
      files: [
        { filename: "AGENTS.md" },
        { filename: "tests/nvim/lazydev-lazy-loading.lua" },
      ],
    },
  });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, true);
  assert.match(result.reason, /process-only exception does not apply/);
  assert.match(result.reason, /tests\/nvim/);
});

test("an incomplete base-to-head comparison never activates the process-only exception", async () => {
  for (const comparison of [
    { status: "behind", total_commits: 1, files: [{ filename: "AGENTS.md" }] },
    { status: "ahead", total_commits: 1, files: [] },
    { status: "ahead", total_commits: 1, files: [{ previous_filename: "AGENTS.md" }] },
    { status: "ahead", total_commits: 250, files: [{ filename: "AGENTS.md" }] },
  ]) {
    const result = await determineIntegrationRequirement({
      context: makeContext(),
      github: fakeGithub({ runs: [], comparison }),
    });
    assert.equal(result.required, true);
    assert.match(result.reason, /comparison may be incomplete/);
  }
});

test("different PRs and missing PR associations cannot provide a reusable baseline", async () => {
  for (const run of [
    baseline({ pull_requests: [{ number: 90 }] }),
    baseline({ pull_requests: [] }),
    baseline({ pull_requests: undefined }),
  ]) {
    const github = fakeGithub({
      runs: [run],
      comparison: { status: "ahead", total_commits: 1, files: [{ filename: ".config/nvim/init.lua" }] },
    });
    const result = await determineIntegrationRequirement({ context: makeContext(), github });
    assert.equal(result.required, true);
    assert.equal(github.calls.jobs.length, 0);
    assert.equal(github.calls.comparisons.length, 1,
      "without a reusable baseline the complete base-to-head diff must be examined");
  }
});

test("skipped, failed and cancelled integration runs cannot provide a baseline", async () => {
  for (const conclusion of ["skipped", "failure", "cancelled"]) {
    const github = fakeGithub({
      jobsByRun: { 123: [{ name: "Fresh install and headless startup", conclusion }] },
      comparison: { status: "ahead", total_commits: 1, files: [{ filename: ".config/nvim/init.lua" }] },
    });
    const result = await determineIntegrationRequirement({ context: makeContext(), github });
    assert.equal(result.required, true);
    assert.equal(github.calls.comparisons.length, 1,
      "a non-successful integration job is not a baseline; compare the complete PR delta");
  }
});

test("documentation-only delta skips integration after a successful baseline on the current base SHA", async () => {
  const github = fakeGithub({
    comparison: { status: "ahead", total_commits: 1, files: [{ filename: "AGENT_WORKLOG.md" }] },
  });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, false);
  assert.match(result.reason, /only non-integration files changed/);
});

test("a master/base SHA change invalidates the previous successful integration baseline", async () => {
  const github = fakeGithub({
    baselineBaseSha: "e".repeat(40),
    comparison: { status: "ahead", total_commits: 1, files: [{ filename: ".config/nvim/init.lua" }] },
  });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, true);
  assert.match(result.reason, /current PR base SHA/);
  assert.match(result.reason, /process-only exception does not apply/);
  assert.equal(github.calls.comparisons.length, 1);
});

test("baseline metadata must match the historical PR head", async () => {
  const github = fakeGithub({ baselinePrHeadSha: "e".repeat(40) });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, true);
  assert.match(result.reason, /PR head metadata does not match/);
  assert.equal(github.calls.comparisons.length, 0);
});

test("missing or incomplete workflow run name metadata fails open", async () => {
  for (const displayTitle of ["no marker", null]) {
    const github = fakeGithub({ displayTitle });
    const result = await determineIntegrationRequirement({ context: makeContext(), github });
    assert.equal(result.required, true);
    assert.match(result.reason, /did not record complete PR base metadata/);
    assert.equal(github.calls.comparisons.length, 0);
  }
});

test("configuration and test changes require integration", async () => {
  for (const filename of [
    ".config/nvim/lua/lsp/native.lua",
    "tests/nvim/lazydev-lazy-loading.lua",
    "tests/ci/neovim-cache-contract.test.cjs",
    "scripts/ci/neovim-bootstrap.cjs",
    "scripts/test-macos-terminal-focus.sh",
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
  const github = fakeGithub({
    runs: [
      baseline({ id: 999, head_sha: CURRENT_HEAD_SHA }),
      baseline({ id: 124, conclusion: "failure" }),
      baseline({ id: 125, conclusion: "cancelled" }),
      baseline({ id: 126, pull_requests: [{ number: 90 }] }),
    ],
    comparison: { status: "ahead", total_commits: 1, files: [{ filename: ".config/nvim/init.lua" }] },
  });
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
    "$" + "{{ !cancelled() && (needs.integration-decision.result != 'success' || needs.integration-decision.outputs.required != 'false') }}",
    "integration must run when decision fails, output is missing, or output is anything except the exact string false"
  );
});

test("workflow run name carries the immutable PR baseline and keeps the heavy job check name stable", () => {
  const workflowPath = resolve(__dirname, "../../.github/workflows/neovim-headless.yml");
  const workflow = readFileSync(workflowPath, "utf8");
  assert.match(workflow, /^run-name:.*nvim-ci-baseline.*base=.*pr_head=.*tested=/m);
  assert.ok(workflow.includes("run-name: ${{ github.workflow }} [nvim-ci-baseline"));

  assert.doesNotMatch(workflow, /github\\.event\\.pull_request\\.title/);
  assert.match(workflow, /name: Fresh install and headless startup/);
  assert.match(workflow, /- "scripts\/ci\/\*\*"/);
  assert.match(workflow, /- "tests\/ci\/\*\*"/);
});

test("a Python provider macOS script-only delta requires full integration", async () => {
  const github = fakeGithub({
    comparison: {
      status: "ahead",
      total_commits: 1,
      files: [{ filename: "scripts/test-python-provider-macos.sh" }],
    },
  });
  const result = await determineIntegrationRequirement({ context: makeContext(), github });
  assert.equal(result.required, true);
  assert.match(result.reason, /integration-relevant files changed/);
});

test("path classifier keeps runtime paths mandatory and isolates only explicit agent-process files", () => {
  for (const path of [
    ".config/nvim/init.lua",
    "tests/nvim/lazydev-lazy-loading.lua",
    ".agents/skills/neovim-maintenance/SKILL.md",
    "scripts/ci/neovim-bootstrap.cjs",
    "tests/ci/neovim-cache-contract.test.cjs",
    "scripts/test-nvim-headless.sh",
    "scripts/test-python-provider-macos.sh",
    "scripts/test-macos-terminal-focus.sh",
    ".github/workflows/neovim-headless.yml",
    "install.sh",
    "README.md",
  ]) assert.equal(isIntegrationPath(path), true, path);

  for (const path of [
    "AGENTS.md",
    ".github/pull_request_template.md",
    ".github/workflows/agent-preflight.yml",
    "AGENT_STATE.md",
    "AGENT_WORKLOG.md",
    "docs/agent-log/2026-11.md",
    "scripts/ci/neovim-integration-decision.cjs",
    "scripts/ci/neovim-integration-decision.test.cjs",
    "scripts/ci/validate-agent-preflight.cjs",
    "tests/ci/agent-process-contract.test.cjs",
  ]) {
    assert.equal(isAgentProcessOnlyPath(path), true, path);
    assert.equal(isIntegrationPath(path), false, path);
  }

  assert.equal(isAgentProcessOnlyPath("tests/ci/neovim-cache-contract.test.cjs"), false);
  assert.equal(isIntegrationPath("docs/neovim-modernization-backlog.md"), false);
});
