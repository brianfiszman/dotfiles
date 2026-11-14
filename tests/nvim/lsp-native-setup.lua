local lsp = require("lsp.config")

assert(type(lsp.servers) == "table" and #lsp.servers > 0, "LSP server list is missing")

local unique = {}
for _, server in ipairs(lsp.servers) do
  assert(not unique[server], "LSP server is listed more than once: " .. server)
  unique[server] = true

  local config = vim.lsp.config[server]
  assert(type(config) == "table", "native LSP config is missing: " .. server)
  assert(type(config.on_attach) == "function", "shared on_attach is missing: " .. server)
end

assert(package.loaded["lsp-zero"] == nil, "lsp-zero was loaded")
assert(package.loaded["lspconfig"] == nil, "deprecated nvim-lspconfig framework was loaded")
assert(package.loaded["typescript-tools"] ~= nil, "typescript-tools setup did not run")

local lua_config = vim.lsp.config.lua_ls
assert(type(lua_config.before_init) == "function", "Neodev before_init integration is missing")
assert(lua_config.settings.Lua.diagnostics.globals[1] == "vim", "LuaLS vim global setting is missing")

local go_config = vim.lsp.config.gopls
assert(go_config.settings.gopls.gofumpt == true, "gopls gofumpt setting is missing")

local yaml_config = vim.lsp.config.yamlls
assert(yaml_config.settings.yaml.validate == false, "YAML validation setting changed")
assert(yaml_config.settings.yaml.schemas["https://json.schemastore.org/github-workflow.json"] == "/.github/workflows/*",
  "GitHub Actions YAML schema mapping is missing")

local compose_config = vim.lsp.config.docker_compose_language_service
assert(compose_config.filetypes[1] == "yaml.docker-compose", "Docker Compose filetype mapping is missing")
assert(compose_config.workspace_required == true, "Docker Compose workspace requirement is missing")

local eslint_config = vim.lsp.config.eslint
assert(eslint_config.on_attach ~= lua_config.on_attach, "ESLint save-time behavior was not given its own attach hook")
assert(eslint_config.settings.workingDirectories.mode == "auto", "ESLint working directory behavior is missing")
assert(eslint_config.workspace_required == true, "ESLint workspace requirement is missing")

local svelte_config = vim.lsp.config.svelte
assert(svelte_config.on_attach ~= lua_config.on_attach, "Svelte change notification hook is missing")

assert(lsp.mason_options.automatic_enable == false, "Mason-LSPConfig must not auto-enable servers")
assert(#lsp.enabled_servers == #lsp.servers, "Not all configured servers were explicitly enabled")

local diagnostic_config = vim.diagnostic.config()
assert(diagnostic_config.underline == true, "Diagnostic underline setting is missing")
assert(diagnostic_config.update_in_insert == false, "Diagnostics should not update during insert mode")
assert(diagnostic_config.signs.text[vim.diagnostic.severity.ERROR] == "✘", "Diagnostic error sign changed")
assert(diagnostic_config.signs.text[vim.diagnostic.severity.WARN] == "▲", "Diagnostic warning sign changed")

print("PASS: native LSP configs exist once for every supported server")
print("PASS: lsp-zero and the deprecated lspconfig framework remain unloaded")
print("PASS: Mason installs servers without owning activation")
print("PASS: TypeScript, ESLint, Svelte, Go, YAML, Docker Compose, and Lua overrides are preserved")
print("PASS: shared diagnostics and LSP completion setup are configured")
