"use strict";

const assert = require("node:assert/strict");
const {
  accessSync,
  chmodSync,
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
  constants,
} = require("node:fs");
const { spawnSync } = require("node:child_process");
const { delimiter, isAbsolute, join, resolve, sep } = require("node:path");
const { tmpdir } = require("node:os");
const test = require("node:test");

const REPO_ROOT = resolve(__dirname, "../..");
const SOURCE_CONFIG = join(REPO_ROOT, ".config/nvim");
const SOURCE_INIT = join(SOURCE_CONFIG, "init.lua");
const NVIM_BIN = resolveExecutable(process.env.NVIM_BIN || "nvim");
const REAL_GIT_BIN = resolveExecutable("git");
const PROCESS_TIMEOUT_MS = 180_000;

function resolveExecutable(command) {
  const candidates = isAbsolute(command) || command.includes(sep)
    ? [resolve(command)]
    : (process.env.PATH || "").split(delimiter).filter(Boolean).map((directory) => join(directory, command));

  for (const candidate of candidates) {
    try {
      accessSync(candidate, constants.X_OK);
      return candidate;
    } catch {
      // Continue searching PATH.
    }
  }

  throw new Error("Required executable not found: " + command);
}

function createWorkspace(root, name) {
  const base = join(root, name);
  const home = join(base, "home");
  const config = join(base, "xdg-config");
  const data = join(base, "xdg-data");
  const state = join(base, "xdg-state");
  const cache = join(base, "xdg-cache");
  const configPath = join(config, "nvim");

  for (const directory of [home, config, data, state, cache]) {
    mkdirSync(directory, { recursive: true });
  }
  cpSync(SOURCE_CONFIG, configPath, { recursive: true });

  return { base, home, config, configPath, data, state, cache };
}

function isolatedEnvironment(workspace, pathValue, extras = {}) {
  const env = {
    ...process.env,
    HOME: workspace.home,
    XDG_CONFIG_HOME: workspace.config,
    XDG_DATA_HOME: workspace.data,
    XDG_STATE_HOME: workspace.state,
    XDG_CACHE_HOME: workspace.cache,
    PATH: pathValue,
    GIT_TERMINAL_PROMPT: "0",
    GIT_CONFIG_NOSYSTEM: "1",
    ...extras,
  };

  for (const name of [
    "NVIM_APPNAME",
    "VIMINIT",
    "EXINIT",
    "MYVIMRC",
    "NVIM_LOG_FILE",
    "NVIM_LISTEN_ADDRESS",
  ]) {
    delete env[name];
  }
  return env;
}

function runNvim(workspace, pathValue, commands = [], extras = {}) {
  const args = ["--headless", "-u", join(workspace.configPath, "init.lua")];
  for (const command of commands) {
    args.push("-c", command);
  }
  args.push("-c", "qa!");

  const result = spawnSync(NVIM_BIN, args, {
    cwd: REPO_ROOT,
    env: isolatedEnvironment(workspace, pathValue, extras),
    encoding: "utf8",
    timeout: PROCESS_TIMEOUT_MS,
    maxBuffer: 4 * 1024 * 1024,
  });

  return {
    ...result,
    output: (result.stdout || "") + (result.stderr || ""),
    args,
  };
}

function createGitWrapper(directory, countFile, failClone = false) {
  mkdirSync(directory, { recursive: true });
  const script = [
    "#!/bin/sh",
    "set -eu",
    'if [ "$#" -gt 0 ] && [ "$1" = "clone" ]; then',
    '  target_lazy=0',
    '  for argument do',
    '    if [ "$argument" = "https://github.com/folke/lazy.nvim.git" ]; then target_lazy=1; fi',
    '  done',
    '  if [ "$target_lazy" = "1" ]; then',
    '    printf "clone\\n" >> "$GIT_CALL_LOG"',
    "    if [ \"$GIT_WRAPPER_FAIL_CLONE\" = \"1\" ]; then",
    '      destination=""',
    '      for argument do destination="$argument"; done',
    '      mkdir -p "$destination/lua/lazy"',
    '      printf "partial checkout\\n" > "$destination/.partial-clone"',
    "    fi",
    "  fi",
    "fi",
    'exec "$REAL_GIT_BIN" "$@"',
    "",
  ].join("\n");

  const wrapper = join(directory, "git");
  writeFileSync(wrapper, script, { mode: 0o755 });
  chmodSync(wrapper, 0o755);

  return {
    path: directory + delimiter + (process.env.PATH || ""),
    extras: {
      GIT_CALL_LOG: countFile,
      REAL_GIT_BIN,
      GIT_WRAPPER_FAIL_CLONE: failClone ? "1" : "0",
    },
  };
}

