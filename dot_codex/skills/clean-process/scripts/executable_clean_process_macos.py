#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import time
from dataclasses import dataclass


AUTOMATION_MARKERS = [
    "playwright",
    "ms-playwright",
    "puppeteer",
    "cypress",
    "selenium",
    "chromedriver",
    "geckodriver",
    "webdriver",
    "browser-use",
    "browser_use",
    "agent-browser",
    "headless",
    "--remote-debugging-pipe",
    "--remote-debugging-port",
    "--test-type",
    "--enable-automation",
    "--user-data-dir=/var/folders/",
    "--user-data-dir=/tmp/",
    "/playwright/",
    "headlesschrome",
]

TARGET_MARKERS = [
    "playwright",
    "node",
    "python",
    "python3",
    "electron",
]

BUILD_PROCESS_NAMES = {
    "actool",
    "cargo",
    "clang",
    "clang++",
    "ibtool",
    "ld",
    "make",
    "metal",
    "ninja",
    "rustc",
    "swift-frontend",
    "swiftc",
    "xcodebuild",
}

BROWSER_PROCESS_MARKERS = [
    "google chrome",
    "chrome helper",
    "chromium",
    "chromium helper",
    "headlesschrome",
]

APPROVED_BROWSER_TOOL_MARKERS = [
    "playwright",
    "ms-playwright",
    "browser-use",
    "browser_use",
    "agent-browser",
]

APPROVED_BROWSER_SESSION_MARKERS = [
    "browser-use-user-data-dir",
    "browseruse/extensions",
    "ms-playwright",
    "/playwright/",
    "playwright_",
    "playwright-",
    "playwright_chromiumdev_profile",
    "agent-browser",
]

SAFE_NAME_MARKERS = [
    "codex",
    "cursor",
    "visual studio code",
    "vscode",
    "warp",
    "iterm",
    "terminal",
]

COMMON_DEV_SERVER_PORTS = {
    3000,
    3001,
    3002,
    3003,
    4173,
    4200,
    4321,
    5000,
    5173,
    5174,
    8000,
    8080,
    8787,
    9000,
}

DEV_SERVER_MARKERS = [
    "next dev",
    "/next/dist/bin/next",
    "vite",
    "nuxt dev",
    "nuxi dev",
    "astro dev",
    "@astrojs",
    "remix dev",
    "react-scripts start",
    "webpack serve",
    "webpack-dev-server",
    "parcel",
    "rsbuild dev",
    "rspack dev",
    "expo start",
    "svelte-kit dev",
    "storybook dev",
]

DEV_SERVER_WRAPPER_MARKERS = [
    "pnpm dev",
    "pnpm run dev",
    "npm run dev",
    "npm dev",
    "yarn dev",
    "bun dev",
    "turbo run dev",
    "nx serve",
]

DEV_SERVER_RUNTIME_MARKERS = [
    "node",
    "bun",
    "deno",
    "python",
    "python3",
    "ruby",
]


@dataclass
class ProcessInfo:
    pid: int
    ppid: int
    cpu: float
    memory_mb: float
    elapsed_seconds: int
    state: str
    command: str
    args: str

    def to_dict(self) -> dict[str, object]:
        return {
            "pid": self.pid,
            "ppid": self.ppid,
            "cpu": self.cpu,
            "memory_mb": self.memory_mb,
            "elapsed_seconds": self.elapsed_seconds,
            "state": self.state,
            "command": self.command,
            "args": self.args,
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Safely inspect and clean stale automation, local dev-server, and resource-heavy build processes on macOS."
    )
    subparsers = parser.add_subparsers(dest="action", required=True)

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--cpu-threshold", type=float, default=20.0)
    common.add_argument("--memory-threshold-mb", type=float, default=1024.0)
    common.add_argument("--min-age-seconds", type=int, default=120)
    common.add_argument("--include-pattern", action="append", default=[])
    common.add_argument("--dev-port", action="append", type=int, default=[])
    common.add_argument("--json", action="store_true")

    subparsers.add_parser("list", parents=[common])

    clean = subparsers.add_parser("clean", parents=[common])
    clean.add_argument("--yes", action="store_true")
    clean.add_argument("--force", action="store_true")
    clean.add_argument("--grace-seconds", type=float, default=3.0)

    return parser.parse_args()


