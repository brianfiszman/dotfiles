const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { validateAgentPreflight } = require("../../scripts/ci/validate-agent-preflight.cjs");

const root = path.resolve(__dirname, "../..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");
const normalize = (source) => source.replace(/\s+/g, " ").trim();

const completePreflight = [
  "## Agent preflight (required; CI-enforced)",
  "- Issue/task: issue #91; implement safe CI dependency caches.",
  "- Prior project learning searched: issue #91, PR #124, docs/agent-log, specialist skills, existing tests, and Actions runs.",
  "- Related prior failures and disposition: PR #125 run #674 failed on a double-escaped whitespace regex; fix the regex and retain a newline regression. PR #124 run #668 has unresolved cache-contract and macOS focus failures.",
  "- Existing regression tests reviewed: tests/ci/neovim-cache-contract.test.cjs and tests/nvim/.",
  "- Falsifiable hypothesis: the PR description gate rejects missing project-learning evidence before the PR can pass fast checks.",
  "- Smallest discriminating automated test: node --test tests/ci/agent-process-contract.test.cjs.",
  "- Automated validation plan: exact-head CI must pass the process contract, cache contract, and applicable Linux/macOS integration jobs.",
].join("\n");

test("whitespace normalization collapses wrapped Markdown lines", () => {
  assert.equal(normalize("Before the first repository\n mutation"), "Before the first repository mutation");
});

test("AGENTS.md makes prior project learning a hard gate before every mutation", () => {
  const agents = normalize(read("AGENTS.md"));
  assert.match(agents, /## Mandatory agent preflight gate/);
  assert.match(agents, /regardless of model size, capability, confidence/);
  assert.match(agents, /Search for prior learning about the same symptom/);
  assert.match(agents, /confirmed root causes, reproductions, fixes, rejected hypotheses, failed approaches/);
  assert.match(agents, /Conversation history, model memory, or another assistant's summary never substitutes/);
  assert.match(agents, /falsifiable root-cause hypothesis/);
  assert.match(agents, /two-attempt stop rule/);
  assert.match(agents, /exact-SHA evidence/);
});

test("specialist skills retain the project's diagnostic and verification safeguards", () => {
  const required = [
    [".agents/skills/execution-continuity/SKILL.md", /canonical checkpoint/],
    [".agents/skills/diagnostic-experiments/SKILL.md", /Two attempts per symptom/],
    [".agents/skills/automated-verification/SKILL.md", /execute that test yourself/],
    [".agents/skills/github-actions-validation/SKILL.md", /head_sha/],
    [".agents/skills/neovim-headless-testing/SKILL.md", /real headless process/],
    [".agents/skills/agent-memory-hygiene/SKILL.md", /300 lines maximum/],
  ];

  for (const [relativePath, pattern] of required) {
    assert.ok(fs.existsSync(path.join(root, relativePath)), "missing skill: " + relativePath);
    assert.match(normalize(read(relativePath)), pattern, "required process rule missing from " + relativePath);
  }
});

test("preflight CI rejects omitted learning, placeholders, and unsupported prior-failure claims", () => {
  assert.deepEqual(validateAgentPreflight(completePreflight), []);

  const withoutLearning = completePreflight.replace(
    "- Prior project learning searched: issue #91, PR #124, docs/agent-log, specialist skills, existing tests, and Actions runs.",
    "- Prior project learning searched:"
  );
  assert.ok(validateAgentPreflight(withoutLearning).some((error) => /Prior project learning searched/.test(error)));

  const placeholder = completePreflight.replace(
    "- Related prior failures and disposition: PR #125 run #674 failed on a double-escaped whitespace regex; fix the regex and retain a newline regression. PR #124 run #668 has unresolved cache-contract and macOS focus failures.",
    "- Related prior failures and disposition: TODO"
  );
  assert.ok(validateAgentPreflight(placeholder).some((error) => /placeholder/.test(error)));
});

test("PR template exposes the fields enforced by the preflight validator", () => {
  const template = normalize(read(".github/pull_request_template.md"));
  for (const field of [
    "Issue/task",
    "Prior project learning searched",
    "Related prior failures and disposition",
    "Existing regression tests reviewed",
    "Falsifiable hypothesis",
    "Smallest discriminating automated test",
    "Automated validation plan",
  ]) {
    assert.ok(template.includes("- " + field + ":"), "PR template is missing " + field);
  }
});

test("canonical agent state stays bounded and the worklog pointer remains discoverable", () => {
  const state = read("AGENT_STATE.md");
  const worklog = read("AGENT_WORKLOG.md");
  const lineCount = state.trimEnd().split("\n").length;

  assert.ok(lineCount <= 40, "AGENT_STATE.md must stay at 40 lines or fewer; found " + lineCount);
  assert.match(worklog, /docs\/agent-log\/\d{4}-\d{2}\.md/);
});

test("CI enforces PR preflight before running the process-contract test", () => {
  const workflow = normalize(read(".github/workflows/neovim-headless.yml"));
  assert.match(workflow, /AGENTS\.md/);
  assert.match(workflow, /\.github\/pull_request_template\.md/);
  assert.match(workflow, /name: Enforce mandatory agent preflight evidence in pull requests/);
  assert.match(workflow, /PR_BODY: \$\{\{ github\.event\.pull_request\.body \|\| '' \}\}/);
  assert.match(workflow, /node scripts\/ci\/validate-agent-preflight\.cjs/);
  assert.match(workflow, /node --test tests\/ci\/agent-process-contract\.test\.cjs/);
});
