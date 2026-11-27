"use strict";
const INTEGRATION_WORKFLOW_ID = "neovim-headless.yml";
const INTEGRATION_JOB_NAME = "Fresh install and headless startup";
const BASELINE_MARKER = /\[nvim-ci-baseline base=([0-9a-f]{40}) pr_head=([0-9a-f]{40}) tested=([0-9a-f]{40})\]/i;

function required(reason) {
  return { required: true, reason };
}

const AGENT_PROCESS_ONLY_FILES = new Set([
  "AGENTS.md",
  ".github/pull_request_template.md",
  ".github/workflows/agent-preflight.yml",
  "AGENT_STATE.md",
  "AGENT_WORKLOG.md",
  "scripts/ci/neovim-integration-decision.cjs",
  "tests/ci/neovim-integration-decision.test.cjs",
  "scripts/ci/neovim-integration-gate.cjs",
  "tests/ci/neovim-integration-gate.test.cjs",
  "scripts/ci/validate-agent-preflight.cjs",
  "tests/ci/agent-process-contract.test.cjs",
]);

function isAgentProcessOnlyPath(path) {
  return typeof path === "string" &&
    (AGENT_PROCESS_ONLY_FILES.has(path) || path.startsWith("docs/agent-log/"));
}

function isIntegrationPath(path) {
  if (isAgentProcessOnlyPath(path)) return false;
  return path.startsWith(".config/nvim/") ||
    path.startsWith("tests/nvim/") ||
    path.startsWith("tests/ci/") ||
    path.startsWith(".agents/skills/") ||
    path.startsWith("scripts/ci/") ||
    path === "install.sh" ||
    path === "scripts/test-nvim-headless.sh" ||
    path === "scripts/test-linux-terminal-focus.sh" ||
    path === "scripts/run_terminal_focus_probe.py" ||
    path === "scripts/test-python-provider.sh" ||
    path === ".github/workflows/neovim-headless.yml" ||
    path === "README.md";
}

function parseIntegrationBaseline(displayTitle) {
  if (typeof displayTitle !== "string") return null;
  const match = displayTitle.match(BASELINE_MARKER);
  if (!match) return null;
  return {
    baseSha: match[1].toLowerCase(),
    prHeadSha: match[2].toLowerCase(),
    testedSha: match[3].toLowerCase(),
  };
}

