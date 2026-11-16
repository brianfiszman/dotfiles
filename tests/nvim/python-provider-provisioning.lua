local provider = require("core.python-provider")
local uv = vim.uv or vim.loop
local data_dir = vim.fn.stdpath("data")
local target = data_dir .. "/python3-venv"
local python = vim.fn.exepath("python3")
local original_path = vim.env.PATH or ""
local original_pythonpath = vim.env.PYTHONPATH
local original_pip_no_index = vim.env.PIP_NO_INDEX
local test_dir = data_dir .. "/python-provider-test"

local function check(label, expected, actual)
  if not vim.deep_equal(expected, actual) then
    error(("%s: expected %s, got %s"):format(
      label,
      vim.inspect(expected),
      vim.inspect(actual)
    ))
  end
  print("PASS: " .. label)
end

local function run_python(label)
  local executable = target .. "/bin/python"
  local result = vim.system({
    executable,
    "-c",
    "import pynvim, neovim; print(getattr(pynvim, '__version__', 'installed'))",
  }, { text = true }):wait()
  check(label, 0, result.code)
  return vim.trim(result.stdout or "")
end

local function invoke_and_wait(expected_status, label)
  -- An ERROR-level notification may be surfaced by Neovim as a synchronous
  -- command error on some platforms. That is an expected failure only when
  -- the command has already recorded the corresponding failed state/message.
  local invoked, invocation_error = pcall(vim.api.nvim_cmd, {
    cmd = "DotfilesInstallPythonProvider",
  }, {})
  if not invoked and expected_status ~= "failed" then
    error(("%s: command unexpectedly raised: %s"):format(label, tostring(invocation_error)))
  end

  local completed = provider.state.status ~= "running" or vim.wait(8 * 60 * 1000, function()
    return provider.state.status ~= "running"
  end, 100)
  check(label .. " completion", true, completed)
  check(label .. " result", expected_status, provider.state.status)

  if not invoked then
    check(label .. " synchronous error matches reported failure", true,
      tostring(invocation_error):find(provider.state.message, 1, true) ~= nil)
  end

  return provider.state.message
end

local function assert_no_staging_directories(label)
  local leftovers = vim.fn.globpath(data_dir, ".python3-venv-stage-*", false, true)
  check(label, {}, leftovers)
end

assert(python ~= "", "python3 is required in the isolated CI runner")
check("Python provider command is registered", 2, vim.fn.exists(":DotfilesInstallPythonProvider"))
check("provider remains optional before explicit install", nil, vim.g.python3_host_prog)
vim.g.python3_host_prog = "/custom/python-host"
provider.configure_host()
check("manual Python host override is preserved", "/custom/python-host", vim.g.python3_host_prog)
vim.g.python3_host_prog = nil
provider.configure_host()
check("missing optional provider remains unset", nil, vim.g.python3_host_prog)
check("provider environment is absent before explicit install", false, uv.fs_lstat(target) ~= nil)

local python_version = vim.system({
  python,
  "-c",
  "import sys; print('%d.%d.%d' % sys.version_info[:3]); raise SystemExit(0 if sys.version_info >= (3, 9) else 1)",
}, { text = true }):wait()
check("test Python is 3.9 or newer", 0, python_version.code)
print("INFO: provider test uses " .. vim.trim(python_version.stdout or ""))

vim.fn.mkdir(test_dir, "p")
invoke_and_wait("installed", "first real provider installation")
check("first real provider installation", "installed", provider.state.status)
check("first install reports the exact interpreter",
  true, provider.state.message:find(target .. "/bin/python", 1, true) ~= nil)
check("first install exposes the exact interpreter path", target .. "/bin/python",
  provider.state.path)
check("provisioned pynvim imports", true, run_python("provisioned pynvim and neovim modules") ~= "")
check("Neovim host is not changed before restart", nil, vim.g.python3_host_prog)

local sentinel = target .. "/provider-preservation-sentinel"
vim.fn.writefile({ "keep this working environment" }, sentinel)
check("sentinel is in the working environment", true, uv.fs_stat(sentinel) ~= nil)