def run_ps() -> list[ProcessInfo]:
    result = subprocess.run(
        [
            "ps",
            "-axo",
            "pid=,ppid=,%cpu=,rss=,etime=,state=,comm=,args=",
        ],
        check=True,
        capture_output=True,
        text=True,
    )

    processes: list[ProcessInfo] = []

    for raw_line in result.stdout.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        parts = line.split(None, 7)
        if len(parts) < 8:
            continue

        pid_text, ppid_text, cpu_text, rss_text, etime_text, state, command, args = parts

        try:
            processes.append(
                ProcessInfo(
                    pid=int(pid_text),
                    ppid=int(ppid_text),
                    cpu=float(cpu_text),
                    memory_mb=int(rss_text) / 1024,
                    elapsed_seconds=parse_etime(etime_text),
                    state=state,
                    command=command,
                    args=args,
                )
            )
        except ValueError:
            continue

    return processes


def parse_etime(value: str) -> int:
    days = 0
    time_text = value

    if "-" in value:
        day_text, time_text = value.split("-", 1)
        days = int(day_text)

    chunks = [int(chunk) for chunk in time_text.split(":")]

    if len(chunks) == 3:
        hours, minutes, seconds = chunks
    elif len(chunks) == 2:
        hours = 0
        minutes, seconds = chunks
    else:
        hours = 0
        minutes = 0
        seconds = chunks[0]

    return days * 86400 + hours * 3600 + minutes * 60 + seconds


def lowercase_text(parts: list[str]) -> str:
    return " ".join(parts).lower()


def get_excluded_pids(processes: list[ProcessInfo]) -> set[int]:
    process_by_pid = {process.pid: process for process in processes}
    excluded: set[int] = set()

    current = os.getpid()
    while current and current not in excluded:
        excluded.add(current)
        process = process_by_pid.get(current)
        if process is None or process.ppid == current:
            break
        current = process.ppid

    return excluded


