local M = {}

local function remove_untracked_help_tags(plugin)
  if not plugin.url or not plugin._ or not plugin._.installed or not plugin.dir then
    return false
  end

  local tags_file = plugin.dir .. "/doc/tags"
  local stat = (vim.uv or vim.loop).fs_lstat(tags_file)
  if not stat or stat.type ~= "file" then
    return false
  end

  -- lazy.nvim's plugin.docs task generates this index with :helptags. It is
  -- disposable when untracked, but a tracked upstream doc/tags must be kept.
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
      ("Removed %d generated untracked doc/tags file(s) before updating plugins."):format(removed),
      vim.log.levels.INFO,
      { title = "Dotfiles" }
    )
  end

  return removed
end

function M.setup()
  if M._setup then
    return
  end
  M._setup = true

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyUpdatePre",
    group = vim.api.nvim_create_augroup("DotfilesLazyMaintenance", { clear = true }),
    callback = M.cleanup_untracked_help_tags,
    desc = "Remove generated untracked help tags before lazy.nvim checks out plugin updates",
  })
end

return M
