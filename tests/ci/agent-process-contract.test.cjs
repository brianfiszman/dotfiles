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
  "- Issue/task: issue #91; make prior-project-learning review mandatory before agent changes.",
  "- Prior project learning searched: issue #91, PRs #124 and #125, AGENT_STATE.md, docs/agent-log, docs/incidents, docs/decisions, specialist skills, existing tests, and Actions runs.",
  "- Related prior failures and disposition: PR #125 run #674 failed because the normalizer double-escaped whitespace; the fix is in this commit with a newline regression. PR #124 run #675 has unresolved cache-contract and macOS focus failures.",
  "- Existing regression tests reviewed: tests/ci/agent-process-contract.test.cjs and tests/ci/neovim-cache-contract.test.cjs.",
  "- Falsifiable hypothesis: the PR-body preflight validator rejects missing project-learning evidence before fast checks pass.",
  "- Smallest discriminating automated test: node --test tests/ci/agent-process-contract.test.cjs.",
  "- Automated validation plan: exact-head PR CI must pass the validator, process contracts, fast checks, and Linux/macOS integration jobs.",
].join("\n");

test("semantic text normalization collapses Markdown wrapping and repeated whitespace", () => {
  assert.equal(normalize("Before the first repository\n mutation"), "Before the first repository mutation");
  assert.equal(normalize("one\t\n  two"), "one two");
});