function cloneCalls(countFile) {
  if (!existsSync(countFile)) {
    return [];
  }
  return readFileSync(countFile, "utf8").split(/\r?\n/).filter(Boolean);
}

function startupCheckCommand(lazyPath) {
  return [
    "lua assert(vim.fn.filereadable(" + JSON.stringify(join(lazyPath, "lua/lazy/init.lua")) + ") == 1, 'lazy.nvim init file is missing')",
    "assert(vim.fn.index(vim.opt.rtp:get(), " + JSON.stringify(lazyPath) + ") >= 0, 'lazy.nvim path was not prepended to runtimepath')",
    "assert(package.loaded.lazy ~= nil, 'the real lazy.nvim module was not loaded')",
    "print('PASS: real lazy.nvim clone, runtimepath and normal startup')",
  ].join("; ");
}

function assertNoStartupErrors(output, label) {
  const errors = output.split(/\r?\n/).filter((line) =>
    /(Error detected while processing|Error executing lua|E\d{3,4}:)/i.test(line)
      && !line.includes("E216: No such group or event: FileExplorer *")
  );
  assert.deepEqual(errors, [], label + " emitted Neovim errors:\n" + errors.join("\n") + "\nFull output:\n" + output);
}

function assertExited(result, expectedStatus, label) {
  assert.equal(result.error, undefined, label + " process error: " + String(result.error || ""));
  assert.equal(result.signal, null, label + " was terminated by " + String(result.signal));
  assert.equal(result.status, expectedStatus, label + " exit status; args=" + JSON.stringify(result.args) + "\n" + result.output);
}

function assertExpectedBootstrapFailure(result, label) {
  assert.equal(result.error, undefined, label + " process error: " + String(result.error || ""));
  assert.equal(result.signal, null, label + " was terminated by " + String(result.signal));
  assert.ok([0, 1].includes(result.status),
    label + " did not exit normally; status=" + String(result.status) + "\n" + result.output);
  if (result.status === 0) {
    assert.match(result.output, /PASS: failed bootstrap stopped before lazy\.nvim setup/,
      label + " exited successfully without proving that bootstrap stopped before plugin setup:\n" + result.output);
  }
}

function failedBootstrapProbeCommand(lazyPath) {
  return [
    "lua assert(vim.fn.isdirectory(" + JSON.stringify(lazyPath) + ") == 0, 'failed bootstrap left a lazy.nvim directory')",
    "assert(package.loaded.lazy == nil, 'lazy.nvim was loaded after bootstrap failed')",
    "print('PASS: failed bootstrap stopped before lazy.nvim setup')",
  ].join("; ");
}

