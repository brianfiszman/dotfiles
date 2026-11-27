-- Exercise the real Neotest file mapping with project-local JavaScript runners.
-- Instrument the active adapter instances from neotest.config (not the original
-- require() return values) so failures include the RunSpec, process result and
-- Neotest's own exception notification.

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 100)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local root = vim.fn.getcwd()
local cases = {
  { adapter = "neotest-jest", project = "jest" },
  { adapter = "neotest-mocha", project = "mocha" },
}
if vim.v.vim_did_enter == 0 then
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
end

local neotest = require("neotest")
local config = require("neotest.config")
local lhs = (vim.g.mapleader or "\\") .. "tf"
local original_notify = vim.notify
local captured_notifications = {}

vim.notify = function(message, level, opts)
  if opts and opts.title == "Neotest" and (level or 0) >= vim.log.levels.WARN then
    captured_notifications[#captured_notifications + 1] = {
      level = level,
      message = type(message) == "string" and message or vim.inspect(message),
    }
  end
  return original_notify(message, level, opts)
end

local function get_adapter(name)
  for _, adapter in ipairs(config.adapters) do
    if adapter.name == name then
      return adapter
    end
  end
end

local function summarize_results(results)
  local summary = { passed = 0, failed = 0, skipped = 0, other = 0 }
  for _, result in pairs(results or {}) do
    if summary[result.status] ~= nil then
      summary[result.status] = summary[result.status] + 1
    else
      summary.other = summary.other + 1
    end
  end
  return summary
end

local ok, failure = xpcall(function()
  wait_for("Neotest file-test mapping registration", 30000, function()
    return vim.fn.maparg(lhs, "n") ~= ""
  end)

  for _, case in ipairs(cases) do
    local project = root .. "/tests/fixtures/neotest-js/" .. case.project
    local file = project .. "/sample.test.js"
    assert(vim.fn.filereadable(file) == 1, "Missing fixture: " .. file)
    vim.cmd("cd " .. vim.fn.fnameescape(project))
    vim.cmd("edit " .. vim.fn.fnameescape(file))
    vim.bo.filetype = "javascript"

    local adapter = assert(get_adapter(case.adapter),
      "Active Neotest config has no adapter instance named " .. case.adapter)
    local original_build_spec = adapter.build_spec
    local original_results = adapter.results
    local diagnostics = {
      adapter = adapter.name,
      cwd_before_run = vim.fn.getcwd(),
    }
    captured_notifications = {}
    diagnostics.notifications = captured_notifications

    -- These are the adapter objects that Neotest's AdapterGroup and Client use.
    -- Wrapping the original require() module would miss these copied instances.
    adapter.build_spec = function(args)
      local spec = original_build_spec(args)
      local position = args.tree and args.tree:data() or nil
      diagnostics.run_spec = spec and {
        position = position and {
          id = position.id,
          name = position.name,
          path = position.path,
          type = position.type,
        } or nil,
        command = spec.command,
        cwd = spec.cwd,
        results_path = spec.context and spec.context.results_path or nil,
      } or nil
      return spec
    end
    adapter.results = function(spec, process_result, tree)
      diagnostics.process_result = {
        code = process_result and process_result.code or nil,
        signal = process_result and process_result.signal or nil,
        output = process_result and type(process_result.output) == "string"
          and process_result.output:sub(-4000) or nil,
      }
      local results = original_results(spec, process_result, tree)
      diagnostics.parsed_results = summarize_results(results)
      return results
    end

    local previous_position = select(1, neotest.run.get_last_run())
    print(("STEP: running %s through the real <leader>tf mapping"):format(case.project))
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "xt", false)

    local selected_position, selected_args
    local dispatched = vim.wait(30000, function()
      selected_position, selected_args = neotest.run.get_last_run()
      return selected_position ~= nil and selected_position ~= previous_position
        and selected_args ~= nil and selected_args.adapter ~= nil
    end, 100)
    local adapter_id = dispatched and selected_args.adapter or nil

    local completed = false
    if dispatched then
      assert(type(adapter_id) == "string"
        and vim.startswith(adapter_id, case.adapter .. ":"),
        ("Mapping selected the wrong adapter for %s: %s"):format(
          case.project, vim.inspect(adapter_id)
        ))
      completed = vim.wait(120000, function()
        if #captured_notifications > 0 then
          return true
        end
        local counts = neotest.state.status_counts(adapter_id)
        return counts and counts.total == 2 and counts.running == 0
          and counts.passed + counts.failed + counts.skipped == counts.total
      end, 100)
    end

    local counts = adapter_id and neotest.state.status_counts(adapter_id) or nil
    local positions = adapter_id and neotest.state.positions(adapter_id) or nil
    diagnostics.selected_adapter = adapter_id
    diagnostics.selected_position = selected_position
    diagnostics.status_counts = counts
    diagnostics.discovered_tree = positions and positions:data() or nil
    diagnostics.notifications = captured_notifications

    adapter.build_spec = original_build_spec
    adapter.results = original_results

    assert(dispatched,
      ("%s was not dispatched by the actual file mapping: %s"):format(
        case.adapter, vim.inspect(diagnostics)
      ))
    assert(completed and #captured_notifications == 0
      and counts and counts.total == 2 and counts.running == 0
      and counts.passed == 1 and counts.failed == 1,
      ("%s did not return one pass and one failure: %s"):format(
        case.adapter, vim.inspect(diagnostics)
      ))
    print(("PASS: %s ran 2 real tests (passed=%d, failed=%d)"):format(
      case.adapter, counts.passed, counts.failed
    ))
  end

  assert(package.loaded["dap"] == nil, "ordinary test execution loaded nvim-dap")
  assert(package.loaded["dapui"] == nil, "ordinary test execution loaded DAP UI")
  assert(package.loaded["mason-nvim-dap"] == nil,
    "ordinary test execution loaded Mason DAP")
  print("PASS: Jest/Mocha testing leaves the DAP stack unloaded")
end, debug.traceback)

vim.notify = original_notify
if not ok then
  error(failure)
end