async function determineIntegrationRequirement({ context, github }) {
  if (context.eventName !== "pull_request") {
    return required(context.eventName + " always runs the cold integration path");
  }
  const pr = context.payload && context.payload.pull_request;
  if (!pr || !pr.head || !/^[0-9a-f]{40}$/i.test(pr.head.sha || "") ||
      !pr.head.ref || !Number.isInteger(pr.number) ||
      !pr.base || !/^[0-9a-f]{40}$/i.test(pr.base.sha || "")) {
    return required("PR payload is incomplete; fail open to full integration");
  }
  const repository = context.repo || {};
  const owner = repository.owner;
  const repoName = repository.repo;
  if (!owner || !repoName || !github || !github.rest || !github.rest.actions) {
    return required("GitHub API context is incomplete; fail open to full integration");
  }

  try {
    const response = await github.rest.actions.listWorkflowRuns({
      owner, repo: repoName, workflow_id: INTEGRATION_WORKFLOW_ID,
      branch: pr.head.ref, event: "pull_request", status: "completed", per_page: 100,
    });
    const workflowRuns = response.data && response.data.workflow_runs;
    if (!Array.isArray(workflowRuns)) {
      return required("workflow-runs API response was incomplete; fail open to full integration");
    }

    const candidates = workflowRuns
      .filter((run) => {
        if (!run || run.id === context.runId ||
            typeof run.head_sha !== "string" || run.head_sha === pr.head.sha ||
            run.conclusion !== "success" || run.head_branch !== pr.head.ref) return false;
        // Require an explicit PR association; branch-name fallback can select
        // another PR's run when two topic branches share the same name.
        return Array.isArray(run.pull_requests) &&
          run.pull_requests.some((associatedPr) => associatedPr.number === pr.number);
      })
      .sort((a, b) => Date.parse(b.created_at || 0) - Date.parse(a.created_at || 0));

    let baseline = null;
    for (const run of candidates.slice(0, 25)) {
      const jobsResponse = await github.rest.actions.listJobsForWorkflowRun({
        owner, repo: repoName, run_id: run.id, filter: "latest", per_page: 100,
      });
      const jobs = jobsResponse.data && jobsResponse.data.jobs;
      if (!Array.isArray(jobs)) {
        return required("baseline job-list API response was incomplete; fail open to full integration");
      }
      // Matrix job names include resolved axis values, e.g. "(Neovim v0.12.6)".
      // A reusable baseline requires every matching matrix cell to have passed.
      const integrationJobs = jobs.filter((job) =>
        job && typeof job.name === "string" &&
        (job.name === INTEGRATION_JOB_NAME || job.name.startsWith(INTEGRATION_JOB_NAME + " ("))
      );
      if (integrationJobs.length === 0 ||
          integrationJobs.some((job) => job.conclusion !== "success")) continue;

      // The workflow run's resolved run-name is exposed as display_title by the
      // Actions API. Unlike job summaries, it is present in listWorkflowRuns.
      const metadata = parseIntegrationBaseline(run.display_title);
      if (!metadata) {
        return required("baseline workflow run did not record complete PR base metadata; fail open to full integration");
      }
      if (metadata.prHeadSha !== run.head_sha.toLowerCase()) {
        return required("baseline PR head metadata does not match its workflow run; fail open to full integration");
      }

      // A successful integration is reusable only for the exact base snapshot
      // it tested. A later master update invalidates the baseline until a new
      // full integration has passed on that base.
      if (metadata.baseSha === pr.base.sha.toLowerCase()) {
        baseline = run;
        break;
      }
    }
    if (!baseline) {
      // For an unbaselined PR, only a complete base-to-head diff containing
      // exclusively agent-process files may skip Neovim runtime integration.
      // Any unknown/runtime path or incomplete comparison fails open.
      const comparisonResponse = await github.request(
        "GET /repos/{owner}/{repo}/compare/{base}...{head}",
        { owner, repo: repoName, base: pr.base.sha, head: pr.head.sha, per_page: 100 }
      );
      const comparison = comparisonResponse.data;
      if (!comparison || comparison.status !== "ahead" ||
          !Array.isArray(comparison.files) || comparison.files.length === 0 ||
          comparison.files.length >= 300 || !Number.isInteger(comparison.total_commits) ||
          comparison.total_commits <= 0 || comparison.total_commits >= 250 ||
          !comparison.files.every((file) => file && typeof file.filename === "string")) {
        return required("no previous successful full integration exists for the current PR base SHA and the base-to-head comparison may be incomplete");
      }

      const changedPaths = comparison.files.flatMap((file) =>
        [file.filename, file.previous_filename].filter((path) => typeof path === "string")
      );
      const nonProcessPaths = changedPaths.filter((path) => !isAgentProcessOnlyPath(path));
      if (nonProcessPaths.length === 0) {
        return {
          required: false,
          reason: "only explicitly allowlisted agent-process policy, workflow, template, state, log, validator, gate verifier, and contract-test paths changed; the dedicated agent-preflight workflow validates them",
        };
      }
      return required(
        "no previous successful full integration exists for the current PR base SHA; process-only exception does not apply to: " +
        nonProcessPaths.join(", ")
      );
    }

    const compareResponse = await github.request(
      "GET /repos/{owner}/{repo}/compare/{base}...{head}",
      { owner, repo: repoName, base: baseline.head_sha, head: pr.head.sha, per_page: 100 }
    );
    const comparison = compareResponse.data;
    if (!comparison || comparison.status !== "ahead" ||
        !Array.isArray(comparison.files) || comparison.files.length === 0 ||
        comparison.files.length >= 300 || !Number.isInteger(comparison.total_commits) ||
        comparison.total_commits <= 0 || comparison.total_commits >= 250) {
      return required("history diverged or the changed-file comparison may be incomplete");
    }

    const changedPaths = comparison.files.flatMap((file) =>
      [file.filename, file.previous_filename].filter((path) => typeof path === "string")
    );
    const relevantPaths = changedPaths.filter(isIntegrationPath);
    if (relevantPaths.length > 0) {
      return required("integration-relevant files changed since " +
        baseline.head_sha.slice(0, 7) + ": " + relevantPaths.join(", "));
    }
    return {
      required: false,
      reason: "only non-integration files changed since successful integration " +
        baseline.head_sha.slice(0, 7) + " on the current PR base",
    };
  } catch (error) {
    return required("integration-gating API failed; fail open to the full suite: " + error.message);
  }
}

module.exports = { determineIntegrationRequirement, isAgentProcessOnlyPath, isIntegrationPath, parseIntegrationBaseline };
