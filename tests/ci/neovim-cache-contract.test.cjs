"use strict";

const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");

const workflowPath = resolve(__dirname, "../../.github/workflows/neovim-headless.yml");
const restoreScriptPath = resolve(__dirname, "../../scripts/test-nvim-headless.sh");
const treesitterPath = resolve(__dirname, "../../.config/nvim/lua/treesitter.lua");
const treesitterProvisioningPath = resolve(__dirname, "../nvim/treesitter-provisioning.lua");
const treesitterCurrentApiPath = resolve(__dirname, "../nvim/treesitter-current-api.lua");
const lspConfigPath = resolve(__dirname, "../../.config/nvim/lua/lsp/config.lua");
const focusTestPath = resolve(__dirname, "../nvim/checktime-focus.lua");
const lockfilePath = resolve(__dirname, "../../.config/nvim/lazy-lock.json");
const macosFocusScriptPath = resolve(__dirname, "../../scripts/test-macos-terminal-focus.sh");
const luasnipIdleLifetimePath = resolve(__dirname, "../nvim/luasnip-idle-lifetime.lua");
const pluginConfigPath = resolve(__dirname, "../../.config/nvim/lua/plugins.lua");

const workflow = readFileSync(workflowPath, "utf8");
const restoreScript = readFileSync(restoreScriptPath, "utf8");
const treesitter = readFileSync(treesitterPath, "utf8");
const treesitterProvisioning = readFileSync(treesitterProvisioningPath, "utf8");
const treesitterCurrentApi = readFileSync(treesitterCurrentApiPath, "utf8");
const lspConfig = readFileSync(lspConfigPath, "utf8");
const focusTest = readFileSync(focusTestPath, "utf8");
const lockfile = JSON.parse(readFileSync(lockfilePath, "utf8"));
const macosFocusScript = readFileSync(macosFocusScriptPath, "utf8");
const luasnipIdleLifetime = readFileSync(luasnipIdleLifetimePath, "utf8");
const pluginConfig = readFileSync(pluginConfigPath, "utf8");

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

