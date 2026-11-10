---
name: clean-process
description: Clean stale macOS automation, idle duplicate XcodeBuildMCP servers, local development, and resource-heavy build processes with a guarded two-pass script.
---

# Clean Process

Use the bundled classifier and cleaner. Its candidate set is the safety boundary.
For inspection-only requests or edits to this skill, do not run cleanup.

## Workflow

1. Run `uname -s` and locate the bundled script. Continue only on macOS with an executable Python runtime; otherwise report the failed precondition.
2. List candidates before mutation:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/clean-process/scripts/clean_process_macos.py" list
```

Complete inspection when the candidate PIDs and reasons are visible.
The list is sorted by CPU descending, then resident memory descending. By default, build processes running for at least 120 seconds become candidates when CPU is at least 20% or resident memory is at least 1024 MB.
Idle duplicate XcodeBuildMCP groups use the rules below instead of the CPU and memory thresholds.

3. Run the graceful cleanup immediately:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/clean-process/scripts/clean_process_macos.py" clean --yes
```

4. List candidates again. When classified leftovers remain, run one forced pass on that remaining set:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/clean-process/scripts/clean_process_macos.py" clean --yes --force
```

5. Run a final list and report the discovered, terminated, and remaining PIDs. Complete only when the classifier returns no candidates or an exact process and failure reason are reported.
Verify any previously reported remaining PIDs even if their classification changes after a parent exits. Report summed process RSS as an estimate of the terminated processes' footprint, not as measured memory reclaimed.

## Duplicate Tool Servers

- Recognize XcodeBuildMCP's `mcp` server and its direct `npm exec` or `npx` wrapper. Group servers only when they share the same Codex host PID and exact server entry path; do not combine versions or other users' launchers.
- Retain the newest server in each group. Older groups qualify only when every member is at least `--min-age-seconds` old, sleeping at 0% CPU, and has no children other than its server/wrapper pair. Low CPU alone does not establish a duplicate.
- List both wrapper and server PIDs with `duplicate-xcodebuildmcp` and the retained server PID. Keep singleton groups and groups with active or unrecognized children.
- Protect active `agent-device`/AgentDeviceRunner branches and build workers beneath tool servers. Do not terminate the current screenshot job, its simulator services, user applications, or OS UI services to reduce load.

## Safety Contract

- Preserve the cleanup command's ancestry, Codex host processes, active tool workers, and unrelated user processes. Sibling tool servers are eligible only under the duplicate rules above.
- Target Chrome, Chromium, Node.js, and Python only when the script ties them to supported automation ancestry, automation profiles, or configured development ports.
- Target build processes only when they exceed the configured CPU or resident-memory threshold and meet the age or orphan condition.
- Use graceful termination before the forced pass.
- Apply user-supplied `--include-pattern`, `--dev-port`, `--cpu-threshold`, `--memory-threshold-mb`, or `--min-age-seconds` filters consistently to list and clean commands.
- Treat a specific PID or narrower user request as an additional filter on the classifier.
