"use strict";

const { mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");
const { join, resolve } = require("node:path");
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
const luasnipIdleLifetimePath = resolve(__dirname, "../nvim/luasnip-idle-lifetime.lua");
const pluginConfigPath = resolve(__dirname, "../../.config/nvim/lua/plugins.lua");
const luasnipBuildPath = resolve(__dirname, "../../.config/nvim/lua/snippets/luasnip_build.lua");
const luasnipNativeReplacementTestPath = resolve(__dirname, "../nvim/luasnip-native-library-replacement.lua");

const workflow = readFileSync(workflowPath, "utf8");
const restoreScript = readFileSync(restoreScriptPath, "utf8");
const treesitter = readFileSync(treesitterPath, "utf8");
const treesitterProvisioning = readFileSync(treesitterProvisioningPath, "utf8");
const treesitterCurrentApi = readFileSync(treesitterCurrentApiPath, "utf8");
const lspConfig = readFileSync(lspConfigPath, "utf8");
const focusTest = readFileSync(focusTestPath, "utf8");
const lockfile = JSON.parse(readFileSync(lockfilePath, "utf8"));
const luasnipIdleLifetime = readFileSync(luasnipIdleLifetimePath, "utf8");
const pluginConfig = readFileSync(pluginConfigPath, "utf8");
const luasnipBuild = readFileSync(luasnipBuildPath, "utf8");

const trustedCacheCondition =
  "$" + "{{ github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.pull_request.head.repo.full_name == github.repository) }}";

function cacheStepBlocks() {
  return workflow.split(/(?=      - name: (?:Restore locked lazy\.nvim plugin checkouts|Restore Mason packages and pinned registry|Restore compiled Tree-sitter parsers))/)
    .filter((block) => block.startsWith("      - name: ") && block.includes("uses: actions/cache@v6"));
}

test("all dependency caches use exact keys and are restricted to trusted push/PR runs", () => {
  assert.equal((workflow.match(/uses: actions\/cache@v6/g) || []).length, 3);
  const blocks = cacheStepBlocks();
  assert.equal(blocks.length, 3);

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
  for (const packageName of ["fd-find", "openbox", "procps", "wmctrl", "x11-utils", "xauth", "xterm", "xfonts-base", "xdotool", "xvfb", "libreadline-dev", "liblua5.1-0-dev", "lua5.1", "python3-venv", "ripgrep", "zsh"]) {
    assert.ok(fingerprintStep.includes(packageName), "toolchain fingerprint omits " + packageName);
  }
  assert.ok(fingerprintStep.includes("gnutimeout="), "toolchain fingerprint omits the GNU timeout version");
});

test("Tree-sitter runtime cache preserves parser binaries, query links, and revision metadata", () => {
  const block = cacheStepBlocks().find((entry) => entry.includes("Restore compiled Tree-sitter parsers"));
  assert.ok(block, "compiled parser cache must exist");
  for (const path of ["data/nvim/site/parser", "data/nvim/site/queries", "data/nvim/site/parser-info"]) {
    assert.ok(block.includes(path), "Tree-sitter cache omits required install_dir state: " + path);
  }
  assert.match(block, /nvim-treesitter-runtime-v2-\$\{\{ runner\.os \}\}-\$\{\{ runner\.arch \}\}/);
  assert.match(block, /env\.NEOVIM_VERSION/);
  assert.match(block, /cli-v0\.27\.2/);
  assert.match(block, /steps\.toolchain\.outputs\.fingerprint/);
  assert.match(block, /lua\/treesitter\.lua/);
  assert.match(block, /treesitter-current-api\.lua/);
});

test("Linux headless runner selects and reports GNU timeout on Ubuntu", () => {
  const gnuTimeout = restoreScript.indexOf("command -v gnutimeout");
  const genericTimeout = restoreScript.indexOf("command -v timeout");
  assert.ok(gnuTimeout >= 0 && genericTimeout > gnuTimeout,
    "prefer gnutimeout and retain generic timeout only as a fallback");
  assert.ok(restoreScript.includes("Timeout supervisor: %s (%s)"),
    "record the resolved supervisor and version in CI logs");
  assert.ok(restoreScript.includes('"$TIMEOUT_BIN" --signal=TERM --kill-after=30s "$time_limit"'),
    "run bounded Neovim phases through the selected supervisor");
  assert.doesNotMatch(restoreScript, /^\s*timeout --signal=/m,
    "do not invoke the ambiguous generic timeout directly");
  assert.ok(workflow.includes("sha256sum gnutimeout find grep tee tar unzip"),
    "Ubuntu runner preflight must require GNU timeout");
  assert.ok(workflow.includes("gnutimeout --version 2>&1 | sed -n '1p'"),
    "Ubuntu runner preflight must log the GNU timeout version");
});

test("plugin restore runs configured build hooks on cold and cached paths, serially, and fails on task errors", () => {
  assert.ok(workflow.includes("DOTFILES_PLUGIN_CACHE_HIT: ${{ steps.lazy-plugin-cache.outputs.cache-hit }}"));
  assert.ok(restoreScript.includes("DOTFILES_PLUGIN_CACHE_HIT:-false"));
  assert.ok(restoreScript.includes("task:has_errors()"));
  assert.ok(restoreScript.includes("luasnip-jsregexp.so"));
  assert.ok(restoreScript.includes("avante_*.so"));
  assert.ok(restoreScript.includes("dotfiles_treesitter_build_hook_ran"));
  assert.ok(restoreScript.includes("plugin.build ~= nil"));
  assert.ok(restoreScript.includes('Plugin cache hit; locked restore is followed by a separate serialized forced build pass.'));
  assert.ok(restoreScript.includes('restore_checks+=("$verify_build_hooks")'));
  assert.ok(restoreScript.includes('restore_checks+=("$verify_build_hooks" "$verify_treesitter_build_hook")'));
  assert.ok(restoreScript.includes('local verify_build_tasks='));
  assert.ok(restoreScript.includes('local -a restore_checks=("+Lazy! restore" "$verify_build_tasks")'));
  assert.ok(restoreScript.includes('run_nvim "plugin-restore"'));
  assert.ok(restoreScript.includes('run_nvim "plugin-cache-build"'));
  assert.ok(restoreScript.includes('"+Lazy! build all" "$verify_build_tasks" "$verify_build_hooks" "$verify_treesitter_build_hook" "+qa!"'));
  assert.ok(restoreScript.includes("DOTFILES_LAZY_CONCURRENCY=1"));
  assert.ok(restoreScript.indexOf('run_nvim "plugin-restore"') < restoreScript.indexOf('run_nvim "plugin-cache-build"'),
    "cached build hooks must run in a fresh process after locked restore");
  assert.equal(restoreScript.split("+Lazy! build all").length - 1, 1,
    "force-run all configured build hooks exactly once on cache hits");
  assert.ok(!restoreScript.includes("without rerunning unchanged hooks"));
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
  assert.ok(treesitterCurrentApi.includes("vim.wait(2000, function()"));
  assert.ok(treesitterCurrentApi.includes("vim.b.current_syntax ~= nil"),
    "current API integration must wait for deferred legacy Vim syntax setup");
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

test("LuaSnip build hook atomically replaces native libraries instead of overwriting loaded files", () => {
  assert.match(pluginConfig, /build = require\\(["']snippets\\.luasnip_build["']\\)\\.build/);
  assert.match(luasnipBuild, /make", "jsregexp/);
  assert.match(luasnipBuild, /vim\\.uv\\.fs_copyfile/);
  assert.match(luasnipBuild, /vim\\.uv\\.fs_rename/);
  assert.doesNotMatch(luasnipBuild, /install_jsregexp/);
});

test("LuaSnip native-library replacement preserves the loaded inode finalizer", () => {
  const testRoot = mkdtempSync(join(tmpdir(), "dotfiles-luasnip-native-"));
  const marker = join(testRoot, "finalizer.txt");
  try {
    const result = spawnSync(
      process.env.NVIM_BIN || "nvim",
      ["--headless", "-u", "NONE", "-l", luasnipNativeReplacementTestPath],
      {
        cwd: resolve(__dirname, "../.."),
        env: {
          ...process.env,
          DOTFILES_LUASNIP_REPLACEMENT_TEST_DIR: testRoot,
        },
        encoding: "utf8",
        timeout: 30000,
      }
    );
    assert.equal(result.error, undefined, result.error && result.error.message);
    assert.equal(result.status, 0,
      "Neovim native-library replacement test failed\\nstdout:\\n" + result.stdout
        + "\\nstderr:\\n" + result.stderr);
    assert.equal(readFileSync(marker, "utf8"), "original",
      "the already-loaded library's original finalizer must run after atomic replacement");
  } finally {
    rmSync(testRoot, { recursive: true, force: true });
  }
});

test("headless LuaSnip fixture queues real typed input without blocking Insert mode", () => {
  assert.ok(luasnipIdleLifetime.includes("vim.api.nvim_input(keys)"),
    "use non-blocking user input so the event loop can run deferred Insert-mode assertions");
  assert.doesNotMatch(luasnipIdleLifetime, /nvim_feedkeys\([^\n]*["'][^"']*x/,
    "blocking feedkeys execution must not hold the event loop while Insert mode remains active");
});

test("runtime integration stays Linux-only and retains native PTY focus and Python provider coverage", () => {
  assert.match(workflow, /Verify native Linux xterm focus reaches Neovim through a real PTY/);
  assert.match(workflow, /run: bash \.\/scripts\/test-linux-terminal-focus\.sh/);
  assert.match(workflow, /Run isolated real Python provider provisioning and fresh-start checks/);
  assert.match(workflow, /run: bash \.\/scripts\/test-python-provider\.sh/);
  assert.doesNotMatch(workflow, /macos-15|macOS plugin restore|Terminal\.app|test-macos-terminal-focus|python-provider-macos/);
  assert.doesNotMatch(restoreScript, /test-macos-terminal-focus|python-provider-macos/);
});

test("a cache-hit build is wrapped by GDB to capture the exhausted forced-build crash", () => {
  assert.match(workflow, /Install GDB for a cache-hit build backtrace/);
  assert.match(workflow, /steps\.lazy-plugin-cache\.outputs\.cache-hit == 'true'/);
  assert.match(workflow, /gdb --batch --quiet --return-child-result/);
  assert.match(workflow, /thread apply all bt full/);
  assert.match(workflow, /\+Lazy! build all/);
});
