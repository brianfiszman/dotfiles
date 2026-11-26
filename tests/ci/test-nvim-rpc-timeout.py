#!/usr/bin/env python3
"""Regression tests for bounded Neovim RPC subprocesses."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
RPC_HELPER = REPO_ROOT / "scripts" / "nvim-rpc.py"


def run_helper(*command: str, timeout_seconds: str = "2") -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["NVIM_RPC_TIMEOUT_SECONDS"] = timeout_seconds
    return subprocess.run(
        [sys.executable, str(RPC_HELPER), *command],
        check=False,
        capture_output=True,
        text=True,
        env=env,
        timeout=3,
    )


def main() -> None:
    success = run_helper(
        sys.executable,
        "-c",
        "print('42\\r\\n')",
    )
    assert success.returncode == 0, success.stderr
    assert success.stdout == "42", repr(success.stdout)

    failure = run_helper(
        sys.executable,
        "-c",
        "import sys; print('expected failure', file=sys.stderr); sys.exit(7)",
    )
    assert failure.returncode == 7, failure.returncode
    assert "expected failure" in failure.stderr

    timed_out = run_helper(
        sys.executable,
        "-c",
        "import time; time.sleep(10)",
        timeout_seconds="0.1",
    )
    assert timed_out.returncode == 124, timed_out.returncode
    assert "exceeded its 0.1s deadline" in timed_out.stderr, timed_out.stderr

    print("PASS: Neovim RPC helper preserves successful output")
    print("PASS: Neovim RPC helper preserves command failures")
    print("PASS: Neovim RPC helper kills commands at the configured deadline")


if __name__ == "__main__":
    main()
