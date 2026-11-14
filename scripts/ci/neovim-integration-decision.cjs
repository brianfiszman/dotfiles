"use strict";
const INTEGRATION_WORKFLOW_ID = "neovim-headless.yml";
const INTEGRATION_JOB_NAME = "Fresh install and headless startup";

function required(reason) {
  return { required: true, reason };
}

function isIntegrationPath(path) {
  return path.startsWith(".config/nvim/") ||
    path.startsWith("tests/nvim/") ||
    path.startsWith(".agents/skills/") ||
    path.startsWith("scripts/ci/") ||
    path === "install.sh" ||
    path === "scripts/test-nvim-headless.sh" ||
    path === ".github/workflows/neovim-headless.yml" ||
    path === "README.md";
}

async function determineIntegrationRequirement({ context, github }) {
  if (context.eventName !== "pull_request") {
    return required(context.eventName + " always runs the cold integration path");
  }
  const pr = context.payload && context.payload.pull_request;
  if (!pr || !pr.head || !pr.head.sha || !pr.head.ref || !Number.isInteger(pr.number)) {
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
      const integration = jobs.find((job) => job.name === INTEGRATION_JOB_NAME);
      if (integration && integration.conclusion === "success") {
        baseline = run;
        break;
      }
    }
    if (!baseline) return required("no previous successful full integration exists for this PR");

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
        baseline.head_sha.slice(0, 7),
    };
  } catch (error) {
    return required("integration-gating API failed; fail open to the full suite: " + error.message);
  }
}

module.exports = { determineIntegrationRequirement, isIntegrationPath };
