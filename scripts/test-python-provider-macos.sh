#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_BIN="${NVIM_BIN:-nvim}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Error: this provider integration script must run on macOS.\n' >&2
  exit 2
fi

for required_command in "$NVIM_BIN" python3 git tar grep tee; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

python3 - <<'PY'
import sys
if sys.version_info < (3, 9):
    raise SystemExit("Python 3.9 or newer is required")
print("Provider test Python:", sys.version.split()[0])
PY

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-python-provider-macos.XXXXXX")"
cleanup() {
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

export HOME="$WORK_DIR/home"
export XDG_CONFIG_HOME="$WORK_DIR/config"
export XDG_DATA_HOME="$WORK_DIR/data"
export XDG_STATE_HOME="$WORK_DIR/state"
export XDG_CACHE_HOME="$WORK_DIR/cache"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

printf '[macOS provider] Neovim: '
"$NVIM_BIN" --version | sed -n '1p'

printf '[macOS provider] Installing dotfiles into isolated XDG paths.\n'
bash "$REPO_ROOT/install.sh" --nvim
NVIM_CONFIG="$XDG_CONFIG_HOME/nvim"
[[ -f "$NVIM_CONFIG/lua/core/python-provider.lua" ]] || {
  printf 'Error: installer did not install the Python provider module.\n' >&2
  exit 1
}
[[ ! -e "$NVIM_CONFIG/venv" ]] || {
  printf 'Error: installer copied a machine-local Python virtualenv.\n' >&2
  exit 1
}

run_provider_test() {
  local label="$1"
  local test_file="$2"
  local expected="$3"
  local log_file="$WORK_DIR/$label.log"
  local status=0

  printf '\n[macOS provider] Running %s.\n' "$label"
  DOTFILES_NVIM_CONFIG="$NVIM_CONFIG" \
    DOTFILES_NVIM_TEST_SCRIPT="$test_file" \
    "$NVIM_BIN" --headless -u "$REPO_ROOT/tests/nvim/python-provider-test-init.lua" \
    2>&1 | tee "$log_file" || status=$?

  if ((status != 0)); then
    printf 'Error: Neovim or the log stream exited %s during %s.\n' "$status" "$label" >&2
    tail -n 80 "$log_file" >&2 || true
    return "$status"
  fi

  if ! grep -Fq "$expected" "$log_file"; then
    printf 'Error: expected completion marker was absent during %s: %s\n' "$label" "$expected" >&2
    return 1
  fi
}

run_provider_test \
  "python-provider-provisioning" \
  "$REPO_ROOT/tests/nvim/python-provider-provisioning.lua" \
  "PASS: optional Python provider real provisioning and failure-preservation suite"

run_provider_test \
  "python-provider-host" \
  "$REPO_ROOT/tests/nvim/python-provider-host.lua" \
  "PASS: fresh-launch Python provider and :checkhealth vim.provider integration"

printf '\nPASS: isolated Neovim Python provider integration on macOS.\n'
