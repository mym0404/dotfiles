import { spawn } from "node:child_process";
import { existsSync, readFileSync, readdirSync, realpathSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { ancestorDirectories, detectTool } from "./project-tools.mjs";
import { createRpc } from "./format-rpc.mjs";

const MAX_OUTPUT_BYTES = 16 * 1024 * 1024;
const COMMAND_TIMEOUT_MS = 10000;
const WORKER_KILL_DELAY_MS = 1000;
const FORMAT_CONFIG = /^\.prettierrc(?:\..+)?$|^prettier\.config\..+$|^biome\.jsonc?$|^\.oxfmtrc\..+$|^oxfmt\.config\..+$/;
const FORMAT_INPUT = /^(?:package\.json|yarn\.lock|pnpm-lock\.yaml|package-lock\.json|bun\.lockb?|\.pnp\.cjs|\.pnp\.loader\.mjs|\.editorconfig|\.prettierignore|\.gitignore)$/;
const PACKAGE_NAMES = { prettier: "prettier", biome: "@biomejs/biome", oxfmt: "oxfmt" };

const fileSignature = (path) => {
  try {
    const { mtimeMs, size, ino } = statSync(path);
    return `${mtimeMs}:${size}:${ino}`;
  } catch {
    return "missing";
  }
};

const configurationSignature = (filePath, packagePath) => {
  const paths = ancestorDirectories(dirname(filePath)).flatMap((directory) => {
    try {
      return readdirSync(directory)
        .filter((entry) => FORMAT_CONFIG.test(entry) || FORMAT_INPUT.test(entry))
        .map((entry) => join(directory, entry));
    } catch {
      return [];
    }
  });
  if (packagePath) paths.push(packagePath);
  return paths.sort().map((path) => `${path}:${fileSignature(path)}`).join("\n");
};

const biomeConfiguration = (filePath) => {
  for (const directory of ancestorDirectories(dirname(filePath))) {
    const matches = ["biome.json", "biome.jsonc"]
      .map((name) => join(directory, name))
      .filter(existsSync);
    if (matches.length > 1) throw new Error(`Multiple Biome configurations in ${directory}`);
    if (matches.length === 1) return matches[0];
  }
  return undefined;
};

const projectEnvironment = (directory) => {
  const loaderDirectory = ancestorDirectories(directory).find((ancestor) =>
    existsSync(join(ancestor, ".pnp.cjs")),
  );
  if (!loaderDirectory) return process.env;
  const loader = join(loaderDirectory, ".pnp.cjs");
  const esmLoader = join(loaderDirectory, ".pnp.loader.mjs");
  const options = [process.env.NODE_OPTIONS, `--require ${JSON.stringify(loader)}`];
  if (existsSync(esmLoader)) options.push(`--experimental-loader ${JSON.stringify(esmLoader)}`);
  return { ...process.env, NODE_OPTIONS: options.filter(Boolean).join(" ") };
};

const terminateChild = (child) => {
  if (child.killed) return;
  if (!child.kill("SIGTERM")) return;
  const timer = setTimeout(() => child.kill("SIGKILL"), WORKER_KILL_DELAY_MS);
  timer.unref();
  child.once("exit", () => clearTimeout(timer));
};

const resolvePackage = (tool, directory) => {
  const projectRequire = createRequire(join(realpathSync(directory), "package.json"));
  const name = PACKAGE_NAMES[tool];
  let manifestPath;
  try {
    manifestPath = projectRequire.resolve(`${name}/package.json`);
  } catch {
    let current = dirname(projectRequire.resolve(name));
    while (true) {
      const candidate = join(current, "package.json");
      if (existsSync(candidate) && JSON.parse(readFileSync(candidate, "utf8")).name === name) {
        manifestPath = candidate;
        break;
      }
      const parent = dirname(current);
      if (parent === current) throw new Error(`${name} package manifest was not found`);
      current = parent;
    }
  }
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  const bin = typeof manifest.bin === "string" ? manifest.bin : manifest.bin?.[tool];
  if (!bin) throw new Error(`${name} does not expose a ${tool} executable`);
  const executable = join(dirname(manifestPath), bin);
  if (!existsSync(executable)) throw new Error(`${name} executable is missing: ${executable}`);

  return { manifestPath, command: process.execPath, args: [executable] };
};

const runCommand = ({ command, args, cwd, input }) =>
  new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd, env: process.env, stdio: ["pipe", "pipe", "pipe"] });
    const stdout = [];
    const stderr = [];
    let stdoutSize = 0;
    let stderrSize = 0;
    let settled = false;
    const finish = (error, output) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      if (error) reject(error);
      else resolve(output);
    };
    const timer = setTimeout(() => {
      child.kill("SIGKILL");
      finish(new Error(`Formatter command timed out after ${COMMAND_TIMEOUT_MS} ms`));
    }, COMMAND_TIMEOUT_MS);
    child.stdout.on("data", (chunk) => {
      stdoutSize += chunk.length;
      if (stdoutSize > MAX_OUTPUT_BYTES) {
        child.kill("SIGKILL");
        finish(new Error("Formatter output exceeds 16 MiB"));
      } else {
        stdout.push(chunk);
      }
    });
    child.stderr.on("data", (chunk) => {
      stderrSize += chunk.length;
      if (stderrSize > MAX_OUTPUT_BYTES) {
        child.kill("SIGKILL");
        finish(new Error("Formatter errors exceed 16 MiB"));
      } else {
        stderr.push(chunk);
      }
    });
    child.on("error", (error) => finish(error));
    child.on("close", (code) => {
      const output = Buffer.concat(stdout).toString();
      const errors = Buffer.concat(stderr).toString().trim();
      if (code !== 0 || (input && !output)) {
        finish(new Error(errors || `Formatter exited with status ${code}`));
      } else {
        finish(undefined, output);
      }
    });
    child.stdin.on("error", () => {});
    child.stdin.end(input);
  });

