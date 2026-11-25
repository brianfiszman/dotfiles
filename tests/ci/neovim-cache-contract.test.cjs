"use strict";

const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");

const workflowPath = resolve(__dirname, "../../.github/workflows/neovim-headless.yml");
const restoreScriptPath = resolve(__dirname, "../../scripts/test-nvim-headless.sh");
const treesitterPath = resolve(__dirname, "../../.config/nvim/lua/treesitter.lua");
const lockfilePath = resolve(__dirname, "../../.config/nvim/lazy-lock.json");

const workflow = readFileSync(workflowPath, "utf8");
const restoreScript = readFileSync(restoreScriptPath, "utf8");
const treesitter = readFileSync(treesitterPath, "utf8");
const lockfile = JSON.parse(readFileSync(lockfilePath, "utf8"));

const trustedCacheCondition =
  "$" + "{{ github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.pull_request.head.repo.full_name == github.repository) }}";

function cacheStepBlocks() {
  return workflow.split(/(?=      - name: (?:Restore locked lazy\.nvim plugin checkouts|Restore Mason packages and pinned registry|Restore compiled Tree-sitter parsers))/)
    .filter((block) => block.startsWith("      - name: ") && block.includes("uses: actions/cache@v6"));
}

test("all dependency caches use exact keys and are restricted to trusted push/PR runs", () => {
  assert.equal((workflow.match(/uses: actions\/cache@v6/g) || []).length, 4);
  const blocks = cacheStepBlocks();
  assert.equal(blocks.length, 4);

  for (const block of blocks) {
    assert.ok(block.includes("if: " + trustedCacheCondition), block.split("\n")[0]);
    assert.doesNotMatch(block, /^\s+restore-keys:/m, "stale cache prefixes must not be restored");
    assert.match(block, /key: nvim-/);
  }

  // Schedule and workflow_dispatch events deliberately do not satisfy the
  // cache condition, so they validate clean installation and parser compilation.
  assert.doesNotMatch(trustedCacheCondition, /schedule|workflow_dispatch/);
});

