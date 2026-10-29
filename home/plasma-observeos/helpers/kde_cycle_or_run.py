#!/usr/bin/env python3
"""KDE-aware cycle-or-run / spawn helpers. no swaymsg, no live profile activation."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Any, Callable, Protocol


@dataclass
class Window:
    window_id: str
    class_name: str = ""
    app_id: str = ""
    instance: str = ""
    name: str = ""
    desktop: str = ""
    focused: bool = False


@dataclass
class Action:
    kind: str  # focus | launch | none
    window_id: str | None = None
    launch: list[str] = field(default_factory=list)
    reason: str = ""


class WindowBackend(Protocol):
    def list_windows(self) -> list[Window]: ...
    def current_desktop(self) -> str | None: ...
    def focus(self, window_id: str) -> None: ...
    def launch(self, argv: list[str]) -> None: ...


class FakeBackend:
    def __init__(self, windows: list[Window], desktop: str | None = "1"):
        self.windows = windows
        self.desktop = desktop
        self.focused: str | None = next((w.window_id for w in windows if w.focused), None)
        self.launched: list[list[str]] = []

    def list_windows(self) -> list[Window]:
        return list(self.windows)

    def current_desktop(self) -> str | None:
        return self.desktop

    def focus(self, window_id: str) -> None:
        self.focused = window_id
        for win in self.windows:
            win.focused = win.window_id == window_id

    def launch(self, argv: list[str]) -> None:
        self.launched.append(list(argv))


def matches(win: Window, term: str) -> bool:
    t = term.lower()
    return any(t in (getattr(win, k) or "").lower() for k in ("class_name", "instance", "app_id", "name"))


def ordered_candidates(windows: list[Window], term: str | None, scope: str, current_desktop: str | None) -> list[Window]:
    out: list[Window] = []
    for win in windows:
        if scope == "current" and current_desktop is not None and win.desktop != current_desktop:
            continue
        if term is not None and not matches(win, term):
            continue
        out.append(win)
    return out


def cycle_candidates(candidates: list[Window], reverse: bool) -> Window | None:
    if not candidates:
        return None
    active_idx = next((i for i, w in enumerate(candidates) if w.focused), -1)
    if active_idx < 0:
        return candidates[-1 if reverse else 0]
    step = -1 if reverse else 1
    return candidates[(active_idx + step) % len(candidates)]


def plan_cycle_or_run(
    windows: list[Window],
    *,
    class_match: str,
    scope: str,
    current_desktop: str | None,
    reverse: bool,
    launch: list[str],
) -> Action:
    if not launch:
        raise ValueError("cycle-or-run needs launch argv")
    candidates = ordered_candidates(windows, class_match, scope, current_desktop)
    if candidates:
        target = cycle_candidates(candidates, reverse)
        assert target is not None
        return Action(kind="focus", window_id=target.window_id, reason="existing match on scope")
    return Action(kind="launch", launch=list(launch), reason="no match; launch")


def plan_spawn(launch: list[str]) -> Action:
    if not launch:
        raise ValueError("spawn needs launch argv")
    return Action(
        kind="launch",
        launch=list(launch),
        reason="always launch new; local tree insertion is owned by tiling (blocked_by_tiling)",
    )


def execute(action: Action, backend: WindowBackend) -> int:
    if action.kind == "focus":
        assert action.window_id is not None
        backend.focus(action.window_id)
        return 0
    if action.kind == "launch":
        backend.launch(action.launch)
        return 0
    return 0


def _kdotool(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["kdotool", *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


class KdotoolBackend:
    """optional live backend. tests must not require this. never talks to sway."""

    def list_windows(self) -> list[Window]:
        proc = _kdotool("search")
        if proc.returncode != 0:
            raise RuntimeError(proc.stderr.strip() or "kdotool search failed")
        ids = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
        active = self._active_id()
        desktop = self.current_desktop()
        windows: list[Window] = []
        for window_id in ids:
            class_name = (_kdotool("getwindowclassname", window_id).stdout or "").strip()
            name = (_kdotool("getwindowname", window_id).stdout or "").strip()
            wdesk = (_kdotool("getwindowdesktop", window_id).stdout or "").strip() or desktop or ""
            windows.append(
                Window(
                    window_id=window_id,
                    class_name=class_name,
                    name=name,
                    desktop=wdesk,
                    focused=window_id == active,
                )
            )
        return windows

    def _active_id(self) -> str | None:
        proc = _kdotool("getactivewindow")
        if proc.returncode != 0:
            return None
        return proc.stdout.strip() or None

    def current_desktop(self) -> str | None:
        proc = _kdotool("getactivedesktop")
        if proc.returncode != 0:
            return None
        return proc.stdout.strip() or None

    def focus(self, window_id: str) -> None:
        proc = _kdotool("windowactivate", window_id)
        if proc.returncode != 0:
            raise RuntimeError(proc.stderr.strip() or f"kdotool windowactivate {window_id} failed")

    def launch(self, argv: list[str]) -> None:
        subprocess.Popen(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


APP_LAUNCH = {
    "terminal": ["kitty-shade"],
    "kitty": ["kitty-shade"],
    "firefox": ["firefox-session", "--new-window"],
    "code": ["code", "-n"],
    "thunar": ["thunar"],
}


def _backend_from_env() -> WindowBackend:
    raw = os.environ.get("OBSERVEOS_KDE_WINDOWS_JSON")
    if raw:
        payload = json.loads(raw)
        windows = [Window(**item) for item in payload.get("windows", [])]
        return FakeBackend(windows, payload.get("desktop", "1"))
    path = os.environ.get("OBSERVEOS_KDE_WINDOWS_FILE")
    if path:
        payload = json.loads(PathRead(path))
        windows = [Window(**item) for item in payload.get("windows", [])]
        return FakeBackend(windows, payload.get("desktop", "1"))
    if shutil.which("kdotool"):
        return KdotoolBackend()
    raise RuntimeError("no window backend: set OBSERVEOS_KDE_WINDOWS_JSON/FILE for tests, or install kdotool")


def PathRead(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="kde-cycle-or-run")
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("cycle-or-run")
    c.add_argument("--class", dest="class_match", required=True)
    c.add_argument("--scope", choices=["current", "any"], default="current")
    c.add_argument("--reverse", action="store_true")
    c.add_argument("--launch", nargs=argparse.REMAINDER, required=True)
    c.add_argument("--dry-run", action="store_true")

    c = sub.add_parser("spawn")
    c.add_argument("--app", help="terminal|firefox|code|thunar")
    c.add_argument("--launch", nargs=argparse.REMAINDER)
    c.add_argument("--dry-run", action="store_true")

    c = sub.add_parser("cycle-focused")
    c.add_argument("--scope", choices=["current", "any"], default="current")
    c.add_argument("--reverse", action="store_true")
    c.add_argument("--dry-run", action="store_true")

    c = sub.add_parser("send-and-follow")
    c.add_argument("desktop")
    c.add_argument("--dry-run", action="store_true")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.cmd == "spawn":
        launch = list(args.launch or [])
        if launch[:1] == ["--"]:
            launch = launch[1:]
        if args.app:
            launch = APP_LAUNCH[args.app] if not launch else launch
        action = plan_spawn(launch)
        if args.dry_run:
            json.dump(action.__dict__, sys.stdout)
            sys.stdout.write("\n")
            return 0
        backend = _backend_from_env()
        return execute(action, backend)

    backend: WindowBackend | None = None
    if not args.dry_run:
        backend = _backend_from_env()
        windows = backend.list_windows()
        desktop = backend.current_desktop()
    else:
        windows = []
        desktop = None
        raw = os.environ.get("OBSERVEOS_KDE_WINDOWS_JSON")
        if raw:
            payload = json.loads(raw)
            windows = [Window(**item) for item in payload.get("windows", [])]
            desktop = payload.get("desktop", "1")

    if args.cmd == "cycle-or-run":
        launch = list(args.launch)
        if launch[:1] == ["--"]:
            launch = launch[1:]
        action = plan_cycle_or_run(
            windows,
            class_match=args.class_match,
            scope=args.scope,
            current_desktop=desktop,
            reverse=args.reverse,
            launch=launch,
        )
        if args.dry_run:
            json.dump(action.__dict__, sys.stdout)
            sys.stdout.write("\n")
            return 0
        assert backend is not None
        return execute(action, backend)

    if args.cmd == "cycle-focused":
        candidates = ordered_candidates(windows, None, args.scope, desktop)
        target = cycle_candidates(candidates, args.reverse)
        action = Action(kind="focus", window_id=target.window_id) if target else Action(kind="none")
        if args.dry_run:
            json.dump(action.__dict__, sys.stdout)
            sys.stdout.write("\n")
            return 0
        assert backend is not None
        return execute(action, backend)

    if args.cmd == "send-and-follow":
        payload = {"kind": "send-and-follow", "desktop": args.desktop, "status": "static-only"}
        json.dump(payload, sys.stdout)
        sys.stdout.write("\n")
        return 0 if args.dry_run else 0

    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001 — CLI boundary
        print(f"kde-cycle-or-run: {exc}", file=sys.stderr)
        raise SystemExit(1)
