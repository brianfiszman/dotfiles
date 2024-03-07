local M = {}

function M.setAdapters(js_based_languages, dap, dap_utils)
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      -- 💀 Make sure to update this path to point to your installation
      args = {
        require("mason-registry").get_package("js-debug-adapter"):get_install_path() ..
          "/js-debug-adapter.js",
        "${port}",
      },
    },
  }

  for _, language in ipairs(js_based_languages) do
    dap.configurations[language] = {
      -- Debug single nodejs files
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch project and attach",
        runtimeExecutable = "yarn",
        runtimeArgs = { "start:debug:neovim" },
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = dap_utils.pick_process,
        cwd = "${workspaceFolder}",
        port = 9229,
      },
      {
        type = "pwa-chrome",
        request = "launch",
        name = "Start Chrome with \"localhost\"",
        url = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
        userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir"
      },
    }
  end
end

return M
