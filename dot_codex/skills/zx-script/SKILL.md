---
name: zx-script
description: Create a project-native Bun and ZX TypeScript script from a reusable utility foundation, keeping only the helpers its current operation needs.
---

# ZX Script

Usage: `$zx-script <filename> <operation>`

## Workflow

1. Inspect `package.json`, existing scripts, and `tools/`, `scripts/`, `bin/`, and `utils/`. Complete discovery when the repository's script directory, runtime, module style, and naming convention are known.
2. Resolve only result-changing details the operation leaves open: inputs, outputs, destructive effects, and integration entrypoint. Prefer safe defaults when the repository already establishes them.
3. Create `<filename>.ts` in the existing script directory or `scripts/` when none exists. Start from the smallest fitting shape:

```ts
#!/usr/bin/env bun
import { $ } from "zx";

const main = async () => {
  // Implement the requested operation.
};

await main();
```

Use only the imports and helpers the operation needs. Read [utility-foundation.md](references/utility-foundation.md) when the operation needs filesystem, JSON, console, assertion, or interactive-input helpers, then copy only the relevant pieces. Follow the repository's quote, module, and error-handling style. Keep external input typed and validate it at the boundary.

4. Add a `package.json` entry only when the user requests one or the repository exposes comparable scripts there. Use `bun <script-path>.ts`.
5. Run the repository formatter or type checker for the file, then exercise the smallest safe representative invocation. Complete when the requested operation works, failure output is actionable, and no unused template code remains.

## Implementation Contract

- Prefer ZX and Bun primitives already installed by the project.
- Keep one-off values inline and extract helpers only when reused or when they isolate complex logic.
- Use arrow functions, inferred types, and concrete boundary validation.
- Preserve unrelated files and package scripts.
- Keep destructive operations behind an explicit user choice or a dry-run preview when practical.

Report the created path, invocation, and verification result.
