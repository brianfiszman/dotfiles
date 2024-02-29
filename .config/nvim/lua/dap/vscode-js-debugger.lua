local M = {
  "microsoft/vscode-js-debug",
  build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
  version = "1.77",
}

return M