test("AGENTS.md makes prior project learning a hard gate before every mutation", () => {
  const agents = normalize(read("AGENTS.md"));
  assert.match(agents, /## Mandatory agent preflight gate/);
  assert.match(agents, /At the start of every repository work session or new conversation/);
  assert.match(agents, /regardless of task size or prior chat context/);
  assert.ok(agents.includes("canonical `master` `AGENT_STATE.md`"), "session recovery must name the canonical master checkpoint");
  assert.match(agents, /regardless of model size, capability, confidence/);
  assert.match(agents, /Search for prior learning about the same symptom/);
  assert.match(agents, /confirmed root causes, reproductions, fixes, rejected hypotheses, failed approaches/);
  assert.match(agents, /Conversation history, model memory, or another assistant's summary never substitutes/);
  assert.match(agents, /falsifiable root-cause hypothesis/);
  assert.match(agents, /two-attempt stop rule/);
  assert.match(agents, /exact-SHA evidence/);
  assert.ok(agents.includes("it cannot prove that an agent genuinely read a source"));
  assert.ok(agents.includes("a workflow that runs without a required-status rule is advisory"));
});

test("AGENTS.md requires proactive context compaction without losing task-critical state", () => {
  const agents = normalize(read("AGENTS.md"));
  for (const required of [
    "## Context compaction before saturation",
    "Compact it proactively",
    "Objective and priority",
    "Live artifact identity",
    "Decisions and authority",
    "Evidence",
    "Uncertainty and history that changes the next action",
    "one concrete, smallest discriminating step",
    "Never compress away the user's priority",
    "Do not preserve chain-of-thought or a transcript",
    "A conversation summary is only a navigation aid",
    "two-attempt diagnostic stop rules",
  ]) {
    assert.ok(agents.includes(required), "context-compaction contract is missing: " + required);
  }
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

test("AGENTS routes live Neovim session inspection to the read-only RPC reference", () => {
  const agents = normalize(read("AGENTS.md"));
  assert.ok(
    agents.includes(".agents/skills/neovim-maintenance/references/live-runtime-rpc.md"),
    "AGENTS.md must route running-session diagnosis to the maintained RPC reference"
  );
});

test("Neovim maintenance exposes a bounded, read-only live RPC reference", () => {
  const maintenance = read(".agents/skills/neovim-maintenance/SKILL.md");
  const rpc = read(".agents/skills/neovim-maintenance/references/live-runtime-rpc.md");

  assert.match(maintenance, /references\/live-runtime-rpc\.md/);
  assert.match(maintenance, /^description: .*configure.*debug.*plugins.*LSP.*DAP.*test adapters.*live-session RPC inspection\.$/m);
  assert.ok(
    maintenance.trimEnd().split("\n").length <= 300,
    "Neovim maintenance skill must stay within the documented 300-line budget"
  );
  assert.match(rpc, /Default to read-only inspection/);
  assert.match(rpc, /refusing to guess a Neovim instance/);
  assert.match(rpc, /Never expose an RPC listener on/);
  assert.match(normalize(rpc), /is not a reliable proof that the user's terminal generated the expected input/);
});

test("preflight CI rejects omitted learning, vague searches, placeholders, and unsupported failure claims", () => {
  assert.deepEqual(validateAgentPreflight(completePreflight), []);

  const withoutLearning = completePreflight.replace(
    "- Prior project learning searched: issue #91, PRs #124 and #125, AGENT_STATE.md, docs/agent-log, docs/incidents, docs/decisions, specialist skills, existing tests, and Actions runs.",
    "- Prior project learning searched:"
  );
  assert.ok(validateAgentPreflight(withoutLearning).some((error) => /Prior project learning searched/.test(error)));

  const vagueSearch = completePreflight.replace(
    "- Prior project learning searched: issue #91, PRs #124 and #125, AGENT_STATE.md, docs/agent-log, docs/incidents, docs/decisions, specialist skills, existing tests, and Actions runs.",
    "- Prior project learning searched: issue #91 and PR #125."
  );
  assert.ok(validateAgentPreflight(vagueSearch).some((error) => /at least two project source categories/.test(error)));

  const placeholder = completePreflight.replace(
    "- Related prior failures and disposition: PR #125 run #674 failed because the normalizer double-escaped whitespace; the fix is in this commit with a newline regression. PR #124 run #675 has unresolved cache-contract and macOS focus failures.",
    "- Related prior failures and disposition: TODO"
  );
  assert.ok(validateAgentPreflight(placeholder).some((error) => /placeholder/.test(error)));

  const unsupportedFailure = completePreflight.replace(
    "- Related prior failures and disposition: PR #125 run #674 failed because the normalizer double-escaped whitespace; the fix is in this commit with a newline regression. PR #124 run #675 has unresolved cache-contract and macOS focus failures.",
    "- Related prior failures and disposition: there were problems, now fixed."
  );
  assert.ok(validateAgentPreflight(unsupportedFailure).some((error) => /must link an issue\/PR\/run and state their disposition/.test(error)));
});

test("preflight validator ignores required fields placed outside the Agent preflight section", () => {
  const fieldOutsideSection = completePreflight.replace(
    "- Falsifiable hypothesis: the PR-body preflight validator rejects missing project-learning evidence before fast checks pass.",
    "## Validation" + "\n" + "- Falsifiable hypothesis: the PR-body preflight validator rejects missing project-learning evidence before fast checks pass."
  );
  assert.ok(
    validateAgentPreflight(fieldOutsideSection).some((error) => /missing required field: Falsifiable hypothesis/.test(error))
  );
});

test("preflight validator rejects a missing section and unreviewed regression coverage", () => {
  const withoutSection = completePreflight.replace(
    "## Agent preflight (required; CI-enforced)",
    "## Validation"
  );
  assert.ok(validateAgentPreflight(withoutSection).some((error) => /missing section/.test(error)));

  const placeholderTests = completePreflight.replace(
    "- Existing regression tests reviewed: tests/ci/agent-process-contract.test.cjs and tests/ci/neovim-cache-contract.test.cjs.",
    "- Existing regression tests reviewed: none"
  );
  assert.ok(validateAgentPreflight(placeholderTests).some((error) => /placeholder/.test(error)));

  const unsupportedTests = completePreflight.replace(
    "- Existing regression tests reviewed: tests/ci/agent-process-contract.test.cjs and tests/ci/neovim-cache-contract.test.cjs.",
    "- Existing regression tests reviewed: reviewed but no paths supplied"
  );
  assert.ok(validateAgentPreflight(unsupportedTests).some((error) => /existing regression tests must name reviewed test paths/.test(error)));
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

test("dedicated agent workflow validates PR preflight and keeps GUI integration out of process-only CI", () => {
  const workflow = normalize(read(".github/workflows/agent-preflight.yml"));
  assert.ok(workflow.includes("pull_request: types: [opened, synchronize, reopened, edited]"));
  assert.match(workflow, /AGENTS\.md/);
  assert.match(workflow, /\.github\/pull_request_template\.md/);
  assert.match(workflow, /name: Enforce mandatory agent preflight evidence in pull requests/);
  assert.match(workflow, /PR_BODY:.*pull_request\.body/);
  assert.match(workflow, /node scripts\/ci\/validate-agent-preflight\.cjs/);
  assert.match(workflow, /node --test tests\/ci\/agent-process-contract\.test\.cjs/);
  assert.match(workflow, /node --test tests\/ci\/neovim-integration-gate\.test\.cjs/);
  assert.match(workflow, /name: Neovim integration gate/);
  assert.match(workflow, /actions: read/);
  assert.match(workflow, /workflow_id: NEOVIM_WORKFLOW_ID/);
  assert.match(workflow, /neovim-integration-gate\.cjs/);
  assert.ok(
    workflow.indexOf("node scripts/ci/validate-agent-preflight.cjs")
      < workflow.indexOf("node --test tests/ci/agent-process-contract.test.cjs"),
    "CI must reject an incomplete preflight before running process-contract tests"
  );

  const neovimWorkflow = normalize(read(".github/workflows/neovim-headless.yml"));
  assert.doesNotMatch(neovimWorkflow, /node scripts\/ci\/validate-agent-preflight\.cjs/);
  assert.doesNotMatch(neovimWorkflow, /node --test tests\/ci\/agent-process-contract\.test\.cjs/);
  assert.doesNotMatch(neovimWorkflow, /name: Neovim integration gate/);
  assert.doesNotMatch(neovimWorkflow, /integration-gate:/);
});
