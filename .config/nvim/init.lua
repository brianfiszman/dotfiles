-- The configuration uses APIs introduced in Neovim 0.11.
local nvim_version = vim.version()
if nvim_version.major == 0 and nvim_version.minor < 11 then
  error(("[dotfiles] Neovim 0.11 or newer is required (found %d.%d.%d)."):format(
    nvim_version.major,
    nvim_version.minor,
    nvim_version.patch
  ))
end

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.sessionoptions = { -- required
  "buffers",
  "tabpages",
  "globals",
}

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- Prefer an isolated pynvim environment when one has been created for this setup.
-- If the maintainer has configured a different Python host explicitly, respect it.
local python_host = vim.fn.stdpath("data") .. "/python3-venv/bin/python"
if vim.g.python3_host_prog == nil and vim.fn.executable(python_host) == 1 then
  vim.g.python3_host_prog = python_host
end

local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_init = lazypath .. "/lua/lazy/init.lua"

if not uv.fs_stat(lazy_init) then
  if vim.fn.executable("git") ~= 1 then
    error("[dotfiles] Git is required to install lazy.nvim. Install Git and restart Neovim.")
  end

  -- Remove an incomplete clone left by an interrupted first launch.
  if uv.fs_stat(lazypath) then
    vim.fn.delete(lazypath, "rf")
  end

  vim.fn.mkdir(vim.fn.fnamemodify(lazypath, ":h"), "p")
  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })

  if vim.v.shell_error ~= 0 or not uv.fs_stat(lazy_init) then
    error(
      "[dotfiles] Could not bootstrap lazy.nvim. Check your internet connection and GitHub access, then restart Neovim.\n"
      .. (output or "")
    )
  end
end

vim.opt.rtp:prepend(lazypath)

require 'core.autocmds'
require 'core.general'
require 'plugins'
require 'bindings.splitting'
require 'bindings.tab'