test("Mason cache is keyed by the exact release and includes package data plus refresh state", () => {
  const block = cacheStepBlocks().find((entry) => entry.includes("Restore Mason packages and pinned registry"));
  assert.ok(block, "dedicated Mason cache must exist");
  assert.match(block, /data\/nvim\/mason(?:\s|$)/);
  assert.match(block, /cache\/nvim\/mason-registry-update/);
  assert.match(block, /nvim-mason-\$\{\{ runner\.os \}\}-\$\{\{ runner\.arch \}\}/);
  assert.match(block, /steps\.mason-registry\.outputs\.version/);
  assert.match(block, /steps\.toolchain\.outputs\.fingerprint/);
  assert.match(block, /hashFiles\('\.config\/nvim\/lazy-lock\.json'/);
  assert.doesNotMatch(block, /^\s+restore-keys:/m);
});

test("Mason release fingerprint is pinned in the real Neovim setup before cache restore", () => {
  const registryIndex = workflow.indexOf("- name: Resolve and pin Mason registry release");
  const cacheIndex = workflow.indexOf("- name: Restore Mason packages and pinned registry");
  assert.ok(registryIndex >= 0 && cacheIndex > registryIndex,
    "Mason registry release must be resolved before cache restore");
  const fingerprintStep = workflow.slice(registryIndex, cacheIndex);
  assert.match(fingerprintStep, /api\.github\.com\/repos\/mason-org\/mason-registry\/releases\/latest/);
  assert.match(fingerprintStep, /tag_name/);
  assert.match(fingerprintStep, /DOTFILES_MASON_REGISTRY_VERSION=\$registry_version/);
  assert.match(fingerprintStep, /version=\$registry_version/);
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

test("plugin restore runs configured build hooks once, serially, and fails on task errors", () => {
  assert.match(workflow, /DOTFILES_PLUGIN_CACHE_HIT: \$\{\{ steps\.lazy-plugin-cache\.outputs\.cache-hit \}\}/);
  assert.match(restoreScript, /DOTFILES_PLUGIN_CACHE_HIT:-false/);
  assert.match(restoreScript, /task:has_errors\(\)/);
  assert.match(restoreScript, /luasnip-jsregexp\.so/);
  assert.match(restoreScript, /avante_\*\.so/);
  assert.match(restoreScript, /dotfiles_treesitter_build_hook_ran/);
  assert.match(restoreScript, /plugin\.build ~= nil/);
  assert.ok(restoreScript.includes('Plugin cache hit; validating restored build artifacts without rerunning unchanged hooks.'));
  assert.ok(restoreScript.includes('restore_checks+=("$verify_build_hooks")'));
  assert.ok(restoreScript.includes('restore_checks+=("$verify_build_hooks" "$verify_treesitter_build_hook")'));
  assert.ok(!restoreScript.includes("+Lazy! build all"),
    "cache hits must validate restored build artifacts without forcing a redundant rebuild");
  for (const plugin of ["LuaSnip", "avante.nvim", "nvim-treesitter"]) {
    assert.ok(restoreScript.includes("'" + plugin + "'"), "missing explicit build-hook assertion for " + plugin);
  }
});

test("Tree-sitter provisioning installs only missing parsers and updates only after a plugin revision change", () => {
  assert.match(treesitter, /ensure_installed = \{ \{ "tree-sitter-cli", version = "v0\.27\.2" \} \}/);
  assert.match(treesitter, /mason_registry_version = vim\.env\.DOTFILES_MASON_REGISTRY_VERSION/);
  assert.match(treesitter, /registries = \{ mason_registry \}/);
  assert.match(treesitter, /local function provision_missing_parsers\(\)/);
  assert.match(treesitter, /local update_existing = pending_parser_update/);
  assert.match(treesitter, /setup_parsers\(update_existing\)/);
  assert.match(treesitter, /pending_parser_update = false/);
  assert.match(treesitter, /if update_existing then[\s\S]*treesitter\.update\(parser_languages/);
  assert.match(treesitter, /updated\.from == updated\.to/);
  assert.match(treesitter, /pending_parser_update/);
  assert.match(treesitter, /DOTFILES_SKIP_TREESITTER_PROVISIONING == "1"/);
  assert.match(treesitter, /tree-sitter 0\.27\.2/);
  assert.match(treesitterProvisioning, /config\.setup\(\{ install_dir = isolated_install_dir \}\)/);
  assert.match(treesitterProvisioning, /treesitter\.get_installed\("parsers"\)/);
  assert.doesNotMatch(treesitterProvisioning, /treesitter\.get_installed = mocked_get_installed/);
  assert.equal(lockfile["nvim-treesitter"]?.branch, "main");
  assert.ok(treesitter.includes("vim.schedule(function()") && treesitter.includes("configure_buffer(bufnr)"),
    "Treesitter indentation must be applied after native ftplugin scripts finish");
  assert.ok(treesitterCurrentApi.includes("vim.wait(2000"),
    "current API integration must wait for deferred Treesitter indentation");

});

test("focus PTY skips only Mason LSP package installation while retaining native server activation", () => {
  assert.match(restoreScript, /env DOTFILES_SKIP_MASON_LSP_INSTALL=1 python3/);
  assert.match(lspConfig, /DOTFILES_SKIP_MASON_LSP_INSTALL == "1"/);
  assert.match(lspConfig, /ensure_installed = skip_mason_lsp_install and \{\} or M\.mason_servers/);
  assert.match(lspConfig, /vim\.lsp\.enable\(M\.servers\)/);
  assert.match(focusTest, /focus PTY skips unrelated Mason package installation/);
  assert.match(focusTest, /focus PTY still explicitly enables configured native LSP servers/);
});

test("the scrolling PTY disables the Neovim message pager before startup", () => {
  assert.match(restoreScript, /nvim_args=\(--cmd "set nomore"\)/);
  assert.match(readFileSync(resolve(__dirname, "../nvim/scrolling.lua"), "utf8"),
    /scrolling PTY cannot block on the message pager/);
});

test("the fresh DAP adapter installation regression remains wired into the cold suite", () => {
  assert.match(restoreScript, /dap-mason-command-trigger\.lua/);
  assert.match(restoreScript, /dap-lazy-loading\.lua/);
  assert.match(restoreScript, /dap-command-trigger\.lua/);
  assert.match(restoreScript, /dap-neotest-trigger\.lua/);
});

test("Treesitter indentation regression waits for deferred FileType configuration", () => {
  const indentationFixture = readFileSync(resolve(__dirname, "../nvim/indented-substitute.lua"), "utf8");
  assert.match(indentationFixture, /vim\.wait\(2000, function\(\)[\s\S]*?indentexpr == expected_indentexpr/,
    "the real FileType fixture must allow the scheduled Treesitter callback to execute before assertions");
});

test("headless LuaSnip fixture queues real typed input without blocking Insert mode", () => {
  assert.ok(luasnipIdleLifetime.includes("vim.api.nvim_input(keys)"),
    "use non-blocking user input so the event loop can run deferred Insert-mode assertions");
  assert.doesNotMatch(luasnipIdleLifetime, /nvim_feedkeys\([^\n]*["'][^"']*x/,
    "blocking feedkeys execution must not hold the event loop while Insert mode remains active");
});

test("macOS Terminal focus launch uses bounded native Launch Services transitions without RPC", () => {
  const focusStep = workflow.slice(
    workflow.indexOf("- name: Verify Terminal.app window activation reports native Neovim focus events"),
    workflow.indexOf("- name: Run isolated real provider provisioning and fresh-start checks")
  );
  assert.match(focusStep, /timeout-minutes: 5/);
  assert.ok(macosFocusScript.includes('open -a Terminal "$command_file"'));
  assert.ok(macosFocusScript.includes("open -a Finder"));
  assert.ok(macosFocusScript.includes("open -a Terminal"));
  assert.match(macosFocusScript, /wait_for_launcher/);
  assert.match(macosFocusScript, /wait_for_ready/);
  assert.match(macosFocusScript, /wait_for_terminal_tty/);
  assert.ok(macosFocusScript.includes("FocusLost"));
  assert.ok(macosFocusScript.includes("FocusGained"));
  const nvimLaunch = macosFocusScript.slice(
    macosFocusScript.indexOf("exec $q_nvim"),
    macosFocusScript.indexOf("\nEOF", macosFocusScript.indexOf("exec $q_nvim"))
  );
  assert.ok(nvimLaunch.indexOf("-u $q_init") < nvimLaunch.indexOf("-c 'lua"),
    "native focus autocmds must be registered after init.lua, matching the post-config command phase");
  assert.ok(macosFocusScript.includes('open -a Finder "$test_root"'),
    "Finder must open a real window before the focus transition");
  assert.ok(macosFocusScript.includes('activate_and_wait_for_frontmost_application "com.apple.finder" "Finder"'),
    "the test must explicitly activate Finder and verify it became frontmost before asserting FocusLost");
  assert.match(macosFocusScript, /NSWorkspace\.shared\.frontmostApplication/,
    "the native activation helper must verify the actual frontmost application");
  assert.ok(macosFocusScript.includes("CGWindowListCopyWindowInfo"),
    "identify the exact Terminal.app window created for the Neovim TTY");
  assert.ok(macosFocusScript.includes("mouseEventSource: source"),
    "construct a real window-specific mouse event");
  assert.ok(macosFocusScript.includes("mouseDown.post(tap: .cghidEventTap)"),
    "post the click through the native WindowServer event stream");
  const terminalLaunchLines = macosFocusScript.split("\n")
    .filter((line) => line.trim() === 'open -a Terminal "$command_file"');
  assert.equal(terminalLaunchLines.length, 1,
    "open Terminal only for the initial TTY launch, not as an app-wide focus substitute");
  assert.equal((macosFocusScript.match(/activate_neovim_terminal_window "\\$terminal_windows_before"/g) || []).length, 2,
    "both focus-gain assertions must target the same exact Neovim Terminal.app window");
  assert.ok(macosFocusScript.includes('swift "$terminal_window_focus_script" activate'),
    "activate only the newly-created Neovim Terminal.app window");
  assert.doesNotMatch(macosFocusScript, /activate_and_wait_for_frontmost_application "com\.apple\.Terminal"/,
    "do not activate every Terminal.app window and steal focus from the Neovim TTY session");
  assert.doesNotMatch(macosFocusScript, /remote_expr|nvim-rpc|--remote-expr|--server/);
  assert.doesNotMatch(macosFocusScript, /run_terminal_applescript|NSAppleScript/,
    "focus activation must not block on Terminal AppleEvents");
  assert.match(treesitterCurrentApi, /syntax ~= ""/);
});
