# Repository Guidance

## Knowledge System

- This root `AGENTS.md` is the repository's primary durable knowledge store and its only router. Keep any related documents under `.agents/knowledge/` synchronized when their owned facts change. Treat task-local plans, inventories, and findings as temporary.
- Document the current state without freezing it: intentional behavior changes may update these contracts. Keep knowledge at responsibility and contract level, and leave implementation details in code.
- Store each fact once. Use the narrowest stable path only for references whose misuse could lose data, bypass access control, or break an external contract, and explain that risk without line numbers or control-flow narration.

## Project Scope

This repository is a personal Neovim configuration built on LazyVim. It owns editor behavior, plugin integration, completion, LSP and formatting policy, generated Tree-sitter query extensions, snippets, and the local `theme-mj` colorscheme.

## Neovim Runtime

- `init.lua` is the runtime entry point and loads `lua/config/lazy.lua`.
- `lua/config/lazy.lua` bootstraps lazy.nvim, imports LazyVim, then imports the local specs from `lua/plugins/`. `lazyvim.json` selects LazyVim extras, while `lazy-lock.json` records resolved plugin revisions.
- `lua/config/` owns repository-wide options, autocommands, and keymaps. `lua/plugins/` owns plugin specs and overrides. `lua/utils/` owns shared editor behavior used by both areas.
- `snippets/`, `after/ftplugin/`, `queries/`, and `after/queries/` are loaded through Neovim's runtime path. Keep filetype-specific behavior in those runtime directories.
- `theme-mj/` is a local plugin loaded from `vim.fn.stdpath("config") .. "/theme-mj"`; the active colorscheme is `theme-mj`. The configuration therefore expects this repository, or a link to it, at Neovim's config path. Moving the theme requires updating that plugin contract.

### Data-changing behavior

- The configuration auto-writes modified buffers when leaving a buffer or losing focus. `lua/config/autocmds.lua` owns this persistence behavior; test changes with disposable files because mistakes can write unintended edits.
- `lua/config/keymaps.lua` owns mappings that discard Git changes and rename or delete files. Changes to these mappings require disposable-file and disposable-hunk checks because an incorrect target can lose work.
- JavaScript and TypeScript save actions are coordinated through `lua/utils/utils.lua`. Keep LSP code actions, formatter behavior, and the active TypeScript provider consistent when changing this path.

## Tree-sitter Query Generation

- `script/generate_highlights.mjs` is the source of truth for the shared and language-conditional extensions under `after/queries/*/highlights.scm`.
- `pnpm run gen:highlights` rewrites every configured file under `after/queries/`; edit the generator, run it, and review all generated diffs together.
- `queries/json/highlights.scm` is a separate hand-maintained base query. The generator does not update it.

## Commands and Verification

- `pnpm run gen:highlights` regenerates Tree-sitter query extensions; it is a write command, not a correctness check.
- `stylua --check .` checks Lua formatting using `stylua.toml`. Stylua is an external prerequisite and is not installed by the root package.
- `nvim --headless "+qa"` smoke-tests startup. It can bootstrap missing plugins and therefore may require Git and network access; it does not verify interactive mappings, LSP actions, completion, or UI behavior.

Use the smallest command that covers the changed area. For Markdown-only knowledge edits, reread the changed documents, resolve every referenced path, inspect the scripts behind named wrapper commands, and review the final diff; browser validation adds no evidence.