const wholeDocumentEdit = (source, formatted) => {
  if (source === formatted) return [];
  const lines = source.split("\n");
  return [{
    range: {
      start: { line: 0, character: 0 },
      end: { line: lines.length - 1, character: lines.at(-1).length },
    },
    newText: formatted,
  }];
};

const startWorker = (tool, directory) => {
  const executable = resolvePackage(tool, directory);
  let oxfmt;
  const openDocuments = new Map();

  const startOxfmt = async () => {
    const child = spawn(executable.command, [...executable.args, "--lsp"], {
      cwd: directory,
      env: process.env,
      stdio: ["pipe", "pipe", "pipe"],
    });
    child.stderr.on("data", (chunk) => process.stderr.write(chunk));
    const rpc = createRpc({
      input: child.stdout,
      output: child.stdin,
      onRequest: () => null,
      onClose: () => terminateChild(child),
    });
    child.on("error", (error) => rpc.close(error));
    child.on("exit", () => rpc.close());
    await rpc.request("initialize", {
      processId: process.pid,
      rootUri: pathToFileURL(directory).href,
      capabilities: {},
    });
    rpc.notify("initialized", {});
    oxfmt = { child, rpc };
  };

  const format = async ({ uri, source, options }) => {
    const filePath = fileURLToPath(uri);
    if (tool === "oxfmt") {
      if (!oxfmt) await startOxfmt();
      const version = (openDocuments.get(uri) ?? 0) + 1;
      if (version === 1) {
        const extension = filePath.match(/\.(tsx?|jsx?)$/)?.[1];
        const languageId = {
          ts: "typescript",
          tsx: "typescriptreact",
          js: "javascript",
          jsx: "javascriptreact",
        }[extension];
        oxfmt.rpc.notify("textDocument/didOpen", {
          textDocument: { uri, languageId, version, text: source },
        });
      } else {
        oxfmt.rpc.notify("textDocument/didChange", {
          textDocument: { uri, version },
          contentChanges: [{ text: source }],
        });
      }
      openDocuments.set(uri, version);
      return (await oxfmt.rpc.request("textDocument/formatting", {
        textDocument: { uri },
        options: options ?? { tabSize: 2, insertSpaces: true },
      })) ?? [];
    }

    const configPath = tool === "biome" ? biomeConfiguration(filePath) : undefined;
    const args = tool === "prettier"
      ? ["--stdin-filepath", filePath]
      : [
          "format",
          ...(configPath ? [`--config-path=${configPath}`] : []),
          `--stdin-file-path=${filePath}`,
        ];
    const formatted = await runCommand({
      ...executable,
      args: [...executable.args, ...args],
      cwd: directory,
      input: source,
    });
    return wholeDocumentEdit(source, formatted);
  };

  createRpc({
    input: process.stdin,
    output: process.stdout,
    onRequest: (method, params) => {
      if (method === "ready") return { packagePath: executable.manifestPath };
      if (method === "format") return format(params);
      if (method === "closeDocument") {
        if (oxfmt && openDocuments.has(params.uri)) {
          oxfmt.rpc.notify("textDocument/didClose", { textDocument: { uri: params.uri } });
          openDocuments.delete(params.uri);
        }
        return null;
      }
      return null;
    },
    onClose: () => {
      if (oxfmt) {
        oxfmt.rpc.close();
        terminateChild(oxfmt.child);
      }
      process.exitCode = 0;
    },
  });
};