test("lazy.nvim bootstrap uses the real Neovim process and recovers cleanly", async (t) => {
  const root = mkdtempSync(join(tmpdir(), "dotfiles-lazy-bootstrap-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));

  const emptyPath = join(root, "empty-path");
  mkdirSync(emptyPath);

  await t.test("rejects Neovim versions below 0.12.0 before startup side effects", () => {
    const workspace = createWorkspace(root, "old-version");
    const script = [
      "vim.version = function() return { major = 0, minor = 11, patch = 9 } end",
      "local ok, err = pcall(dofile, " + JSON.stringify(SOURCE_INIT) + ")",
      "assert(not ok, 'Neovim 0.11.9 must be rejected')",
      "assert(tostring(err):find('[dotfiles] Neovim 0.12.0 or newer is required', 1, true), tostring(err))",
      "print('PASS: unsupported Neovim version rejected with the minimum-version message')",
    ].join("; ");
    const result = spawnSync(NVIM_BIN, ["--headless", "-u", "NONE", "-c", "lua " + script, "-c", "qa!"], {
      cwd: REPO_ROOT,
      env: isolatedEnvironment(workspace, emptyPath),
      encoding: "utf8",
      timeout: 30_000,
    });
    const output = (result.stdout || "") + (result.stderr || "");
    assert.equal(result.error, undefined, "version-guard process error: " + String(result.error || "") + "\n" + output);
    assert.equal(result.status, 0, "version-guard assertion failed:\n" + output);
    assert.match(output, /PASS: unsupported Neovim version rejected/);
  });

  await t.test("reports missing Git without attempting a clone", () => {
    const workspace = createWorkspace(root, "missing-git");
    const result = runNvim(
      workspace,
      emptyPath,
      [failedBootstrapProbeCommand(join(workspace.data, "nvim/lazy/lazy.nvim"))]
    );
    assertExpectedBootstrapFailure(result, "missing-Git bootstrap");
    assert.match(result.output, /\[dotfiles\] Git is required to install lazy\.nvim/);
    assert.equal(existsSync(join(workspace.data, "nvim/lazy/lazy.nvim")), false,
      "missing-Git path unexpectedly created a lazy.nvim directory");
    assert.match(result.output, /Install Git and restart Neovim/);
    console.log("PASS: missing Git is rejected before cloning with an actionable message");
  });

  await t.test("captures a real Git clone failure and removes its partial destination", () => {
    const workspace = createWorkspace(root, "failed-clone");
    const callsFile = join(workspace.base, "git-calls.log");
    const wrapper = createGitWrapper(join(workspace.base, "bin"), callsFile, true);
    const lazyPath = join(workspace.data, "nvim/lazy/lazy.nvim");
    const result = runNvim(
      workspace,
      wrapper.path,
      [failedBootstrapProbeCommand(lazyPath)],
      wrapper.extras
    );

    assertExpectedBootstrapFailure(result, "failed-clone bootstrap");
    assert.match(result.output, /\[dotfiles\] Could not bootstrap lazy\.nvim/);
    assert.match(result.output, /Check your internet connection and GitHub access, then restart Neovim/);
    assert.match(result.output, /destination path .* already exists and is not an empty directory/i,
      "Git stderr was not included in the actionable bootstrap error:\n" + result.output);
    assert.deepEqual(cloneCalls(callsFile), ["clone"], "expected exactly one real Git clone attempt");
    assert.equal(existsSync(lazyPath), false,
      "failed clone left a partial lazy.nvim checkout behind: " + lazyPath);
    console.log("PASS: failed Git clone preserves stderr, gives retry guidance and removes the partial checkout");
  });

  let successfulLazyPath;
  await t.test("clones real upstream lazy.nvim and continues normal startup", () => {
    const workspace = createWorkspace(root, "successful-clone");
    const callsFile = join(workspace.base, "git-calls.log");
    const wrapper = createGitWrapper(join(workspace.base, "bin"), callsFile);
    const lazyPath = join(workspace.data, "nvim/lazy/lazy.nvim");
    const result = runNvim(
      workspace,
      wrapper.path,
      [startupCheckCommand(lazyPath)],
      { ...wrapper.extras, DOTFILES_TEST_BOOTSTRAP: "1" }
    );

    assertExited(result, 0, "successful bootstrap");
    assert.match(result.output, /PASS: real lazy\.nvim clone, runtimepath and normal startup/);
    assertNoStartupErrors(result.output, "successful bootstrap");
    assert.deepEqual(cloneCalls(callsFile), ["clone"], "expected exactly one real Git clone of upstream lazy.nvim");
    assert.equal(existsSync(join(lazyPath, "lua/lazy/init.lua")), true,
      "real upstream clone did not contain lua/lazy/init.lua");
    successfulLazyPath = lazyPath;
    console.log("PASS: real upstream lazy.nvim clone was loaded and normal startup completed");
  });

  await t.test("reuses an existing valid checkout without invoking Git clone", () => {
    assert.ok(successfulLazyPath, "successful upstream clone fixture was not created");
    const workspace = createWorkspace(root, "existing-clone");
    const lazyPath = join(workspace.data, "nvim/lazy/lazy.nvim");
    mkdirSync(join(workspace.data, "nvim/lazy"), { recursive: true });
    cpSync(successfulLazyPath, lazyPath, { recursive: true });

    const callsFile = join(workspace.base, "git-calls.log");
    const wrapper = createGitWrapper(join(workspace.base, "bin"), callsFile);
    const result = runNvim(
      workspace,
      wrapper.path,
      [startupCheckCommand(lazyPath)],
      { ...wrapper.extras, DOTFILES_TEST_BOOTSTRAP: "1" }
    );

    assertExited(result, 0, "existing lazy.nvim checkout");
    assert.match(result.output, /PASS: real lazy\.nvim clone, runtimepath and normal startup/);
    assertNoStartupErrors(result.output, "existing lazy.nvim checkout");
    assert.deepEqual(cloneCalls(callsFile), [],
      "a valid existing lazy.nvim checkout triggered another Git clone");
    console.log("PASS: existing lazy.nvim checkout is reused without another clone");
  });
});
