import { spawn, spawnSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

const TOOL_NAMES = {
  format: ["prettier", "biome", "oxfmt"],
  lint: ["eslint", "biome", "oxlint"],
};

const CONFIG_FILES = {
  prettier: /^\.prettierrc(?:\..+)?$|^prettier\.config\..+$/,
  biome: /^biome\.jsonc?$/,
  oxfmt: /^\.oxfmtrc\..+$|^oxfmt\.config\..+$/,
  eslint: /^\.eslintrc(?:\..+)?$|^eslint\.config\..+$/,
  oxlint: /^\.oxlintrc\..+$|^oxlint\.config\..+$/,
};

const SCRIPT_NAMES = {
  format: /^format(?::|$)|^fmt(?::|$)/,
  lint: /^lint(?::|$)|^check(?::|$)/,
};

const readPackage = (directory) => {
  try {
    return JSON.parse(readFileSync(join(directory, "package.json"), "utf8"));
  } catch {
    return undefined;
  }
};

const ancestorDirectories = (start) => {
  const directories = [];
  let directory = resolve(start);
  const home = homedir();

  while (true) {
    directories.push(directory);
    if (existsSync(join(directory, ".git")) || directory === home) break;
    const parent = dirname(directory);
    if (parent === directory) break;
    directory = parent;
  }

  return directories;
};

const toolsInScript = (script, names) =>
  names.filter((name) => new RegExp(`(?:^|[^\\w.-])${name}(?=$|[^\\w.-])`).test(script));

const detectTool = (kind, start) => {
  const names = TOOL_NAMES[kind];
  let dependencyMatch;

  for (const directory of ancestorDirectories(start)) {
    let entries;
    try {
      entries = readdirSync(directory);
    } catch {
      continue;
    }

    const manifest = readPackage(directory);
    const configMatches = names.filter(
      (name) =>
        entries.some((entry) => CONFIG_FILES[name].test(entry)) ||
        (name === "prettier" && manifest?.prettier !== undefined) ||
        (name === "eslint" && manifest?.eslintConfig !== undefined),
    );
    const scripts = Object.entries(manifest?.scripts ?? {})
      .filter(([name]) => SCRIPT_NAMES[kind].test(name))
      .map(([, command]) => command)
      .join(" ");
    const scriptMatches = toolsInScript(scripts, names);

    if (scriptMatches.length === 1) {
      return { tool: scriptMatches[0], directory };
    }
    if (scriptMatches.length > 1) {
      return { error: `Multiple ${kind} tools in scripts at ${directory}` };
    }
    if (configMatches.length === 1) {
      return { tool: configMatches[0], directory };
    }
    if (configMatches.length > 1) {
      return { error: `Multiple ${kind} configurations in ${directory}` };
    }

    const dependencies = { ...manifest?.dependencies, ...manifest?.devDependencies };
    const installed = names.filter((name) => dependencies?.[name === "biome" ? "@biomejs/biome" : name]);
    if (!dependencyMatch && installed.length === 1) {
      dependencyMatch = { tool: installed[0], directory };
    }
  }

  return dependencyMatch ?? { error: `No project ${kind} tool found` };
};

const packageManager = (directory) => {
  for (const ancestor of ancestorDirectories(directory)) {
    const declared = readPackage(ancestor)?.packageManager?.split("@")[0];
    if (declared) return declared;
    if (existsSync(join(ancestor, "yarn.lock"))) return "yarn";
    if (existsSync(join(ancestor, "pnpm-lock.yaml"))) return "pnpm";
    if (existsSync(join(ancestor, "bun.lock")) || existsSync(join(ancestor, "bun.lockb"))) {
      return "bun";
    }
    if (existsSync(join(ancestor, "package-lock.json"))) {
      return "npm";
    }
  }
  return undefined;
};

const toolCommand = (tool, directory, args) => {
  for (const ancestor of ancestorDirectories(directory)) {
    const binary = join(ancestor, "node_modules", ".bin", tool);
    if (existsSync(binary)) return { command: binary, args, cwd: directory };
  }

  const manager = packageManager(directory);
  if (!manager) return undefined;
  const invocation = {
    yarn: ["yarn", ["exec", tool, ...args]],
    pnpm: ["pnpm", ["exec", tool, ...args]],
    npm: ["npm", ["exec", "--no", "--", tool, ...args]],
    bun: ["bunx", ["--no-install", tool, ...args]],
  }[manager];
  if (!invocation) return undefined;
  return { command: invocation[0], args: invocation[1], cwd: directory };
};

const format = (filePath) => {
  const source = readFileSync(0, "utf8");
  const selection = detectTool("format", dirname(filePath));
  if (!selection.tool) {
    process.stderr.write(`${selection.error}\n`);
    process.stdout.write(source);
    return;
  }

  const args = {
    prettier: ["--stdin-filepath", filePath],
    biome: ["format", `--stdin-file-path=${filePath}`],
    oxfmt: ["--stdin-filepath", filePath],
  }[selection.tool];
  const invocation = toolCommand(selection.tool, selection.directory, args);
  if (!invocation) throw new Error(`${selection.tool} is not installed in this project`);

  const result = spawnSync(invocation.command, invocation.args, {
    cwd: invocation.cwd,
    encoding: "utf8",
    input: source,
    maxBuffer: 16 * 1024 * 1024,
  });
  if (result.error || result.status !== 0 || (source && !result.stdout)) {
    throw new Error(result.stderr?.trim() || result.error?.message || `${selection.tool} failed`);
  }
  process.stdout.write(result.stdout);
};

const eslintServer = () => {
  const base = join(homedir(), "Library", "Application Support", "Zed", "languages", "eslint");
  const versions = readdirSync(base).filter((name) => name.startsWith("vscode-eslint-"));
  versions.sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
  const server = versions
    .map((version) => join(base, version, "vscode-eslint", "server", "out", "eslintServer.js"))
    .find(existsSync);
  if (!server) throw new Error("Zed's ESLint language server is not installed");
  return { command: process.execPath, args: ["--max-old-space-size=8192", server, "--stdio"] };
};

const sendLsp = (message) => {
  const content = Buffer.from(JSON.stringify({ jsonrpc: "2.0", ...message }));
  process.stdout.write(`Content-Length: ${content.length}\r\n\r\n`);
  process.stdout.write(content);
};

const emptyLanguageServer = (reason) => {
  process.stderr.write(`${reason}\n`);
  let pending = Buffer.alloc(0);
  process.stdin.on("data", (chunk) => {
    pending = Buffer.concat([pending, chunk]);
    while (true) {
      const headerEnd = pending.indexOf("\r\n\r\n");
      if (headerEnd < 0) break;
      const header = pending.subarray(0, headerEnd).toString();
      const length = Number(/Content-Length:\s*(\d+)/i.exec(header)?.[1]);
      if (!Number.isFinite(length) || pending.length < headerEnd + 4 + length) break;
      const message = JSON.parse(pending.subarray(headerEnd + 4, headerEnd + 4 + length).toString());
      pending = pending.subarray(headerEnd + 4 + length);
      if (message.method === "exit") {
        process.exit(0);
      }
      if (message.id === undefined || !message.method) continue;
      const result = {
        initialize: { capabilities: { textDocumentSync: 1 } },
        shutdown: null,
        "textDocument/diagnostic": { kind: "full", items: [] },
        "workspace/diagnostic": { items: [] },
      }[message.method] ?? null;
      sendLsp({ id: message.id, result });
    }
  });
};

const lint = () => {
  const selection = detectTool("lint", process.cwd());
  if (!selection.tool) {
    emptyLanguageServer(selection.error);
    return;
  }

  const invocation =
    selection.tool === "eslint"
      ? eslintServer()
      : toolCommand(
          selection.tool,
          selection.directory,
          selection.tool === "biome" ? ["lsp-proxy"] : ["--lsp"],
        );
  if (!invocation) {
    emptyLanguageServer(`${selection.tool} is not installed in this project`);
    return;
  }

  const child = spawn(invocation.command, invocation.args, {
    cwd: invocation.cwd ?? selection.directory,
    env: process.env,
    stdio: "inherit",
  });
  child.on("error", (error) => {
    emptyLanguageServer(`${selection.tool}: ${error.message}`);
  });
  child.on("exit", (code) => {
    process.exitCode = code ?? 1;
  });
};

try {
  if (process.argv[2] === "format" && process.argv[3]) {
    format(resolve(process.argv[3]));
  } else if (process.argv[2] === "lsp") {
    lint();
  } else if (process.argv[2] === "detect") {
    const kind = process.argv[3];
    if (!TOOL_NAMES[kind]) throw new Error(`Unknown tool kind: ${kind}`);
    const path = resolve(process.argv[4] ?? process.cwd());
    process.stdout.write(`${JSON.stringify(detectTool(kind, path))}\n`);
  } else {
    throw new Error("Usage: project-tools.mjs format <file> | lsp | detect <format|lint> <directory>");
  }
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
