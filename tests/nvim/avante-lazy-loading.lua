-- Verify Avante stays unloaded during ordinary startup, lazy-loads on the
-- first real InsertEnter event, and uses Ollama for automatic suggestions.

local function wait_for(description, timeout_ms, predicate)
  assert(vim.wait(timeout_ms, predicate, 25), ("Timed out waiting for %s"):format(description))
end

local lazy = require("lazy.core.config")
local avante_spec = assert(lazy.plugins["avante.nvim"], "Avante plugin spec is missing")
assert(lazy.plugins["codeium.vim"] == nil, "retired Codeium plugin is still declared")
assert(package.loaded["avante"] == nil, "Avante loaded during ordinary startup")
assert(package.loaded["avante.config"] == nil, "Avante configuration loaded during ordinary startup")

local function has_event(event)
  if type(avante_spec.event) == "string" then return avante_spec.event == event end
  return vim.tbl_contains(avante_spec.event or {}, event)
end

assert(has_event("InsertEnter"), "Avante must load on the first InsertEnter for automatic completion")
assert(avante_spec.build == ":AvanteBuild", "Avante must download release-matched native libraries instead of compiling from source")
assert(vim.fn.maparg("<Space>at", "n") ~= "", "Avante toggle keymap is missing")
assert(vim.fn.maparg("<Space>aa", "n") ~= "", "Avante ask keymap is missing")
assert(vim.fn.maparg("<Space>ae", "v") ~= "", "Avante visual-edit keymap is missing")
assert(vim.fn.exists(":Avante") == 2, "Avante command is not registered as a lazy trigger")
assert(type(avante_spec.opts) == "table", "Avante opts were not registered with lazy.nvim")

print("PASS: Avante stays unloaded during idle startup and is registered for InsertEnter")

-- Use Neovim's real InsertEnter event path rather than manually requiring the plugin.
vim.api.nvim_feedkeys("i", "xt", false)
wait_for("Avante to load on InsertEnter", 30000, function()
  return package.loaded["avante"] ~= nil and package.loaded["avante.config"] ~= nil
end)
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)

assert(vim.fn.exists(":AvanteAsk") == 2, "AvanteAsk command was not registered after loading")
assert(vim.fn.exists(":AvanteBuild") == 2, "AvanteBuild command was not registered after loading")

local config = require("avante.config")
local expected_endpoint = vim.env.AVANTE_OLLAMA_ENDPOINT or "http://127.0.0.1:11434"
local expected_model = vim.env.AVANTE_OLLAMA_MODEL or "gemma4:12b"

assert(config.provider == "ollama", "expected local Ollama provider, got " .. tostring(config.provider))
assert(config.auto_suggestions_provider == "ollama", "automatic suggestions provider must remain local")
assert(config.providers.ollama.endpoint == expected_endpoint,
  "Ollama endpoint mismatch: expected " .. expected_endpoint .. ", got " .. tostring(config.providers.ollama.endpoint))
assert(config.providers.ollama.model == expected_model,
  "Ollama model mismatch: expected " .. expected_model .. ", got " .. tostring(config.providers.ollama.model))
assert(type(config.providers.ollama.is_env_set) == "function", "Ollama endpoint check is not configured")

assert(config.behaviour.auto_suggestions == true, "automatic inline suggestions must be enabled")
assert(config.behaviour.auto_suggestions_respect_ignore == true, "automatic suggestions must skip Git-ignored files")
assert(config.suggestion.debounce == 800, "automatic suggestion debounce must be 800 ms")
assert(config.suggestion.throttle == 1200, "automatic suggestion throttle must be 1200 ms")
assert(config.behaviour.auto_approve_tool_permissions == false, "agent tools must require permission prompts")
assert(config.behaviour.auto_apply_diff_after_generation == false, "generated diffs must remain reviewable")
assert(config.behaviour.allow_access_to_git_ignored_files == false, "git-ignored files must stay inaccessible")
assert(config.prompt_logger.enabled == false, "prompt logging must be disabled")

assert(vim.fn.maparg("<M-l>", "i") ~= "", "Avante suggestion accept mapping is missing")
assert(vim.fn.maparg("<M-]>", "i") ~= "", "Avante next-suggestion mapping is missing")
assert(vim.fn.maparg("<M-[>", "i") ~= "", "Avante previous-suggestion mapping is missing")
assert(vim.fn.maparg("<C-]>", "i") ~= "", "Avante dismiss-suggestion mapping is missing")

print("PASS: Avante loads on InsertEnter and uses the configured local Ollama model for automatic suggestions")
print("PASS: suggestion pacing, accept/dismiss mappings, tool permissions, diff review, ignored-file access, and prompt logging use the expected settings")
print("INFO: CI validates the automatic-suggestion activation/configuration path; a live model response still requires a local Ollama smoke test")
