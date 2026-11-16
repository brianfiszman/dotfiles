local model = vim.env.AVANTE_OLLAMA_MODEL or "qwen3:8b"
local endpoint = vim.env.AVANTE_OLLAMA_ENDPOINT or "http://127.0.0.1:11434"

return {
  "yetone/avante.nvim",
  version = false,
  build = "make",
  event = "InsertEnter",
  cmd = {
    "Avante",
    "AvanteAsk",
    "AvanteBuild",
    "AvanteChat",
    "AvanteChatNew",
    "AvanteEdit",
    "AvanteModels",
    "AvanteSwitchProvider",
  },
  keys = {
    { "<leader>at", "<cmd>Avante toggle<cr>", desc = "Avante: Toggle assistant" },
    { "<leader>aa", "<cmd>AvanteAsk<cr>", desc = "Avante: Ask about code" },
    { "<leader>ae", "<cmd>AvanteEdit<cr>", mode = "v", desc = "Avante: Edit selection" },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "ColinKennedy/mega.cmdparse",
      dependencies = { "ColinKennedy/mega.logging" },
    },
  },
  opts = {
    mode = "agentic",
    provider = "ollama",
    auto_suggestions_provider = "ollama",
    providers = {
      ollama = {
        endpoint = endpoint,
        model = model,
        -- Ollama has no API key; explicitly probe the configured local endpoint.
        is_env_set = function()
          return require("avante.providers.ollama").check_endpoint_alive()
        end,
      },
    },
    behaviour = {
      auto_suggestions = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      auto_approve_tool_permissions = false,
      auto_add_current_file = true,
      allow_access_to_git_ignored_files = false,
    },
    -- Prompts and project code should not be copied into a local replay log.
    prompt_logger = {
      enabled = false,
    },
    suggestion = {
      debounce = 800,
      throttle = 1200,
    },
  },
}
