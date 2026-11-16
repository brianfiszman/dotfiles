local expected_python = vim.fn.stdpath("data") .. "/python3-venv/bin/python"

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

check("next launch selects the dedicated Python provider before plugin setup",
  expected_python, vim.g.python3_host_prog)
check("selected provider interpreter is executable", 1,
  vim.fn.executable(expected_python))
check("Neovim detects the Python 3 provider", 1, vim.fn.has("python3"))

vim.cmd([[
python3 import pynvim, neovim; vim.vars["dotfiles_python_provider_version"] = getattr(pynvim, "__version__", "installed")
]])

check("real :python3 host imports pynvim and neovim",
  true, type(vim.g.dotfiles_python_provider_version) == "string"
    and vim.g.dotfiles_python_provider_version ~= "")

vim.cmd("checkhealth vim.provider")
local health_buffer = vim.fn.bufnr("health://")
check("checkhealth created its report buffer", true, health_buffer > 0)
local report = table.concat(vim.api.nvim_buf_get_lines(health_buffer, 0, -1, true), "\n")
check("Python provider health reports installed pynvim",
  true, report:find("Latest pynvim is installed.", 1, true) ~= nil)
check("Python provider health does not report a missing pynvim module",
  false, report:find("pynvim is not installed", 1, true) ~= nil)

print("PASS: fresh-launch Python provider and :checkhealth vim.provider integration")
