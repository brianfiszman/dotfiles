#!/usr/bin/env python3
"""Run Neovim under a real PTY and inject terminal focus-reporting sequences.

The test process asks this driver to send FOCUS_LOST / FOCUS_GAINED through a
FIFO. The driver writes the corresponding bytes to the PTY master, so Neovim's
own TUI input parser produces the native FocusLost / FocusGained events.
"""

from __future__ import annotations

import errno
import fcntl
import os
import pty
import selectors
import signal
import struct
import sys
import tempfile
import termios
import time
from pathlib import Path


FOCUS_REPORTING_ENABLE = b"\x1b[?1004h"
FOCUS_REPORTING_DISABLE = b"\x1b[?1004l"
FOCUS_LOST_SEQUENCE = b"\x1b[O"
FOCUS_GAINED_SEQUENCE = b"\x1b[I"


class FocusPtyDriver:
    def __init__(self, master_fd: int, fifo_fd: int) -> None:
        self.master_fd = master_fd
        self.fifo_fd = fifo_fd
        self.selector = selectors.DefaultSelector()
        self.selector.register(master_fd, selectors.EVENT_READ, "pty")
        self.selector.register(fifo_fd, selectors.EVENT_READ, "control")
        self.control_buffer = bytearray()
        self.terminal_query_buffer = bytearray()
        self.terminal_output = bytearray()
        self.focus_reporting_enabled = False
        self.focus_reporting_disabled = False
        self.focus_lost_sent = 0
        self.focus_gained_sent = 0
        self.pty_eof = False

    def write_pty(self, data: bytes) -> None:
        view = memoryview(data)
        while view:
            try:
                written = os.write(self.master_fd, view)
            except BlockingIOError:
                selectors.DefaultSelector().select(0.01)
                continue
            if written <= 0:
                raise RuntimeError("PTY master stopped accepting terminal input")
            view = view[written:]

    def _answer_terminal_queries(self) -> None:
        # Behave like the small subset of an xterm-compatible terminal that
        # Neovim queries during startup. This prevents a synthetic PTY from
        # leaving a hit-enter prompt before the behavior test begins.
        queries = (
            (b"\x1b]11;?\x07", b"\x1b]11;rgb:1a1a/1a1a/1a1a\x07"),
            (b"\x1b]11;?\x1b\\", b"\x1b]11;rgb:1a1a/1a1a/1a1a\x07"),
            (b"\x1b]10;?\x07", b"\x1b]10;rgb:dddd/dddd/dddd\x07"),
            (b"\x1b]10;?\x1b\\", b"\x1b]10;rgb:dddd/dddd/dddd\x07"),
            (b"\x1b[5n", b"\x1b[0n"),
            (b"\x1b[>c", b"\x1b[>0;95;0c"),
            (b"\x1b[?u", b"\x1b[?0u"),
            (b"\x1b[c", b"\x1b[?1;2c"),
        )

        while True:
            matched = False
            for query, response in queries:
                index = self.terminal_query_buffer.find(query)
                if index < 0:
                    continue
                del self.terminal_query_buffer[: index + len(query)]
                self.write_pty(response)
                matched = True
                break
            if not matched:
                break

        # Retain enough trailing bytes to recognize a control sequence split
        # across PTY reads without allowing unbounded diagnostic state.
        if len(self.terminal_query_buffer) > 4096:
            del self.terminal_query_buffer[:-4096]

    def read_pty(self) -> None:
        while True:
            try:
                data = os.read(self.master_fd, 65536)
            except BlockingIOError:
                return
            except OSError as error:
                if error.errno == errno.EIO:
                    self.pty_eof = True
                    try:
                        self.selector.unregister(self.master_fd)
                    except Exception:
                        pass
                    return
                raise

            if not data:
                self.pty_eof = True
                try:
                    self.selector.unregister(self.master_fd)
                except Exception:
                    pass
                return

            self.terminal_output.extend(data)
            self.terminal_query_buffer.extend(data)
            if FOCUS_REPORTING_ENABLE in self.terminal_output:
                self.focus_reporting_enabled = True
            if FOCUS_REPORTING_DISABLE in self.terminal_output:
                self.focus_reporting_disabled = True

            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
            self._answer_terminal_queries()

    def wait_for_focus_reporting_request(self, timeout: float = 2.0) -> None:
        deadline = time.monotonic() + timeout
        while not self.focus_reporting_enabled and time.monotonic() < deadline:
            readable, _, _ = __import__("select").select([self.master_fd], [], [], 0.05)
            if readable:
                self.read_pty()
        if not self.focus_reporting_enabled:
            raise RuntimeError(
                "Neovim TUI never requested terminal focus reporting "
                "(expected CSI ? 1004 h before focus input)"
            )

    def handle_control_command(self, command: str) -> None:
        command = command.strip()
        if not command:
            return

        self.wait_for_focus_reporting_request()
        if command == "FOCUS_LOST":
            self.write_pty(FOCUS_LOST_SEQUENCE)
            self.focus_lost_sent += 1
            print(
                f"[focus-pty] sent terminal FocusLost report "
                f"(ESC [ O), count={self.focus_lost_sent}",
                file=sys.stderr,
                flush=True,
            )
        elif command == "FOCUS_GAINED":
            self.write_pty(FOCUS_GAINED_SEQUENCE)
            self.focus_gained_sent += 1
            print(
                f"[focus-pty] sent terminal FocusGained report "
                f"(ESC [ I), count={self.focus_gained_sent}",
                file=sys.stderr,
                flush=True,
            )
        else:
            raise RuntimeError(f"unknown focus PTY command: {command!r}")

    def read_control(self) -> None:
        try:
            data = os.read(self.fifo_fd, 4096)
        except BlockingIOError:
            return

        if not data:
            return
        self.control_buffer.extend(data)
        while b"\n" in self.control_buffer:
            raw, _, remainder = self.control_buffer.partition(b"\n")
            self.control_buffer = bytearray(remainder)
            self.handle_control_command(raw.decode("ascii", errors="strict"))

    def run(self, child_pid: int) -> int:
        child_status: int | None = None
        try:
            while child_status is None:
                for key, _ in self.selector.select(timeout=0.1):
                    if key.data == "pty":
                        self.read_pty()
                    elif key.data == "control":
                        # Drain PTY output first so the focus-reporting enable
                        # request is observed before accepting a focus command.
                        if not self.pty_eof:
                            self.read_pty()
                        self.read_control()

                waited_pid, status = os.waitpid(child_pid, os.WNOHANG)
                if waited_pid == child_pid:
                    child_status = status

            if not self.pty_eof:
                self.read_pty()

            if not os.WIFEXITED(child_status):
                signal_number = os.WTERMSIG(child_status)
                return 128 + signal_number
            exit_code = os.WEXITSTATUS(child_status)

            if exit_code == 0:
                if not self.focus_reporting_enabled:
                    raise RuntimeError("Neovim completed without enabling TUI focus reporting")
                if not self.focus_reporting_disabled:
                    raise RuntimeError("Neovim exited without disabling TUI focus reporting")
                if self.focus_lost_sent < 1 or self.focus_gained_sent < 1:
                    raise RuntimeError(
                        "the test did not drive both terminal focus-reporting sequences"
                    )
                if self.focus_lost_sent != self.focus_gained_sent:
                    raise RuntimeError(
                        "unbalanced focus input: "
                        f"lost={self.focus_lost_sent}, gained={self.focus_gained_sent}"
                    )
                print(
                    "[focus-pty] PASS: real TUI enabled/disabled focus reporting and "
                    f"consumed {self.focus_lost_sent} loss/gain sequence pairs",
                    file=sys.stderr,
                    flush=True,
                )
            return exit_code
        finally:
            self.selector.close()


