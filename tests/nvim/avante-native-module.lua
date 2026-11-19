-- Verify Avante's Rust template module loads through the actual Lazy.nvim
-- InsertEnter/config path. Do not add package.cpath manually: doing so would
-- hide a missing avante_lib.load() call in the plugin configuration.

local function wait_for(description, timeout_ms, predicate)
  assert(vim.wait(timeout_ms, predicate, 25), ("Timed out waiting for %s"):format(description))
end

-- The configured Avante config function must call avante_lib.load() before
-- avante.setup(), which makes the release-matched native modules requireable.
vim.api.nvim_feedkeys("i", "xt", false)
wait_for("Avante to finish loading on InsertEnter", 30000, function()
  return package.loaded["avante"] ~= nil and package.loaded["avante.config"] ~= nil
end)
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)

local ok, templates = pcall(require, "avante_templates")
assert(ok, "Avante config did not load avante_templates through avante_lib.load(): " .. tostring(templates))
assert(type(templates) == "table", "avante_templates must return a Lua module table")
assert(type(templates.initialize) == "function", "avante_templates.initialize is missing")
assert(type(templates.render) == "function", "avante_templates.render is missing")

print("PASS: Avante InsertEnter config loaded avante_lib and avante_templates is requireable")
vim.cmd("qa!")