-- Missing python3 must fail before creating a stage or touching the working venv.
local empty_path = test_dir .. "/empty-path"
vim.fn.mkdir(empty_path, "p")
vim.env.PATH = empty_path
local missing_message = invoke_and_wait("failed", "missing python3")
vim.env.PATH = original_path
check("missing-python error is actionable", true, missing_message:find("python3 was not found", 1, true) ~= nil)
check("missing-python failure preserves existing provider", true, uv.fs_stat(sentinel) ~= nil)
assert_no_staging_directories("missing-python failure leaves no staging directory")

-- Wrap only python3 -m venv to reproduce a deterministic environment-creation failure.
local venv_failure_bin = test_dir .. "/venv-failure-bin"
vim.fn.mkdir(venv_failure_bin, "p")
local venv_wrapper = venv_failure_bin .. "/python3"
vim.fn.writefile({
  "#!/bin/sh",
  'if [ "$1" = "-m" ] && [ "$2" = "venv" ]; then',
  "  echo 'simulated venv creation failure' >&2",
  "  exit 73",
  "fi",
  "exec " .. vim.fn.shellescape(python) .. ' "$@"',
}, venv_wrapper)
vim.fn.setfperm(venv_wrapper, "rwx------")
vim.env.PATH = venv_failure_bin .. ":" .. original_path
local venv_message = invoke_and_wait("failed", "venv creation failure")
vim.env.PATH = original_path
check("venv error includes actionable failure detail", true,
  venv_message:find("simulated venv creation failure", 1, true) ~= nil)
check("venv failure preserves existing provider", true, uv.fs_stat(sentinel) ~= nil)
run_python("existing provider still imports after venv failure")
assert_no_staging_directories("venv failure leaves no staging directory")

-- Disabling package indexes makes pip fail deterministically without network timing.
vim.env.PIP_NO_INDEX = "1"
local pip_message = invoke_and_wait("failed", "pip installation failure")
vim.env.PIP_NO_INDEX = original_pip_no_index
check("pip error explains recovery and preservation", true,
  pip_message:find("Could not install or update pip and pynvim", 1, true) ~= nil)
check("pip failure preserves existing provider", true, uv.fs_stat(sentinel) ~= nil)
run_python("existing provider still imports after pip failure")
assert_no_staging_directories("pip failure leaves no staging directory")

-- PYTHONPATH shadows the real installed module only during the final import check.
local import_failure_dir = test_dir .. "/import-failure"
vim.fn.mkdir(import_failure_dir, "p")
vim.fn.writefile({
  "raise RuntimeError('simulated pynvim import failure')",
}, import_failure_dir .. "/pynvim.py")
vim.env.PYTHONPATH = import_failure_dir
local import_message = invoke_and_wait("failed", "pynvim import failure")
vim.env.PYTHONPATH = original_pythonpath
check("import error includes the Python failure", true,
  import_message:find("simulated pynvim import failure", 1, true) ~= nil)
check("import failure preserves existing provider", true, uv.fs_stat(sentinel) ~= nil)
run_python("existing provider still imports after import failure")
assert_no_staging_directories("import failure leaves no staging directory")

-- Re-running the command must replace the environment at the same stable path.
invoke_and_wait("installed", "repeat installation")
check("repeat installation is idempotent", "installed", provider.state.status)
check("repeat installation keeps the configured interpreter path", target .. "/bin/python",
  provider.state.path)
check("replacement environment imports successfully", true,
  run_python("replacement pynvim and neovim modules") ~= "")
check("successful replacement removes the old environment sentinel", false,
  uv.fs_stat(sentinel) ~= nil)
assert_no_staging_directories("successful installation leaves no staging directory")

local backups = vim.fn.globpath(data_dir, ".python3-venv-backup-*", false, true)
check("successful replacement removes its previous-environment backup", {}, backups)

print("PASS: optional Python provider real provisioning and failure-preservation suite")