def stop_child_process_group(child_pid: int) -> None:
    try:
        os.killpg(child_pid, signal.SIGTERM)
    except ProcessLookupError:
        return

    deadline = time.monotonic() + 2.0
    while time.monotonic() < deadline:
        waited_pid, _ = os.waitpid(child_pid, os.WNOHANG)
        if waited_pid == child_pid:
            return
        time.sleep(0.05)

    try:
        os.killpg(child_pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    try:
        os.waitpid(child_pid, 0)
    except ChildProcessError:
        pass


def main(argv: list[str]) -> int:
    if argv and argv[0] == "--":
        argv = argv[1:]
    if not argv:
        print("usage: run-nvim-focus-pty.py -- nvim [args...]", file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory(prefix="dotfiles-focus-pty-") as temporary_dir:
        control_fifo = str(Path(temporary_dir) / "focus-control.fifo")
        os.mkfifo(control_fifo, 0o600)

        child_env = os.environ.copy()
        child_env["TERM"] = "xterm-256color"
        child_env["LINES"] = "24"
        child_env["COLUMNS"] = "80"
        child_env["DOTFILES_FOCUS_CONTROL_FIFO"] = control_fifo

        fifo_fd = os.open(control_fifo, os.O_RDWR | os.O_NONBLOCK)
        child_pid, master_fd = pty.fork()
        if child_pid == 0:
            try:
                os.environ.clear()
                os.environ.update(child_env)
                os.execvpe(argv[0], argv, child_env)
            except BaseException as error:
                os.write(2, f"focus PTY child exec failed: {error}\n".encode())
                os._exit(127)

        driver = FocusPtyDriver(master_fd, fifo_fd)
        try:
            fcntl.ioctl(master_fd, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
            os.kill(child_pid, signal.SIGWINCH)
            os.set_blocking(master_fd, False)
            return driver.run(child_pid)
        except BaseException:
            stop_child_process_group(child_pid)
            raise
        finally:
            try:
                os.close(master_fd)
            except OSError:
                pass
            os.close(fifo_fd)


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        raise SystemExit(130)
    except Exception as error:
        print(f"[focus-pty] ERROR: {error}", file=sys.stderr, flush=True)
        raise SystemExit(1)
