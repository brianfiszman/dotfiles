const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const root = path.resolve(__dirname, "../..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");

test("AGENTS.md defines a mandatory preflight before repository mutations", () => {
  const agents = read("AGENTS.md");
  assert.match(agents, /## Mandatory agent preflight gate/);
  assert.match(agents, /Before the first repository mutation/);
  assert.match(agents, /Read this file/);
  assert.match(agents, /one falsifiable root cause/);
  assert.match(agents, /exact-SHA evidence/);
  assert.match(agents, /stop the affected mutation/);
});

test("the specialist skills retain the required diagnostic and verification safeguards", () => {
  const required = [
    [".agents/skills/execution-continuity/SKILL.md", /canonical checkpoint/],
    [".agents/skills/diagnostic-experiments/SKILL.md", /Two attempts per symptom/],
    [".agents/skills/automated-verification/SKILL.md", /execute that test yourself/],
    [".agents/skills/github-actions-validation/SKILL.md", /head_sha/],
    [".agents/skills/neovim-headless-testing/SKILL.md", /real headless process/],
    [".agents/skills/agent-memory-hygiene/SKILL.md", /300 lines maximum/],
  ];

  for (const [relativePath, pattern] of required) {
    assert.ok(fs.existsSync(path.join(root, relativePath)), `missing skill: ${relativePath}`);
    assert.match(read(relativePath), pattern, `required process rule missing from ${relativePath}`);
  }
});

test("canonical agent state and worklog pointer remain bounded and discoverable", () => {
  const state = read("AGENT_STATE.md");
  const worklog = read("AGENT_WORKLOG.md");
  const lineCount = state.trimEnd().split("\n").length;

  assert.ok(lineCount <= 40, `AGENT_STATE.md must stay at 40 lines or fewer; found ${lineCount}`);
  assert.match(worklog, /docs\/agent-log\/\d{4}-\d{2}\.md/);
});

test("CI runs this contract and triggers fast checks when the agent policy changes", () => {
  const workflow = read(".github/workflows/neovim-headless.yml");
  assert.match(workflow, /AGENTS\.md/);
  assert.match(workflow, /AGENT_STATE\.md/);
  assert.match(workflow, /AGENT_WORKLOG\.md/);
  assert.match(workflow, /docs\/agent-log\/\*\*/);
  assert.match(workflow, /node --test tests\/ci\/agent-process-contract\.test\.cjs/);
});
