---
name: zx-script
description: Create a project-native ZX TypeScript script using the runtime and module format that fit the existing environment, keeping only the helpers its current operation needs.
---

# ZX Script

Usage: `$zx-script <filename> <operation>`

## Workflow

1. Inspect `package.json`, toolchain configuration, existing scripts, and `tools/`, `scripts/`, `bin/`, and `utils/` before choosing an execution method. Identify the installed runtime and version, TypeScript execution support, module settings, script directory, and naming convention. Prefer the method that fits the existing project environment; verify it with a small safe invocation when support is unclear.
2. Resolve only result-changing details the operation leaves open: inputs, outputs, destructive effects, and integration entrypoint. Prefer safe defaults when the repository already establishes them.
3. Use `<filename>.ts` when the existing environment can run it directly with the required module behavior. Otherwise use `<filename>.mts` to make ESM explicit. The `.mts` extension does not add TypeScript execution support: if the runtime cannot execute TypeScript directly, use the project's existing TypeScript runner. Create the file in the existing script directory or `scripts/` when none exists. Start from the smallest fitting shape:

```ts
import { $ } from "zx";

const main = async () => {
  // Implement the requested operation.
};

await main();
```

Use only the imports and helpers the operation needs. Add a shebang only when the project uses direct script invocation, matching the selected runtime. Use the bundled utilities below first. Read [utility-foundation.md](references/utility-foundation.md) only when additional filesystem, JSON, console, assertion, or interactive-input helpers are needed; copy only pieces not already covered by ZX. Follow the repository's quote, module, and error-handling style. Keep external input typed and validate it at the boundary.

4. Add a `package.json` entry only when the user requests one or the repository exposes comparable scripts there. Use the selected runtime or existing TypeScript runner with the chosen file extension.
5. Run the repository formatter or type checker for the file, then exercise the smallest safe representative invocation. Complete when the requested operation works, failure output is actionable, and no unused template code remains.

## Implementation Contract

- Prefer ZX and runtime primitives already available in the project. Do not introduce a runtime merely to follow a template.
- Keep one-off values inline and extract helpers only when reused or when they isolate complex logic.
- Use arrow functions, inferred types, and concrete boundary validation.
- Preserve unrelated files and package scripts.
- Keep destructive operations behind an explicit user choice or a dry-run preview when practical.

Report the created path, invocation, and verification result.

## Bundled Utilities and Imports

Actively use ZX's bundled utilities whenever they fit the operation. Import them directly from `"zx"` instead of adding the same libraries as separate dependencies or writing equivalent helpers. For example, use `argv` for ordinary CLI arguments, `chalk` for colors, `fs.readJson` / `fs.outputJson` for JSON files, `fs.ensureDir` for directories, and `glob` for file matching. Import only what the script uses.

Check the installed ZX version and its public exports before choosing APIs. The inventory below combines the [official API reference](https://google.github.io/zx/api) with the public entrypoint and declarations; availability can differ by version. In particular, `MAML` appears in the current upstream entrypoint but is absent from ZX 8.8.5. Do not assume that every transitive dependency or internal helper is exported from `"zx"`.

```ts
import { $, argv, chalk, echo, fs, glob, path } from "zx";
```

### Bundled Modules

| Import from `"zx"` | Use |
| --- | --- |
| `argv` | Parsed command-line flags and positional arguments (`argv._`). |
| `minimist` | Argument parsing with explicit boolean, string, alias, and default options. |
| `chalk` | Terminal text colors and styles. |
| `fs` | `fs-extra`: filesystem operations plus `readJson`, `outputJson`, `ensureDir`, `copy`, `remove`, and `pathExists`. |
| `path` | Node path operations such as `join`, `resolve`, and `dirname`. |
| `os` | Node operating-system information and paths. |
| `glob`, `globby` | File-pattern matching; aliases for the same bundled utility, including `glob.sync`. |
| `YAML` | YAML parsing and serialization. |
| `MAML` | MAML parsing and serialization, when exported by the installed version. |
| `dotenv` | Parse, serialize, load, or apply environment-file values; check the installed API signatures. |
| `which` | Locate an executable. |
| `ps` | Process lookup and process-tree inspection. |
| `versions` | ZX and bundled dependency versions. |

### Script Helpers

| Import from `"zx"` | Use |
| --- | --- |
| `$` | Shell commands with escaped interpolations; supports `.sync`, timeouts, abort signals, and pipes. |
| `ProcessPromise`, `ProcessOutput` | Command execution and result classes; use their types when needed. |
| `parseArgv`, `updateArgv` | Parse arguments with ZX options, or update the shared `argv` object. |
| `echo` | Print values or command output. |
| `question` | Read interactive input, with optional completion choices. |
| `stdin` | Read standard input as text. |
| `fetch` | HTTP requests with ZX's piping support. |
| `sleep` | Delay execution. |
| `retry`, `expBackoff` | Bounded retries and exponentially increasing delays. |
| `spinner` | Display progress while a callback runs. |
| `tempdir`, `tmpdir` | Create a temporary directory; aliases. |
| `tempfile`, `tmpfile` | Create a temporary file, optionally with contents; aliases. |
| `cd` | Change the working directory. |
| `within` | Scope ZX configuration to a callback's async context. |
| `syncProcessCwd` | Enable or disable synchronization after `process.chdir`. |
| `kill` | Signal a process and its descendants. |
| `quote`, `quotePowerShell` | Explicit Bash or PowerShell quoting; `$` already escapes interpolations. |
| `useBash`, `usePowerShell`, `usePwsh` | Select a shell preset. |
| `VERSION`, `version` | ZX version string; aliases. |

The public entrypoint also exports `defaults`, `resolveDefaults`, `log`, `Fail`, and `bus` for configuration, logging, errors, and internal coordination. Use them only when the operation needs that lower-level control. Type-only exports include `Options`, `Shell`, `Duration`, and `LogEntry`; import types with `import type`.

The exported standalone `nothrow` and `quiet` helpers are deprecated. Use a command's `.nothrow()` and `.quiet()` methods instead.

Sources: [API reference](https://google.github.io/zx/api), [public entrypoint](https://github.com/google/zx/blob/main/src/index.ts), [script helpers](https://github.com/google/zx/blob/main/src/goods.ts), and [command core](https://github.com/google/zx/blob/main/src/core.ts). Recheck the installed package's exports and declarations when using this inventory in another environment.
