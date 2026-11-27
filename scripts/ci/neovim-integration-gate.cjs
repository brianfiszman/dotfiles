"use strict";

const { parseIntegrationBaseline } = require("./neovim-integration-decision.cjs");

const NEOVIM_WORKFLOW_ID = "neovim-headless.yml";
const DECISION_JOB_NAME = "Decide whether full integration is required";
const FAST_CHECKS_JOB_NAME = "Fast shell and lockfile checks";
const LINUX_JOB_PREFIX = "Fresh install and headless startup (Neovim ";

function normalizeSha(value) {
  return typeof value === "string" ? value.toLowerCase() : "";
}

function matchesPullRequestRun(run, identity) {
  if (!run || run.event !== "pull_request" ||
      normalizeSha(run.head_sha) !== normalizeSha(identity.headSha)) return false;
  if (!Number.isInteger(identity.prNumber) || identity.prNumber < 1 ||
      !/^[0-9a-f]{40}$/i.test(identity.headSha || "") ||
      !/^[0-9a-f]{40}$/i.test(identity.baseSha || "")) return false;

  const associated = Array.isArray(run.pull_requests) &&
    run.pull_requests.some((pullRequest) =>
      pullRequest && pullRequest.number === identity.prNumber
    );
  if (!associated) return false;

  const metadata = parseIntegrationBaseline(run.display_title);
  return Boolean(metadata) &&
    metadata.baseSha === normalizeSha(identity.baseSha) &&
    metadata.prHeadSha === normalizeSha(identity.headSha);
}

function selectLatestMatchingRun(runs, identity) {
  if (!Array.isArray(runs)) return null;
  const matchingRuns = runs.filter((run) => matchesPullRequestRun(run, identity));
  matchingRuns.sort((left, right) => {
    const leftCreated = Date.parse(left.created_at || "") || 0;
    const rightCreated = Date.parse(right.created_at || "") || 0;
    if (leftCreated !== rightCreated) return rightCreated - leftCreated;
    return (Number(right.run_number || right.id) || 0) -
      (Number(left.run_number || left.id) || 0);
  });
  return matchingRuns[0] || null;
}

function evaluateNeovimRun(run, jobs, identity) {
  const fail = (reason) => ({ passed: false, mode: "failed", reason });
  if (!matchesPullRequestRun(run, identity)) {
    return fail("Neovim workflow run does not match the exact PR number, head SHA, and base SHA.");
  }
  if (run.status !== "completed") return fail("Neovim workflow run is not completed: " + String(run.status));
  if (run.conclusion !== "success") return fail("Neovim workflow run concluded " + String(run.conclusion) + ".");
  if (!Array.isArray(jobs)) return fail("Neovim workflow job-list response is missing or malformed.");

  const findSingleJob = (name) => {
    const matching = jobs.filter((job) => job && job.name === name);
    return matching.length === 1 ? matching[0] : null;
  };
  const decision = findSingleJob(DECISION_JOB_NAME);
  const fastChecks = findSingleJob(FAST_CHECKS_JOB_NAME);
  const linux = jobs.filter((job) =>
    job && typeof job.name === "string" && job.name.startsWith(LINUX_JOB_PREFIX)
  );

  if (!decision) return fail("Expected exactly one integration-decision job.");
  if (!fastChecks) return fail("Expected exactly one fast-checks job.");
  if (linux.length === 0) return fail("No matrix-expanded Linux headless integration job was found.");
  if (decision.conclusion !== "success") {
    return fail("Integration decision did not succeed: " + String(decision.conclusion));
  }
  if (fastChecks.conclusion !== "success") {
    return fail("Fast shell and lockfile checks did not succeed: " + String(fastChecks.conclusion));
  }

  const runtimeJobs = linux;
  const runtimeResults = runtimeJobs.map((job) => job.conclusion);
  if (runtimeResults.every((result) => result === "success")) {
    return { passed: true, mode: "full-integration",
      reason: "Integration decision and fast checks passed; every Linux integration matrix cell passed." };
  }
  if (runtimeResults.every((result) => result === "skipped")) {
    return { passed: true, mode: "process-only-skip",
      reason: "Integration decision and fast checks passed; every Linux runtime matrix cell was skipped by the shared explicit process-only condition." };
  }
  return fail("Runtime integration results must be all success or all skipped; observed: " +
    runtimeJobs.map((job) => job.name + "=" + String(job.conclusion)).join(", "));
}

module.exports = {
  NEOVIM_WORKFLOW_ID,
  evaluateNeovimRun,
  matchesPullRequestRun,
  selectLatestMatchingRun,
};