export const startFormatServer = () => {
  const documents = new Map();
  const workers = new Map();

  const stopWorker = (key) => {
    const worker = workers.get(key);
    if (!worker) return;
    workers.delete(key);
    worker.rpc.close();
    terminateChild(worker.child);
  };

  const getWorker = async (selection, filePath) => {
    const key = `${selection.directory}:${selection.tool}`;
    let worker = workers.get(key);
    if (worker && worker.signatures.has(filePath)) {
      const signature = configurationSignature(filePath, worker.packagePath);
      if (signature !== worker.signatures.get(filePath)) {
        stopWorker(key);
        worker = undefined;
      }
    }
    if (!worker) {
      const child = spawn(process.execPath, [fileURLToPath(import.meta.url), "--worker", selection.tool, selection.directory], {
        cwd: selection.directory,
        env: projectEnvironment(selection.directory),
        stdio: ["pipe", "pipe", "pipe"],
      });
      child.stderr.on("data", (chunk) => process.stderr.write(chunk));
      const rpc = createRpc({
        input: child.stdout,
        output: child.stdin,
        onClose: () => terminateChild(child),
      });
      child.on("error", (error) => rpc.close(error));
      child.on("exit", () => rpc.close());
      worker = { child, rpc, queue: Promise.resolve(), signatures: new Map() };
      workers.set(key, worker);
      worker.ready = rpc.request("ready").then((ready) => {
        worker.packagePath = ready.packagePath;
      }).catch((error) => {
        stopWorker(key);
        throw error;
      });
    }
    await worker.ready;
    worker.signatures.set(filePath, configurationSignature(filePath, worker.packagePath));
    return worker;
  };

  const format = async ({ uri, options }) => {
    const document = documents.get(uri);
    if (!document) return [];
    const filePath = fileURLToPath(uri);
    const selection = detectTool("format", dirname(filePath));
    if (!selection.tool) {
      if (selection.error.startsWith("No project")) {
        process.stderr.write(`${selection.error}: ${filePath}\n`);
        return [];
      }
      throw new Error(selection.error);
    }
    const worker = await getWorker(selection, filePath);
    const source = document.text;
    const version = document.version;
    const task = worker.queue.then(() => worker.rpc.request("format", { uri, source, options }));
    worker.queue = task.catch(() => {});
    const edits = await task;
    const current = documents.get(uri);
    return current?.version === version && current?.text === source ? edits : [];
  };

  createRpc({
    input: process.stdin,
    output: process.stdout,
    onRequest: (method, params) => {
      if (method === "initialize") {
        return { capabilities: { textDocumentSync: 1, documentFormattingProvider: true } };
      }
      if (method === "shutdown") return null;
      if (method === "textDocument/formatting") {
        return format({ uri: params.textDocument.uri, options: params.options });
      }
      return null;
    },
    onNotification: (method, params) => {
      if (method === "exit") {
        for (const key of workers.keys()) stopWorker(key);
        process.exit(0);
      }
      if (method === "textDocument/didOpen") {
        documents.set(params.textDocument.uri, {
          text: params.textDocument.text,
          version: params.textDocument.version,
        });
      }
      if (method === "textDocument/didChange") {
        const change = params.contentChanges.at(-1);
        if (change) {
          documents.set(params.textDocument.uri, {
            text: change.text,
            version: params.textDocument.version,
          });
        }
      }
      if (method === "textDocument/didClose") {
        documents.delete(params.textDocument.uri);
        for (const worker of workers.values()) {
          worker.queue = worker.queue.then(() => worker.rpc.request("closeDocument", {
            uri: params.textDocument.uri,
          })).catch(() => {});
        }
      }
    },
    onClose: () => {
      for (const key of workers.keys()) stopWorker(key);
      process.exitCode = 0;
    },
  });
};

if (process.argv[2] === "--worker") {
  try {
    startWorker(process.argv[3], process.argv[4]);
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
}
