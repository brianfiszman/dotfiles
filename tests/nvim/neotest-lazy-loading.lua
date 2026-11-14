-- Verify Neotest, vim-test, and its adapters stay unloaded until a test action.
-- The Stop mapping is deliberately used: it activates the testing integration
-- without launching a real project test suite.

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 50)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local lazy_modules = {
  "neotest",
  "neotest-vim-test",
  "neotest-python",
  "neotest-vitest",
  "neotest-plenary",
  "neotest-zig",
  "neotest-go",
  "neotest-mocha",
  "neotest-jest",
}

for _, module in ipairs(lazy_modules) do
  assert(package.loaded[module] == nil, module .. " loaded during idle startup")
end
assert(vim.g["test#strategy"] == nil, "vim-test was configured during idle startup")
assert(package.loaded["dap"] == nil, "DAP loaded during idle startup")
print("PASS: Neotest, vim-test, adapters, and DAP stay unloaded during idle startup")

if vim.v.vim_did_enter == 0 then
  print("STEP: firing VimEnter so Which-Key can finalize queued mappings")
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
end

local leader = vim.g.mapleader or "\\"
local lhs = leader .. "ts"
wait_for("lazy.nvim to register the existing Test Stop trigger", 30000, function()
  return vim.fn.maparg(lhs, "n") ~= ""
end)

local mapping = vim.fn.maparg(lhs, "n", false, true)
assert(type(mapping) == "table" and mapping.rhs ~= "", "Test Stop trigger has no executable mapping")
print(("MAPPING: Test Stop rhs=%s"):format(mapping.rhs))

print("STEP: dispatching the existing Test Stop mapping")
local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
vim.api.nvim_feedkeys(keys, "xt", false)

wait_for("Neotest and vim-test setup to finish", 30000, function()
  return package.loaded["neotest"] ~= nil
    and vim.g["test#strategy"] == "neovim"
end)

for _, module in ipairs({
  "neotest-vim-test",
  "neotest-python",
  "neotest-vitest",
  "neotest-plenary",
  "neotest-zig",
  "neotest-go",
  "neotest-mocha",
  "neotest-jest",
}) do
  assert(package.loaded[module] ~= nil, module .. " was not loaded by Neotest setup")
end
print("PASS: first test action loads Neotest, vim-test, and all configured adapters")

assert(package.loaded["dap"] == nil, "ordinary test action unexpectedly loaded nvim-dap")
assert(package.loaded["dapui"] == nil, "ordinary test action unexpectedly loaded DAP UI")
assert(package.loaded["mason-nvim-dap"] == nil, "ordinary test action unexpectedly loaded Mason DAP")
assert(package.loaded["nvim-dap-virtual-text"] == nil, "ordinary test action unexpectedly loaded DAP virtual text")
print("PASS: ordinary test action leaves the DAP stack unloaded")