test("Linux plugin cache key includes OS, architecture, Neovim, build toolchain and source inputs", () => {
  const block = cacheStepBlocks().find((entry) =>
    entry.includes("path: " + "$" + "{{ runner.temp }}" + "/nvim-headless-smoke/data/nvim/lazy"));
  assert.ok(block, "Linux lazy.nvim source cache must exist");
  assert.match(block, /nvim-lazy-\$\{\{ runner\.os \}\}-\$\{\{ runner\.arch \}\}/);
  assert.match(block, /nvim-\$\{\{ env\.NEOVIM_VERSION \}\}/);
  assert.match(block, /steps\.toolchain\.outputs\.fingerprint/);
  assert.match(block, /hashFiles\('\.config\/nvim\/lazy-lock\.json'/);
  assert.match(block, /scripts\/test-nvim-headless\.sh/);
});

test("macOS plugin cache is isolated by OS/architecture/toolchain and lockfile", () => {
  const block = cacheStepBlocks().find((entry) =>
    entry.includes("path: " + "$" + "{{ runner.temp }}" + "/nvim-headless-macos/data/nvim/lazy"));
  assert.ok(block, "macOS lazy.nvim source cache must exist");
  assert.match(block, /nvim-lazy-\$\{\{ runner\.os \}\}-\$\{\{ runner\.arch \}\}/);
  assert.match(block, /steps\.toolchain\.outputs\.fingerprint/);
  assert.match(block, /hashFiles\('\.config\/nvim\/lazy-lock\.json'/);
});

test("Mason cache is keyed by the exact registry revision and includes the isolated Mason root", () => {
  const block = cacheStepBlocks().find((entry) => entry.includes("Restore Mason packages and pinned registry"));
  assert.ok(block, "dedicated Mason cache must exist");
  assert.match(block, /data\/nvim\/mason(?:\s|$)/);
  assert.match(block, /nvim-mason-\$\{\{ runner\.os \}\}-\$\{\{ runner\.arch \}\}/);
  assert.match(block, /steps\.mason-registry\.outputs\.revision/);
  assert.match(block, /steps\.toolchain\.outputs\.fingerprint/);
  assert.match(block, /hashFiles\('\.config\/nvim\/lazy-lock\.json'/);
  assert.doesNotMatch(block, /^\s+restore-keys:/m);
});

test("Mason registry fingerprint resolves the exact remote HEAD before restoring its cache", () => {
  const registryIndex = workflow.indexOf("- name: Fingerprint Mason registry revision");
  const cacheIndex = workflow.indexOf("- name: Restore Mason packages and pinned registry");
  assert.ok(registryIndex >= 0 && cacheIndex > registryIndex,
    "Mason registry must be fingerprinted before cache restore");
  const fingerprintStep = workflow.slice(registryIndex, cacheIndex);
  assert.match(fingerprintStep, /git ls-remote https:\/\/github\.com\/mason-org\/mason-registry\.git HEAD/);
  assert.match(fingerprintStep, /\^\[0-9a-f\]\{40\}\$/);
  assert.match(fingerprintStep, /echo "revision=\$registry_sha" >> "\$GITHUB_OUTPUT"/);
});

test("Linux parser cache fingerprint is computed after supplemental APT dependencies are installed", () => {
  const aptIndex = workflow.indexOf("- name: Install only missing Neovim build prerequisites");
  const fingerprintIndex = workflow.indexOf("- name: Fingerprint installed Linux plugin-build toolchain");
  const cacheIndex = workflow.indexOf("Restore compiled Tree-sitter parsers");
  assert.ok(aptIndex >= 0 && fingerprintIndex > aptIndex && cacheIndex > fingerprintIndex,
    "native dependency versions must be fingerprinted after APT and before cache restore");
  const fingerprintStep = workflow.slice(fingerprintIndex, cacheIndex);
  for (const packageName of ["libreadline-dev", "liblua5.1-0-dev", "lua5.1", "python3-venv", "ripgrep", "zsh"]) {
    assert.ok(fingerprintStep.includes(packageName), "toolchain fingerprint omits " + packageName);
  }
});

test("compiled parser cache is keyed by platform, architecture, toolchain, Neovim, CLI and parser inputs", () => {
  const block = cacheStepBlocks().find((entry) => entry.includes("Restore compiled Tree-sitter parsers"));
  assert.ok(block, "compiled parser cache must exist");
  assert.match(block, /data\/nvim\/site\/parser/);
  assert.match(block, /nvim-treesitter-parsers-\$\{\{ runner\.os \}\}-\$\{\{ runner\.arch \}\}/);
  assert.match(block, /env\.NEOVIM_VERSION/);
  assert.match(block, /cli-v0\.27\.2/);
  assert.match(block, /steps\.toolchain\.outputs\.fingerprint/);
  assert.match(block, /lua\/treesitter\.lua/);
  assert.match(block, /treesitter-current-api\.lua/);
});

test("plugin cache hits force all lazy.nvim build hooks and fail on task errors", () => {
  assert.match(workflow, /DOTFILES_PLUGIN_CACHE_HIT: \$\{\{ steps\.lazy-plugin-cache\.outputs\.cache-hit \}\}/);
  assert.match(restoreScript, /DOTFILES_PLUGIN_CACHE_HIT:-false/);
  assert.match(restoreScript, /\+Lazy! build all/);
  assert.match(restoreScript, /task:has_errors\(\)/);
  for (const plugin of ["LuaSnip", "avante.nvim", "nvim-treesitter"]) {
    assert.ok(restoreScript.includes("'" + plugin + "'"), "missing explicit build-hook assertion for " + plugin);
  }
});

test("Tree-sitter provisioning installs only missing parsers and updates only after a plugin revision change", () => {
  assert.match(treesitter, /ensure_installed = \{ \{ "tree-sitter-cli", version = "v0\.27\.2" \} \}/);
  assert.match(treesitter, /local function provision_missing_parsers\(\)/);
  assert.match(treesitter, /local update_existing = pending_parser_update/);
  assert.match(treesitter, /setup_parsers\(update_existing\)/);
  assert.match(treesitter, /pending_parser_update = false/);
  assert.match(treesitter, /if update_existing then[\s\S]*treesitter\.update\(parser_languages/);
  assert.match(treesitter, /updated\.from == updated\.to/);
  assert.match(treesitter, /pending_parser_update/);
  assert.match(treesitter, /DOTFILES_SKIP_TREESITTER_PROVISIONING == "1"/);
  assert.match(treesitter, /tree-sitter 0\.27\.2/);
  assert.equal(lockfile["nvim-treesitter"]?.branch, "main");
});

test("the fresh DAP adapter installation regression remains wired into the cold suite", () => {
  assert.match(restoreScript, /dap-mason-command-trigger\.lua/);
  assert.match(restoreScript, /dap-lazy-loading\.lua/);
  assert.match(restoreScript, /dap-command-trigger\.lua/);
  assert.match(restoreScript, /dap-neotest-trigger\.lua/);
});
