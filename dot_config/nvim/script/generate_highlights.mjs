#!/usr/bin/env zx
/* eslint-disable max-len */

// #region

// #endregion

// region ZX Util
import fs from 'fs-extra';
const join = path.join;
const resolve = path.resolve;
const filename = path.basename(__filename);
const cwd = () => process.cwd();
const exit = process.exit;
const _printTag = 'Highlights' || filename;
function exist(path) {
  return fs.existsSync(path);
}
function isDir(path) {
  return exist(path) && fs.lstatSync(path).isDirectory();
}
function isFile(path) {
  return exist(path) && fs.lstatSync(path).isFile();
}
async function iterateDir(path, fn) {
  if (!isDir(path)) {
    return;
  }
  for (const file of fs.readdirSync(path)) {
    await fn(file);
  }
}
function read(path) {
  return fs.readFileSync(path, { encoding: 'utf8' });
}
// you should require when possible(optimized in js)
function readJsonSlow(path) {
  return fs.readJSONSync(path);
}
function write(p, content) {
  const dir = path.dirname(p);
  if (!exist(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  return fs.writeFileSync(p, content);
}
function writeJson(path, json) {
  return write(path, JSON.stringify(json, null, 2));
}
function remove(path) {
  if (!exist(path)) {
    return;
  }
  if (fs.lstatSync(path).isDirectory()) {
    return fs.rmSync(path, { force: true, recursive: true });
  } else {
    return fs.rmSync(path, { force: true });
  }
}
function addLine(str, added, backward = false) {
  if (backward) {
    return added + '\n' + str;
  } else {
    return str + '\n' + added;
  }
}
function addLineToFile(path, added, backward = false) {
  return write(path, addLine(read(path), added, backward));
}
function print(...args) {
  echo(chalk.blue(`[${_printTag}]`, ...args));
}
function printSuccess(...args) {
  echo(chalk.bold.bgBlue(`[${_printTag}]`, ...args));
}
function printError(...args) {
  echo(chalk.bold.bgRed(`[${_printTag}]`, ...args));
}
function asrt(condition, ...args) {
  if (!condition) {
    echo(chalk.bold.bgRed(`[${_printTag}]`, ...args));
    exit(1);
  }
}
const tKey = {};
function measureBegin(name = '⏳') {
  print(`=======Start [${name}=======`);
  tKey[name] = Date.now();
}
function measureEnd(name = '⏳') {
  print(
    `=======End [${name}]==[${(Date.now() - tKey[name]).toLocaleString().split('.')[0]}ms]=======`,
  );
}
async function input(message) {
  if (message) {
    return question(message + ': ');
  } else {
    return stdin();
  }
}
async function fixLint(path) {
  await $`yarn prettier ${path} --write --log-level silent`;
  await $`yarn eslint ${path} --fix --quiet --max-warnings 100`;
}
const HEADING = `// @ts-nocheck
/* eslint-disable */
/**
 * Generated file. Don't modify manually.
 */
 `;
// endregion
const langs = ["c", "cpp", "javascript", "typescript", "typescriptreact", "javascriptreact", "python", "swift", "kotlin", "java", "json"]
const q = `
;; extends

[swift]((protocol_declaration name: (type_identifier) @code.interface) (#set! priority 200))
[swift]((class_declaration name: (type_identifier) @code.class) (#set! priority 200))
[swift]((custom_operator) @code.operator (#set! priority 200))
[swift]((parameter name: (simple_identifier)) @code (#set! priority 150))
[swift]((value_argument name: (value_argument_label) @code) (#set! priority 150))

[javascript,javascriptreact,typescript,typescriptreact]((hash_bang_line) @Special)
`.trim()
async function main() {
  const base_path = join(resolve(__dirname, '..'), "after", "queries");

  for (const lang of langs) {
    const dir_path = join(base_path, lang);
    const file_path = join(dir_path, "highlights.scm");

    let ret = '';
    for (const line of q.split(/\r?\n/)) {
      const m = line.match(/^\[([\w,]+)\](.*)/);
      if (!m) {
        ret += line + "\n";
      } else {
        const tokens = m[1].split(',').map(c => c.trim())
        const negativeTokens = tokens.filter(t => t.startsWith("!")).map(t => t.substr(1));
        const positiveTokens = tokens.filter(t => !t.startsWith("!"));
        const isAllTokenExist = tokens.findIndex(t => t === "*") !== -1;
        if (!negativeTokens.includes(lang) && (isAllTokenExist || positiveTokens.includes(lang))) {
          ret += m[2] + "\n";
        }
      }
    }

    try {
      write(file_path, ret);
    } catch (error) {
      printError(`Error: Could not write to file: ${file_path}`, error);
    }
  }

  print("Highlight query generation complete.");
};
main();
