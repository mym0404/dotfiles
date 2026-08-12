---
name: clean-process
description: Clean stale macOS automation and local development processes with a guarded two-pass script.
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
- Use graceful termination before the forced pass.
- Apply user-supplied `--include-pattern`, `--dev-port`, `--cpu-threshold`, or `--min-age-seconds` filters consistently to list and clean commands.
- Treat a specific PID or narrower user request as an additional filter on the classifier.
