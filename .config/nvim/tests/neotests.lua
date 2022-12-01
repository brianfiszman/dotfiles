require('overseer').setup({
    dap = true,
    component_aliases = {
      default_neotest = {
        "on_output_summarize",
        "on_exit_set_status",
        "on_complete_notify",
        "on_complete_dispose",
      },
    }
  })

local function config_test()
  vim.api.nvim_exec(
    [[
        " Test config
        let test#strategy = "neovim"
        let test#neovim#term_position = "belowright"
        let g:test#preserve_screen = 1
        " Python
        let test#python#runner = 'pyunit'
        " let test#python#runner = 'pytest'
        " Javascript
        let test#javascript#reactscripts#options = "--watchAll=false"
        let g:test#javascript#runner = 'jest'
        let g:test#javascript#cypress#executable = 'npx cypress run-ct'
        " csharp
        let test#csharp#runner = 'dotnettest'
    ]],
    false
    )
end

require("neotest").setup({
    adapters = {
      require("neotest-plenary"),
      require("neotest-vim-test")({
          ignore_file_types = { "python", "vim", "lua" },
        }),
      require("neotest-go")({
          experimental = {
            test_table = true,
          },
          args = { "-count=1", "-timeout=60s" }
        }),
      require('neotest-jest')({
          jestCommand = "npm test --",
          jestConfigFile = "custom.jest.config.ts",
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        }),
    },

    -- overseer.nvim
    consumers = {
      overseer = require("neotest.consumers.overseer"),
    },
    overseer = {
      enabled = true,
      force_default = true,
    },
  })

config_test()
-- Now neotest.run is unchanged; to run tests with overseer use:
