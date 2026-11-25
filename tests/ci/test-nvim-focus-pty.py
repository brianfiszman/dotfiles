#!/usr/bin/env python3
"""Exercise the focus PTY's startup-prompt handling without launching Neovim."""

from __future__ import annotations

import importlib.util
import io
import os
import select
import sys
from contextlib import redirect_stdout
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
DRIVER_PATH = REPO_ROOT / "scripts" / "run-nvim-focus-pty.py"
SPEC = importlib.util.spec_from_file_location("run_nvim_focus_pty", DRIVER_PATH)
assert SPEC is not None and SPEC.loader is not None
DRIVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DRIVER)


class CaptureStdout:
    def __init__(self) -> None:
        self.buffer = io.BytesIO()

    def flush(self) -> None:
        self.buffer.flush()


def make_driver(read_fd: int, writes: list[bytes]):
    driver = DRIVER.FocusPtyDriver.__new__(DRIVER.FocusPtyDriver)
    driver.master_fd = read_fd
    driver.control_buffer = bytearray()
    driver.terminal_query_buffer = bytearray()
    driver.terminal_output = bytearray()
    driver.focus_reporting_enabled = True
    driver.focus_reporting_disabled = False
    driver.focus_lost_sent = 0
    driver.focus_gained_sent = 0
    driver.hit_enter_prompt_dismissals = 0
    driver.pty_eof = False
    driver.startup_quiet_observed = False
    driver.write_pty = writes.append
    driver._answer_terminal_queries = lambda: None
    return driver


def main() -> None:
    read_fd, write_fd = os.pipe()
    os.set_blocking(read_fd, False)
    writes: list[bytes] = []
    driver = make_driver(read_fd, writes)
    try:
        os.write(write_fd, DRIVER.HIT_ENTER_PROMPT)
        capture = CaptureStdout()
        # The real read_pty() code must recognize the hit-enter prompt and
        # write a single carriage-return byte, not the two printable bytes
        # backslash + r.
        with redirect_stdout(capture):
            driver.read_pty()
        assert writes == [b"\r"], f"expected one real carriage return, got {writes!r}"
        assert driver.hit_enter_prompt_dismissals == 1
        assert DRIVER.HIT_ENTER_PROMPT not in driver.terminal_output
    finally:
        os.close(read_fd)
        os.close(write_fd)

    read_fd, write_fd = os.pipe()
    os.set_blocking(read_fd, False)
    writes = []
    driver = make_driver(read_fd, writes)
    try:
        # If the prompt arrives at the same time as a requested focus change,
        # the driver must drain it, dismiss it, and wait for a quiet PTY before
        # sending the native focus sequence.
        os.write(write_fd, DRIVER.HIT_ENTER_PROMPT)
        capture = CaptureStdout()
        with redirect_stdout(capture):
            driver.handle_control_command("FOCUS_LOST")
        assert writes == [b"\r", DRIVER.FOCUS_LOST_SEQUENCE], (
            "focus input was not ordered after prompt dismissal: " + repr(writes)
        )
        assert driver.startup_quiet_observed is True
        assert driver.hit_enter_prompt_dismissals == 1
        assert driver.focus_lost_sent == 1
    finally:
        os.close(read_fd)
        os.close(write_fd)

    print("PASS: focus PTY sends a real CR before native focus input")
    print("PASS: focus PTY waits for startup output to settle before focus input")


if __name__ == "__main__":
    main()
