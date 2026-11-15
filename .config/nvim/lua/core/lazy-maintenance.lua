local M = {}
local pending_help_tags = {}

local function remove_untracked_help_tags(plugin)
  if not plugin.url or not plugin._ or not plugin._.installed or not plugin.dir then
    return false
  end

  local doc_dir = plugin.dir .. "/doc"
  local tags_file = doc_dir .. "/tags"
  local stat = (vim.uv or vim.loop).fs_lstat(tags_file)
  if not stat or stat.type ~= "file" then
    return false
  end

  -- lazy.nvim's plugin.docs task generates this index with :helptags. It may
  -- be removed for checkout only when it is not part of the upstream tree.
  local tracked = vim.system({
    "git", "-C", plugin.dir, "ls-files", "--error-unmatch", "--", "doc/tags",
  }, { text = true }):wait()

  if tracked.code == 0 then
    return false
  end
  if tracked.code ~= 1 then
    error(("Could not determine whether %s/doc/tags is tracked: %s"):format(
      plugin.name or plugin.dir,
      tracked.stderr or tracked.stdout or "unknown Git error"
    ))
  end

  local ok, err = (vim.uv or vim.loop).fs_unlink(tags_file)
  if not ok then
    error(("Could not remove generated untracked help tags for %s: %s"):format(
      plugin.name or plugin.dir,
      err or "unknown filesystem error"
    ))
  end

  pending_help_tags[doc_dir] = true
  return true
end

function M.cleanup_untracked_help_tags()
  local config = require("lazy.core.config")
  local removed = 0

  for _, plugin in pairs(config.plugins) do
    if remove_untracked_help_tags(plugin) then
      removed = removed + 1
    end
  end

  if removed > 0 then
    vim.notify(
      ("Prepared %d generated untracked doc/tags file(s) for plugin checkout."):format(removed),
      vim.log.levels.INFO,
      { title = "Dotfiles" }
    )
  end

  return removed
end

function M.restore_help_tags()
  for doc_dir in pairs(pending_help_tags) do
    local tags_file = doc_dir .. "/tags"
    local stat = (vim.uv or vim.loop).fs_lstat(tags_file)

    -- An updated upstream revision may now track doc/tags, or Lazy's normal
    -- plugin.docs task may already have regenerated it. In either case keep
    -- the new file. If the plugin was not updated, recreate the old index.
    if not stat and vim.fn.isdirectory(doc_dir) == 1 then
      local ok, err = pcall(vim.api.nvim_cmd, {
        cmd = "helptags",
        args = { doc_dir },
      }, { output = true })
      if not ok then
        error(("Could not restore generated help tags in %s: %s"):format(doc_dir, tostring(err)))
      end
    end
  end

  pending_help_tags = {}
end

function M.setup()
  if M._setup then
    return
  end
  M._setup = true

  local group = vim.api.nvim_create_augroup("DotfilesLazyMaintenance", { clear = true })
  for _, event in ipairs({ "LazyUpdatePre", "LazyRestorePre" }) do
    vim.api.nvim_create_autocmd("User", {
      pattern = event,
      group = group,
      callback = M.cleanup_untracked_help_tags,
      desc = "Prepare generated untracked help tags for lazy.nvim plugin checkouts",
    })
  end
  for _, event in ipairs({ "LazyUpdate", "LazyRestore" }) do
    vim.api.nvim_create_autocmd("User", {
      pattern = event,
      group = group,
      callback = M.restore_help_tags,
      desc = "Restore generated help tags for plugins not updated by lazy.nvim",
    })
  end
end

return M
