#!/usr/bin/env python3
"""Run one Neovim RPC command with a hard deadline."""

from __future__ import annotations

import os
import subprocess
import sys


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: nvim-rpc.py COMMAND [ARG ...]", file=sys.stderr)
        return 2

    try:
        timeout_seconds = float(os.environ.get("NVIM_RPC_TIMEOUT_SECONDS", "2"))
    except ValueError:
        print("NVIM_RPC_TIMEOUT_SECONDS must be a positive number", file=sys.stderr)
        return 2
    if timeout_seconds <= 0:
        print("NVIM_RPC_TIMEOUT_SECONDS must be a positive number", file=sys.stderr)
        return 2

    command = sys.argv[1:]
    try:
        result = subprocess.run(
            command,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired:
        print(
            f"[nvim-rpc] command exceeded its {timeout_seconds:g}s deadline: {command!r}",
            file=sys.stderr,
        )
        return 124
    except OSError as error:
        print(f"[nvim-rpc] could not execute {command[0]!r}: {error}", file=sys.stderr)
        return 127

    if result.returncode != 0:
        if result.stderr:
            sys.stderr.write(result.stderr)
        return result.returncode

    sys.stdout.write(result.stdout.replace("\\r", "").replace("\\n", ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