def get_listening_tcp_ports() -> dict[int, set[int]]:
    try:
        result = subprocess.run(
            ["lsof", "-nP", "-iTCP", "-sTCP:LISTEN", "-Fpn"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return {}

    listening_ports_by_pid: dict[int, set[int]] = {}
    current_pid: int | None = None

    for raw_line in result.stdout.splitlines():
        if not raw_line:
            continue

        field = raw_line[0]
        value = raw_line[1:]

        if field == "p":
            try:
                current_pid = int(value)
            except ValueError:
                current_pid = None
                continue
            listening_ports_by_pid.setdefault(current_pid, set())
            continue

        if field != "n" or current_pid is None:
            continue

        match = re.search(r":(\d+)(?:->|$)", value)
        if match is None:
            continue

        listening_ports_by_pid[current_pid].add(int(match.group(1)))

    return listening_ports_by_pid


def matches_any_marker(text: str, markers: list[str]) -> bool:
    return any(marker in text for marker in markers)


def get_lineage_texts(
    process: ProcessInfo, process_by_pid: dict[int, ProcessInfo], max_depth: int = 8
) -> list[str]:
    lineage: list[str] = []
    seen: set[int] = set()
    current_pid = process.ppid

    while current_pid and current_pid not in seen and len(lineage) < max_depth:
        seen.add(current_pid)
        current = process_by_pid.get(current_pid)
        if current is None:
            break
        lineage.append(lowercase_text([current.command, current.args]))
        if current.ppid == current.pid:
            break
        current_pid = current.ppid

    return lineage


def get_dev_server_reason_by_pid(
    *,
    processes: list[ProcessInfo],
    process_by_pid: dict[int, ProcessInfo],
    listening_ports_by_pid: dict[int, set[int]],
    dev_ports: set[int],
) -> dict[int, list[str]]:
    reasons_by_pid: dict[int, set[str]] = {}

    for process in processes:
        listening_ports = sorted(listening_ports_by_pid.get(process.pid, set()) & dev_ports)
        if not listening_ports:
            continue

        lowered = lowercase_text([process.command, process.args])
        lineage_texts = get_lineage_texts(process, process_by_pid)
        has_direct_dev_marker = matches_any_marker(lowered, DEV_SERVER_MARKERS)
        has_wrapper_in_lineage = any(
            matches_any_marker(text, DEV_SERVER_WRAPPER_MARKERS) for text in lineage_texts
        )
        has_runtime_marker = matches_any_marker(lowered, DEV_SERVER_RUNTIME_MARKERS)

        if not has_direct_dev_marker and not (has_wrapper_in_lineage and has_runtime_marker):
            continue

        port_reason = ",".join(str(port) for port in listening_ports)
        listener_reasons = reasons_by_pid.setdefault(process.pid, set())
        listener_reasons.add(f"dev-port:{port_reason}")
        listener_reasons.add("dev-server-listener")

        current_pid = process.ppid
        depth = 0
        while current_pid and depth < 6:
            current = process_by_pid.get(current_pid)
            if current is None:
                break

            current_text = lowercase_text([current.command, current.args])
            if matches_any_marker(current_text, SAFE_NAME_MARKERS):
                break

            if matches_any_marker(current_text, DEV_SERVER_WRAPPER_MARKERS):
                wrapper_reasons = reasons_by_pid.setdefault(current.pid, set())
                wrapper_reasons.add(f"dev-server-wrapper:{port_reason}")

            if current.ppid == current.pid:
                break

            current_pid = current.ppid
            depth += 1

    return {pid: sorted(reasons) for pid, reasons in reasons_by_pid.items()}


def get_browser_automation_reason(
    process: ProcessInfo, process_by_pid: dict[int, ProcessInfo]
) -> str | None:
    lowered = lowercase_text([process.command, process.args])
    executable_prefix = process.args.partition(" --")[0] if process.args else ""
    browser_identity = lowercase_text([process.command, executable_prefix])

    if not matches_any_marker(browser_identity, BROWSER_PROCESS_MARKERS):
        return None

    lineage_texts = get_lineage_texts(process, process_by_pid)

    if matches_any_marker(lowered, APPROVED_BROWSER_SESSION_MARKERS):
        return "automation-browser-session"

    if matches_any_marker(lowered, APPROVED_BROWSER_TOOL_MARKERS):
        return "automation-browser-marker"

    if any(matches_any_marker(text, APPROVED_BROWSER_TOOL_MARKERS) for text in lineage_texts):
        return "automation-browser-parent"

    return None


def build_candidate_list(
    *,
    processes: list[ProcessInfo],
    cpu_threshold: float,
    memory_threshold_mb: float,
    min_age_seconds: int,
    include_patterns: list[str],
    dev_ports: list[int],
) -> list[dict[str, object]]:
    process_by_pid = {process.pid: process for process in processes}
    children_by_ppid: dict[int, list[ProcessInfo]] = {}
    listening_ports_by_pid = get_listening_tcp_ports()

    for process in processes:
        children_by_ppid.setdefault(process.ppid, []).append(process)

    excluded_pids = get_excluded_pids(processes)
    include_markers = [pattern.lower() for pattern in include_patterns]
    effective_dev_ports = set(dev_ports or COMMON_DEV_SERVER_PORTS)
    dev_server_reason_by_pid = get_dev_server_reason_by_pid(
        processes=processes,
        process_by_pid=process_by_pid,
        listening_ports_by_pid=listening_ports_by_pid,
        dev_ports=effective_dev_ports,
    )

    def describe(process: ProcessInfo) -> tuple[bool, list[str]]:
        lowered = lowercase_text([process.command, process.args])
        process_names = {
            os.path.basename(process.command).lower(),
            os.path.basename(process.args.split(None, 1)[0]).lower() if process.args else "",
        }
        is_build_process = not process_names.isdisjoint(BUILD_PROCESS_NAMES)
        browser_automation_reason = get_browser_automation_reason(process, process_by_pid)
        dev_server_reasons = dev_server_reason_by_pid.get(process.pid, [])

        if process.pid in excluded_pids:
            return False, []

        if matches_any_marker(lowered, SAFE_NAME_MARKERS):
            return False, []

        is_target = (
            matches_any_marker(lowered, TARGET_MARKERS)
            or is_build_process
            or matches_any_marker(lowered, include_markers)
            or browser_automation_reason is not None
            or bool(dev_server_reasons)
        )
        if not is_target:
            return False, []

        reasons: list[str] = []

        if process.cpu >= cpu_threshold:
            reasons.append(f"cpu>={cpu_threshold:g}")

        if process.memory_mb >= memory_threshold_mb:
            reasons.append(f"memory>={memory_threshold_mb:g}MB")

        if process.elapsed_seconds >= min_age_seconds:
            reasons.append(f"age>={min_age_seconds}s")

        if is_build_process:
            reasons.append("build-process")

        has_automation_marker = matches_any_marker(lowered, AUTOMATION_MARKERS)
        if has_automation_marker:
            reasons.append("automation-marker")

        if browser_automation_reason is not None:
            reasons.append(browser_automation_reason)

        reasons.extend(dev_server_reasons)

        parent = process_by_pid.get(process.ppid)
        if parent is None or process.ppid == 1:
            reasons.append("orphaned")
        elif matches_any_marker(lowercase_text([parent.command, parent.args]), AUTOMATION_MARKERS):
            reasons.append("automation-child")

        if (
            not has_automation_marker
            and not dev_server_reasons
            and process.cpu < cpu_threshold
            and process.memory_mb < memory_threshold_mb
        ):
            return False, []

        if (
            process.elapsed_seconds < min_age_seconds
            and "orphaned" not in reasons
            and not dev_server_reasons
        ):
            return False, []

        if len(reasons) < 2 and "automation-marker" not in reasons and not dev_server_reasons:
            return False, []

        return True, reasons

    candidates: list[dict[str, object]] = []

    for process in processes:
        is_candidate, reasons = describe(process)
        if not is_candidate:
            continue

        children = children_by_ppid.get(process.pid, [])
        child_pids = [child.pid for child in children if child.pid not in excluded_pids]

        candidates.append(
            {
                "process": process,
                "reasons": sorted(set(reasons)),
                "child_pids": child_pids,
            }
        )

    return sorted(
        candidates,
        key=lambda item: (
            -item["process"].cpu,
            -item["process"].memory_mb,
            -item["process"].elapsed_seconds,
            item["process"].pid,
        ),
    )


def print_candidates(candidates: list[dict[str, object]], as_json: bool) -> None:
    if as_json:
        payload = [
            {
                **item["process"].to_dict(),
                "reasons": item["reasons"],
                "child_pids": item["child_pids"],
            }
            for item in candidates
        ]
        print(json.dumps(payload, indent=2))
        return

    if not candidates:
        print("No matching automation, dev-server, or resource-heavy build processes found.")
        return

    print("PID\tPPID\tCPU\tMEM(MB)\tAGE(s)\tREASONS\tCOMMAND")
    for item in candidates:
        process: ProcessInfo = item["process"]
        reasons = ",".join(item["reasons"])
        print(
            f"{process.pid}\t{process.ppid}\t{process.cpu:.1f}\t{process.memory_mb:.1f}\t{process.elapsed_seconds}\t{reasons}\t{process.args}"
        )


def terminate_candidates(
    *,
    candidates: list[dict[str, object]],
    grace_seconds: float,
    force: bool,
) -> dict[str, list[int]]:
    killed_with_term: list[int] = []
    killed_with_kill: list[int] = []
    remaining: list[int] = []

    for item in candidates:
        send_signal(item["process"].pid, signal.SIGTERM, killed_with_term)

    time.sleep(max(grace_seconds, 0))

    for item in candidates:
        pid = item["process"].pid
        if is_alive(pid):
            remaining.append(pid)

    if force and remaining:
        still_running: list[int] = []
        for pid in remaining:
            send_signal(pid, signal.SIGKILL, killed_with_kill)
        time.sleep(0.5)
        for pid in remaining:
            if is_alive(pid):
                still_running.append(pid)
        remaining = still_running

    return {
        "term": killed_with_term,
        "kill": killed_with_kill,
        "remaining": remaining,
    }


def send_signal(pid: int, sig: signal.Signals, sink: list[int]) -> None:
    try:
        os.kill(pid, sig)
        sink.append(pid)
    except ProcessLookupError:
        return
    except PermissionError:
        return


def is_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def ensure_macos() -> None:
    if sys.platform != "darwin":
        raise SystemExit("This script only supports macOS.")


def main() -> None:
    ensure_macos()
    args = parse_args()
    processes = run_ps()
    candidates = build_candidate_list(
        processes=processes,
        cpu_threshold=args.cpu_threshold,
        memory_threshold_mb=args.memory_threshold_mb,
        min_age_seconds=args.min_age_seconds,
        include_patterns=args.include_pattern,
        dev_ports=args.dev_port,
    )

    if args.action == "list":
        print_candidates(candidates, args.json)
        return

    if not args.yes:
        raise SystemExit("Refusing to terminate processes without --yes.")

    if args.json:
        payload = {
            "candidates": [
                {
                    **item["process"].to_dict(),
                    "reasons": item["reasons"],
                    "child_pids": item["child_pids"],
                }
                for item in candidates
            ]
        }
    else:
        print_candidates(candidates, args.json)

    if not candidates:
        if args.json:
            payload["summary"] = {"term": [], "kill": [], "remaining": []}
            print(json.dumps(payload, indent=2))
        return

    summary = terminate_candidates(
        candidates=candidates,
        grace_seconds=args.grace_seconds,
        force=args.force,
    )

    if args.json:
        payload["summary"] = summary
        print(json.dumps(payload, indent=2))
        return

    print("")
    print(f"SIGTERM sent: {summary['term']}")
    if args.force:
        print(f"SIGKILL sent: {summary['kill']}")
    print(f"Still running: {summary['remaining']}")


if __name__ == "__main__":
    main()
