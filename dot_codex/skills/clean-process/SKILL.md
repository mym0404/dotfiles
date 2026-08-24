---
name: clean-process
description: Clean stale macOS automation, local development, and resource-heavy build processes with a guarded two-pass script.
---

# Clean Process

Use the bundled classifier and cleaner. Its candidate set is the safety boundary.

## Workflow

1. Run `uname -s` and locate the bundled script. Continue only on macOS with an executable Python runtime; otherwise report the failed precondition.
2. List candidates before mutation:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/clean-process/scripts/clean_process_macos.py" list
```

Complete inspection when the candidate PIDs and reasons are visible.
The list is sorted by CPU descending, then resident memory descending. By default, build processes running for at least 120 seconds become candidates when CPU is at least 20% or resident memory is at least 1024 MB.

3. Run the graceful cleanup immediately:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/clean-process/scripts/clean_process_macos.py" clean --yes
```

4. List candidates again. When classified leftovers remain, run one forced pass on that remaining set:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/clean-process/scripts/clean_process_macos.py" clean --yes --force
```

5. Run a final list and report the discovered, terminated, and remaining PIDs. Complete only when the classifier returns no candidates or an exact process and failure reason are reported.

## Safety Contract

- Preserve the current Codex process tree and unrelated user processes.
- Target Chrome, Chromium, Node.js, and Python only when the script ties them to supported automation ancestry, automation profiles, or configured development ports.
- Target build processes only when they exceed the configured CPU or resident-memory threshold and meet the age or orphan condition.
- Use graceful termination before the forced pass.
- Apply user-supplied `--include-pattern`, `--dev-port`, `--cpu-threshold`, `--memory-threshold-mb`, or `--min-age-seconds` filters consistently to list and clean commands.
- Treat a specific PID or narrower user request as an additional filter on the classifier.
