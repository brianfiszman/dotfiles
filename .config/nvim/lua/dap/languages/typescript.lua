local M = {}

function M.setAdapters(js_based_languages, dap, dap_utils)
  local js_debug_server = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      args = {
        require("mason-registry").get_package("js-debug-adapter"):get_install_path() ..
          "/js-debug/src/dapDebugServer.js",
        "${port}",
      },
    },
  }
  dap.adapters["pwa-node"] = js_debug_server
  dap.adapters["pwa-chrome"] = js_debug_server

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
