# ZX Utility Foundation

Read this reference only when the requested script needs reusable filesystem, JSON, console, assertion, or interactive-input helpers. Copy the smallest fitting subset and adapt imports and quotes to the repository.

```ts
import { mkdir, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { chalk, question } from "zx";

const isMissingPathError = (error: unknown): error is NodeJS.ErrnoException =>
  error instanceof Error && "code" in error && error.code === "ENOENT";

const exists = async (target: string) => {
  try {
    await stat(target);
    return true;
  } catch (error) {
    if (isMissingPathError(error)) return false;
    throw error;
  }
};

const isDirectory = async (target: string) =>
  (await exists(target)) && (await stat(target)).isDirectory();

const isFile = async (target: string) =>
  (await exists(target)) && (await stat(target)).isFile();

const forEachEntry = async (
  target: string,
  visit: (entry: string) => Promise<void> | void,
) => {
  if (!(await isDirectory(target))) return;
  for (const entry of await readdir(target)) await visit(entry);
};

const readText = (target: string) => readFile(target, "utf8");

const readJson = async (target: string): Promise<unknown> =>
  JSON.parse(await readText(target));

const writeText = async (target: string, content: string) => {
  await mkdir(dirname(target), { recursive: true });
  await writeFile(target, content);
};

const writeJson = (target: string, value: unknown) =>
  writeText(target, `${JSON.stringify(value, null, 2)}\n`);

const remove = (target: string) => rm(target, { force: true, recursive: true });

const appendLine = (content: string, line: string, prepend = false) =>
  prepend ? `${line}\n${content}` : `${content}\n${line}`;

const print = (...values: unknown[]) => console.log(chalk.blue(...values));
const printSuccess = (...values: unknown[]) => console.log(chalk.green(...values));
const printError = (...values: unknown[]) => console.error(chalk.red(...values));

const assert = (condition: unknown, message: string): asserts condition => {
  if (condition) return;
  throw new Error(message);
};

const input = (message: string) => question(`${message}: `);
```

Validate the `unknown` value returned by `readJson` before using it. Omit every unused helper and import from the final script.
