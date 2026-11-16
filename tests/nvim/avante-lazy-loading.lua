-- Verify Avante is idle until the maintainer invokes its actual keymap,
-- then assert the loaded provider and safety-sensitive settings.

local function wait_for(description, timeout_ms, predicate)
  assert(vim.wait(timeout_ms, predicate, 25), ("Timed out waiting for %s"):format(description))
end

local lazy = require("lazy.core.config")
local avante_spec = assert(lazy.plugins["avante.nvim"], "Avante plugin spec is missing")
assert(lazy.plugins["codeium.vim"] == nil, "retired Codeium plugin is still declared")
assert(package.loaded["avante"] == nil, "Avante loaded during ordinary startup")
assert(package.loaded["avante.config"] == nil, "Avante configuration loaded during ordinary startup")

local leader = vim.g.mapleader or "\\"
assert(vim.fn.maparg(leader .. "aa", "n") ~= "", "Avante toggle keymap is missing")
assert(vim.fn.maparg(leader .. "aq", "n") ~= "", "Avante ask keymap is missing")
assert(vim.fn.maparg(leader .. "ae", "v") ~= "", "Avante visual-edit keymap is missing")
assert(vim.fn.exists(":Avante") == 2, "Avante command is not registered as a lazy trigger")
assert(type(avante_spec.opts) == "table", "Avante opts were not registered with lazy.nvim")

print("PASS: Avante stays unloaded during idle startup and exposes its user keymaps/command")

-- Replay the real normal-mode mapping, including lazy.nvim's remapping handler.
local keys = vim.api.nvim_replace_termcodes(leader .. "aa", true, false, true)
vim.api.nvim_feedkeys(keys, "mtx", false)
wait_for("the Avante module to load from <leader>aa", 30000, function()
  return package.loaded["avante"] ~= nil and package.loaded["avante.config"] ~= nil
end)

assert(vim.fn.exists(":AvanteAsk") == 2, "AvanteAsk command was not registered after loading")
assert(vim.fn.exists(":AvanteBuild") == 2, "AvanteBuild command was not registered after loading")

local config = require("avante.config")
local expected_endpoint = vim.env.AVANTE_OLLAMA_ENDPOINT or "http://127.0.0.1:11434"
local expected_model = vim.env.AVANTE_OLLAMA_MODEL or "qwen3:8b"

assert(config.provider == "ollama", "expected local Ollama provider, got " .. tostring(config.provider))
assert(config.auto_suggestions_provider == "ollama", "automatic suggestions provider must remain local")
assert(config.providers.ollama.endpoint == expected_endpoint,
  "Ollama endpoint mismatch: expected " .. expected_endpoint .. ", got " .. tostring(config.providers.ollama.endpoint))
assert(config.providers.ollama.model == expected_model,
  "Ollama model mismatch: expected " .. expected_model .. ", got " .. tostring(config.providers.ollama.model))
assert(type(config.providers.ollama.is_env_set) == "function", "Ollama endpoint check is not configured")

assert(config.behaviour.auto_suggestions == false, "experimental automatic suggestions must be off by default")
assert(config.behaviour.auto_approve_tool_permissions == false, "agent tools must require permission prompts")
assert(config.behaviour.auto_apply_diff_after_generation == false, "generated diffs must remain reviewable")
assert(config.behaviour.allow_access_to_git_ignored_files == false, "git-ignored files must stay inaccessible")
assert(config.prompt_logger.enabled == false, "prompt logging must be disabled")

print("PASS: Avante loads on the real keymap and selects the configured local Ollama provider")
print("PASS: tool permissions, diff review, ignored-file access, prompt logging, and auto-suggestions use safe defaults")
print("INFO: no model request was made; live Ollama inference is covered by the documented manual smoke test")
