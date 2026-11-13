-- Neovim configuration entry point.
-- This config currently uses APIs introduced in Neovim 0.11.
local nvim_version = vim.version()
if nvim_version.major == 0 and nvim_version.minor < 11 then
  error(("[dotfiles] Neovim 0.11 or newer is required (found %d.%d.%d)."):format(
    nvim_version.major,
    nvim_version.minor,
    nvim_version.patch
  ))
end

-- lazy.nvim is the only plugin manager used by this configuration.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  if vim.fn.executable("git") ~= 1 then
    error("[dotfiles] Git is required to install lazy.nvim. Install Git and restart Neovim.")
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

  if vim.v.shell_error ~= 0 then
    error(("[dotfiles] Could not install lazy.nvim. Check your network connection and Git, then restart Neovim.\n%s"):format(output))
  end
end

vim.opt.rtp:prepend(lazypath)

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.sessionoptions = {
  "buffers",
  "tabpages",
  "globals",
}

vim.opt.termguicolors = true

require("core.autocmds")
require("core.general")
require("plugins")
require("bindings.splitting")
require("bindings.tab")
