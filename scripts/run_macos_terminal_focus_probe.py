#!/usr/bin/env python3
"""Observe native Terminal.app focus reports on its real foreground TTY.

Runs inside the Terminal.app .command session, requests DECSET 1004, records
only incoming CSI I / CSI O bytes, and restores terminal state before Neovim
is exec'd in the same TTY. It never writes a focus-event sequence.
"""
from __future__ import annotations

import argparse
import os
import select
import sys
import termios
import time
import tty
from pathlib import Path

FOCUS_REPORTING_ENABLE = b"\x1b[?1004h"
FOCUS_REPORTING_DISABLE = b"\x1b[?1004l"
FOCUS_LOST_SEQUENCE = b"\x1b[O"
FOCUS_GAINED_SEQUENCE = b"\x1b[I"


class FocusSequenceDecoder:
    """Decode focus reports that may be split across arbitrary reads."""

    def __init__(self) -> None:
        self.pending = bytearray()

    def feed(self, data: bytes) -> list[str]:
        self.pending.extend(data)
        events: list[str] = []
        sequences = (
            (FOCUS_LOST_SEQUENCE, "focus_lost"),
            (FOCUS_GAINED_SEQUENCE, "focus_gained"),
        )
        while True:
            matches = [
                (self.pending.find(sequence), event, len(sequence))
                for sequence, event in sequences
                if self.pending.find(sequence) >= 0
            ]
            if not matches:
                if len(self.pending) > 2:
                    del self.pending[:-2]
                break
            index, event, size = min(matches, key=lambda item: item[0])
            events.append(event)
            del self.pending[: index + size]
        return events


def atomic_write(path: Path, value: str) -> None:
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(value + "\n", encoding="utf-8")
    os.replace(temporary, path)


def increment_counter(path: Path) -> int:
    try:
        current = int(path.read_text(encoding="utf-8").strip())
    except (FileNotFoundError, ValueError):
        current = 0
    updated = current + 1
    atomic_write(path, str(updated))
    return updated


def log_line(path: Path, message: str) -> None:
    with path.open("a", encoding="utf-8") as log:
        log.write(f"{time.monotonic():.6f} {message}\n")


def run_probe(
    ready_file: Path,
    release_file: Path,
    done_file: Path,
    focus_lost_file: Path,
    focus_gained_file: Path,
    log_file: Path,
) -> int:
    fd = sys.stdin.fileno()
    original_attributes: list[object] | None = None
    tracking_enabled = False
    error: str | None = None
    decoder = FocusSequenceDecoder()

    for counter_file in (focus_lost_file, focus_gained_file):
        atomic_write(counter_file, "0")
    for marker in (ready_file, done_file):
        marker.unlink(missing_ok=True)

    try:
        if not os.isatty(fd):
            raise RuntimeError("stdin is not Terminal.app's foreground TTY")
        original_attributes = termios.tcgetattr(fd)
        tty.setraw(fd, termios.TCSANOW)
        os.write(fd, FOCUS_REPORTING_ENABLE)
        tracking_enabled = True
        atomic_write(ready_file, "1")
        log_line(log_file, "probe ready; requested DECSET 1004 on the actual Terminal.app TTY")

        while not release_file.exists():
            try:
                readable, _, _ = select.select([fd], [], [], 0.1)
            except InterruptedError:
                continue
            if not readable:
                continue
            chunk = os.read(fd, 4096)
            if not chunk:
                raise RuntimeError("Terminal.app TTY reached EOF during raw focus observation")
            log_line(log_file, f"tty input hex={chunk.hex()}")
            for event in decoder.feed(chunk):
                target = focus_lost_file if event == "focus_lost" else focus_gained_file
                count = increment_counter(target)
                log_line(log_file, f"native {event} count={count}")

        log_line(
            log_file,
            "probe released; "
            f"FocusLost={focus_lost_file.read_text().strip()} "
            f"FocusGained={focus_gained_file.read_text().strip()}",
        )
    except Exception as exc:
        error = f"{type(exc).__name__}: {exc}"
        log_line(log_file, f"ERROR {error}")
    finally:
        if tracking_enabled:
            try:
                os.write(fd, FOCUS_REPORTING_DISABLE)
            except OSError as exc:
                log_line(log_file, f"ERROR sending DECSET 1004 disable: {exc}")
                error = error or f"could not disable focus reporting: {exc}"
        if original_attributes is not None:
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, original_attributes)
            except termios.error as exc:
                log_line(log_file, f"ERROR restoring terminal attributes: {exc}")
                error = error or f"could not restore terminal attributes: {exc}"
        atomic_write(done_file, "error" if error else "ok")

    if error:
        print(f"Terminal.app raw focus probe failed: {error}", file=sys.stderr)
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("ready_file", type=Path)
    parser.add_argument("release_file", type=Path)
    parser.add_argument("done_file", type=Path)
    parser.add_argument("focus_lost_file", type=Path)
    parser.add_argument("focus_gained_file", type=Path)
    parser.add_argument("log_file", type=Path)
    args = parser.parse_args()
    return run_probe(
        args.ready_file,
        args.release_file,
        args.done_file,
        args.focus_lost_file,
        args.focus_gained_file,
        args.log_file,
    )


if __name__ == "__main__":
    raise SystemExit(main())
