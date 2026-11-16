local M = {
  state = {
    status = "idle",
    message = "Python provider has not been installed in this session.",
  },
}

local uv = vim.uv or vim.loop
local provider_dir_name = "python3-venv"
local stage_prefix = ".python3-venv-stage-"

local function notify(message, level)
  vim.notify(message, level, { title = "Dotfiles" })
end

local function command_output(result)
  local output = {}
  local stdout = vim.trim(result.stdout or "")
  local stderr = vim.trim(result.stderr or "")

  if stdout ~= "" then
    output[#output + 1] = stdout
  end
  if stderr ~= "" then
    output[#output + 1] = stderr
  end

  local joined = table.concat(output, "\n")
  local lines = vim.split(joined, "\n", { plain = true })
  if #lines > 16 then
    local tail = { "... (last 16 lines)" }
    for index = #lines - 15, #lines do
      tail[#tail + 1] = lines[index]
    end
    lines = tail
  end

  return table.concat(lines, "\n")
end

local function cleanup_stage()
  local stage = M._stage_path
  M._stage_path = nil

  if stage and uv.fs_lstat(stage) then
    local result = vim.fn.delete(stage, "rf")
    if result ~= 0 then
      return " Temporary files could not be removed: " .. stage
    end
  end

  return ""
end

local function finish(status, message, path)
  local cleanup_message = ""
  if status ~= "installed" then
    cleanup_message = cleanup_stage()
  else
    M._stage_path = nil
  end

  M.state.status = status
  M.state.message = message .. cleanup_message
  M.state.path = path

  notify(M.state.message, status == "failed" and vim.log.levels.ERROR or vim.log.levels.INFO)
end

local function fail(message)
  finish("failed", message)
end

local function run_async(command, callback)
  local started, process_or_error = pcall(vim.system, command, { text = true }, function(result)
    vim.schedule(function()
      local ok, callback_error = pcall(callback, result)
      if not ok then
        fail("Python provider setup stopped unexpectedly: " .. tostring(callback_error))
      end
    end)
  end)

  if not started then
    callback({
      code = -1,
      stdout = "",
      stderr = tostring(process_or_error),
    })
  end
end

local function unique_backup_path(data_dir)
  local pid = vim.fn.getpid()
  local suffix = 0
  local path

  repeat
    path = ("%s/.python3-venv-backup-%d-%s-%d"):format(
      data_dir,
      pid,
      tostring(uv.hrtime()),
      suffix
    )
    suffix = suffix + 1
  until not uv.fs_lstat(path)

  return path
end

local function publish_stage(data_dir, stage, target)
  local backup
  local existing = uv.fs_lstat(target)

  if existing then
    backup = unique_backup_path(data_dir)
    local moved, move_error = uv.fs_rename(target, backup)
    if not moved then
      fail(("Could not preserve the existing Python provider environment at %s: %s")
        :format(target, tostring(move_error)))
      return
    end
  end

  local published, publish_error = uv.fs_rename(stage, target)
  if not published then
    local restore_error
    if backup then
      local restored
      restored, restore_error = uv.fs_rename(backup, target)
      if not restored then
        fail(("Could not activate the new Python provider (%s), and could not restore the previous environment. The previous environment is preserved at %s. Restore error: %s")
          :format(tostring(publish_error), backup, tostring(restore_error)))
        return
      end
    end

    fail(("Could not activate the new Python provider environment at %s: %s")
      :format(target, tostring(publish_error)))
    return
  end

  M._stage_path = nil

  local cleanup_note = ""
  if backup and vim.fn.delete(backup, "rf") ~= 0 then
    cleanup_note = ("\nThe previous environment backup was left at %s."):format(backup)
  end

  finish(
    "installed",
    ("Python provider installed and verified.\nInterpreter: %s\nRestart Neovim to activate it.%s")
      :format(target .. "/bin/python", cleanup_note),
    target .. "/bin/python"
  )
end

function M.configure_host()
  if vim.g.python3_host_prog ~= nil then
    return
  end

  local python_host = vim.fn.stdpath("data") .. "/" .. provider_dir_name .. "/bin/python"
  if vim.fn.executable(python_host) == 1 then
    vim.g.python3_host_prog = python_host
  end
end

function M.install()
  if M.state.status == "running" then
    notify("Python provider installation is already running.", vim.log.levels.WARN)
    return
  end

  M.state.status = "running"
  M.state.message = "Preparing a dedicated Python provider environment."

  local python = vim.fn.exepath("python3")
  if python == "" then
    fail("Python provider was not installed: python3 was not found in Neovim's PATH. Install Python 3.9 or newer using your normal system setup, make python3 available in PATH, and retry. No files were changed.")
    return
  end

  local version_script = table.concat({
    "import sys",
    "print('Python %d.%d.%d' % sys.version_info[:3])",
    "raise SystemExit(0 if sys.version_info >= (3, 9) else 1)",
  }, "; ")
  local version_ok, version_result = pcall(function()
    return vim.system({ python, "-c", version_script }, { text = true }):wait()
  end)

  if not version_ok then
    fail("Could not run python3 to check its version: " .. tostring(version_result))
    return
  end
  if version_result.code ~= 0 then
    local detail = command_output(version_result)
    if detail == "" then
      detail = "Python 3.9 or newer is required."
    end
    fail("Python provider was not installed: python3 must be version 3.9 or newer.\n" .. detail)
    return
  end

  local data_dir = vim.fn.stdpath("data")
  vim.fn.mkdir(data_dir, "p")
  local data_stat = uv.fs_stat(data_dir)
  if not data_stat or data_stat.type ~= "directory" then
    fail("Could not access Neovim's data directory: " .. data_dir)
    return
  end

  local target = data_dir .. "/" .. provider_dir_name
  local target_stat = uv.fs_lstat(target)
  if target_stat and target_stat.type ~= "directory" then
    fail(("Refusing to replace %s because it is not a directory. Move it aside manually and retry; it was not changed.")
      :format(target))
    return
  end

  local stage, stage_error = uv.fs_mkdtemp(data_dir .. "/" .. stage_prefix .. "XXXXXX")
  if not stage then
    fail(("Could not create a temporary Python environment in %s: %s")
      :format(data_dir, tostring(stage_error)))
    return
  end
  M._stage_path = stage

  local staged_python = stage .. "/bin/python"
  run_async({ python, "-m", "venv", stage }, function(venv_result)
    if venv_result.code ~= 0 then
      local detail = command_output(venv_result)
      fail("Could not create the Python virtual environment. Check that your Python installation includes the venv/ensurepip module.\n" .. detail)
      return
    end

    if vim.fn.executable(staged_python) ~= 1 then
      fail("Python reported that it created a virtual environment, but its interpreter is missing: " .. staged_python)
      return
    end

    run_async({
      staged_python,
      "-m",
      "pip",
      "install",
      "--disable-pip-version-check",
      "--upgrade",
      "pip",
      "pynvim",
    }, function(pip_result)
      if pip_result.code ~= 0 then
        local detail = command_output(pip_result)
        fail("Could not install or update pip and pynvim in the temporary environment. Check your network/PyPI access and retry. The previous Python provider environment was not changed.\n" .. detail)
        return
      end

      run_async({
        staged_python,
        "-c",
        "import pynvim, neovim; print(getattr(pynvim, '__version__', 'installed'))",
      }, function(import_result)
        if import_result.code ~= 0 then
          local detail = command_output(import_result)
          fail("The new environment was created, but Python could not import pynvim and neovim. The previous Python provider environment was not changed.\n" .. detail)
          return
        end

        publish_stage(data_dir, stage, target)
      end)
    end)
  end)
end

function M.setup()
  if M._setup then
    return
  end

  M._setup = true
  vim.api.nvim_create_user_command("DotfilesInstallPythonProvider", M.install, {
    desc = "Install or update the optional Neovim Python provider",
  })
end

return M
