-- Exercise the real Neotest file mapping with project-local JavaScript runners.
local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 100)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local root = vim.fn.getcwd()
local cases = {
  { adapter = "neotest-jest", project = "jest" },
  { adapter = "neotest-vitest", project = "vitest" },
  { adapter = "neotest-mocha", project = "mocha" },
}
if vim.v.vim_did_enter == 0 then
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
end
local lhs = (vim.g.mapleader or "\\") .. "tf"
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
  print(("STEP: running %s via %s and the real <leader>tf mapping"):format(case.project, case.adapter))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "xt", false)
  wait_for(case.adapter .. " to report one pass and one failure", 120000, function()
    local counts = require("neotest").state.status_counts(case.adapter)
    return counts and counts.total == 2 and counts.running == 0
      and counts.passed == 1 and counts.failed == 1
  end)
  local counts = require("neotest").state.status_counts(case.adapter)
  assert(counts.total == 2 and counts.passed == 1 and counts.failed == 1,
    ("%s returned unexpected results: %s"):format(case.adapter, vim.inspect(counts)))
  print(("PASS: %s ran 2 real tests (passed=%d, failed=%d)"):format(
    case.adapter, counts.passed, counts.failed
  ))
end
assert(package.loaded["dap"] == nil, "ordinary test execution loaded nvim-dap")
assert(package.loaded["dapui"] == nil, "ordinary test execution loaded DAP UI")
assert(package.loaded["mason-nvim-dap"] == nil, "ordinary test execution loaded Mason DAP")
print("PASS: Jest/Vitest/Mocha testing leaves the DAP stack unloaded")
