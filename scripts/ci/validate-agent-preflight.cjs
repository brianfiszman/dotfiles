const REQUIRED_FIELDS = [
  "Issue/task",
  "Prior project learning searched",
  "Related prior failures and disposition",
  "Existing regression tests reviewed",
  "Falsifiable hypothesis",
  "Smallest discriminating automated test",
  "Automated validation plan",
];

const SOURCE_CATEGORIES = [
  /issue|pull request|\bpr\b/i,
  /worklog|incident|decision/i,
  /specialist skill|\.agents\/skills/i,
  /regression test|tests\//i,
  /workflow|actions|ci run/i,
];

function validateAgentPreflight(body) {
  const errors = [];
  if (typeof body !== "string" || body.trim() === "") {
    return ["PR description is empty; complete the required Agent preflight section."];
  }

  const lines = body.split(/\r?\n/);
  if (!lines.some((line) => /^##\s+Agent preflight \(required; CI-enforced\)\s*$/i.test(line.trim()))) {
    errors.push("missing section: ## Agent preflight (required; CI-enforced)");
  }

  const values = {};
  for (const field of REQUIRED_FIELDS) {
    const prefix = "- " + field + ":";
    const line = lines.find((candidate) => candidate.trimStart().startsWith(prefix));
    if (!line) {
      errors.push("missing required field: " + field);
      continue;
    }

    const value = line.trimStart().slice(prefix.length).trim();
    if (
      value === "" ||
      /^\[(?:required|fill in|describe|add|link)[^\]]*\]$/i.test(value) ||
      /^(?:todo|tbd|to be completed|n\/a|none)$/i.test(value)
    ) {
      errors.push("required field is empty or still a placeholder: " + field);
      continue;
    }
    values[field] = value;
  }

  const priorSearch = values["Prior project learning searched"];
  if (priorSearch) {
    const categoriesFound = SOURCE_CATEGORIES.filter((pattern) => pattern.test(priorSearch)).length;
    if (categoriesFound < 2) {
      errors.push("prior-learning search must identify at least two project source categories (for example issues/PRs, worklogs/incidents, skills, tests, or Actions runs)");
    }
  }

  const priorFailures = values["Related prior failures and disposition"];
  if (
    priorFailures &&
    !/none found after searching/i.test(priorFailures) &&
    !(/#\d+|https:\/\/github\.com\//i.test(priorFailures) && /failed|failure|rejected|reused|unresolved|pending|passed|superseded|cancelled|in progress|not yet/i.test(priorFailures))
  ) {
    errors.push("related prior failures must link an issue/PR/run and state their disposition, or explicitly say none were found after searching");
  }

  const regressionTests = values["Existing regression tests reviewed"];
  if (regressionTests && !/tests\/|none found after searching/i.test(regressionTests)) {
    errors.push("existing regression tests must name reviewed test paths or explicitly say none were found after searching");
  }

  return errors;
}

if (require.main === module) {
  const errors = validateAgentPreflight(process.env.PR_BODY || "");
  if (errors.length > 0) {
    process.stderr.write("Agent preflight gate failed:\n");
    for (const error of errors) process.stderr.write("- " + error + "\n");
    process.exitCode = 1;
  } else {
    process.stdout.write("Agent preflight gate passed: prior learning, diagnosis, and automated validation are recorded.\n");
  }
}

module.exports = { REQUIRED_FIELDS, validateAgentPreflight };
