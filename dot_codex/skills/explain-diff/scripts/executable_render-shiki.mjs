#!/usr/bin/env node

import { spawnSync } from 'node:child_process';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const skillDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const templatePath = path.join(skillDir, 'assets', 'explanation-template.html');
const packageJsonPath = path.join(skillDir, 'package.json');
const codeTheme = 'ayu-mirage';
const outputNamePattern = /^\d{4}-\d{2}-\d{2}-explanation-[a-z0-9]+(?:-[a-z0-9]+)*\.html$/;
const templateSlotPattern = /\{\{EXPLAIN_DIFF_[A-Z_]+\}\}/;
const sectionIds = ['background', 'intuition', 'code', 'quiz'];
const webstormIconPath = path.join(skillDir, 'assets', 'editor-icons', 'webstorm.svg');
const codeSourceAttributes = [
  'data-code-add-lines',
  'data-code-column',
  'data-code-file',
  'data-code-highlight-lines',
  'data-code-lang',
  'data-code-line',
  'data-code-openable',
  'data-code-remove-lines',
  'data-code-source',
  'data-code-title',
];

const readInstalledVersion = async (packageName) => {
  try {
    const packagePath = path.join(skillDir, 'node_modules', packageName, 'package.json');
    const packageJson = JSON.parse(await fs.readFile(packagePath, 'utf8'));
    return packageJson.version;
  } catch {
    return undefined;
  }
};

const ensureDependencies = async () => {
  const { dependencies: requiredDependencies } = JSON.parse(
    await fs.readFile(packageJsonPath, 'utf8'),
  );
  const installedVersions = await Promise.all(
    Object.keys(requiredDependencies).map(readInstalledVersion),
  );
  const ready = Object.values(requiredDependencies).every(
    (version, index) => installedVersions[index] === version,
  );

  if (ready) {
    return;
  }

  const result = spawnSync(
    'pnpm',
    ['install', '--frozen-lockfile', '--ignore-scripts'],
    { cwd: skillDir, stdio: 'inherit' },
  );

  if (result.error) {
    throw new Error(`Failed to start pnpm: ${result.error.message}`);
  }

  if (result.status !== 0) {
    throw new Error(`pnpm install failed with exit code ${result.status ?? 'unknown'}`);
  }
};

const resolveInputPath = async (rawPath) => {
  if (!rawPath || process.argv.length !== 3) {
    throw new Error('Usage: render-shiki.mjs /tmp/YYYY-MM-DD-explanation-<slug>.html');
  }

  const inputPath = path.resolve(rawPath);

  if (path.dirname(inputPath) !== '/tmp' || !outputNamePattern.test(path.basename(inputPath))) {
    throw new Error('Input must match /tmp/YYYY-MM-DD-explanation-<slug>.html');
  }

  const stat = await fs.lstat(inputPath);

  if (!stat.isFile()) {
    throw new Error('Input must be a regular HTML file, not a symlink');
  }

  return inputPath;
};

const parseLineSet = ({ value, attribute, lineCount }) => {
  const lines = new Set();

  if (value === undefined) {
    return lines;
  }

  if (!value.trim()) {
    throw new Error(`${attribute} must not be empty`);
  }

  for (const part of value.split(',')) {
    const match = part.trim().match(/^(\d+)(?:-(\d+))?$/);

    if (!match) {
      throw new Error(`${attribute} has an invalid range: ${part}`);
    }

    const start = Number(match[1]);
    const end = Number(match[2] ?? match[1]);

    if (start < 1 || end < start || end > lineCount) {
      throw new Error(`${attribute} is outside the 1-${lineCount} line range: ${part}`);
    }

    for (let line = start; line <= end; line += 1) {
      lines.add(line);
    }
  }

  return lines;
};

const escapeHtml = (value) => value
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#39;');

const parsePositiveInteger = ({ value, attribute, blockNumber, defaultValue }) => {
  const source = value ?? defaultValue;
  const parsed = Number(source);

  if (!/^[1-9]\d*$/.test(String(source)) || !Number.isSafeInteger(parsed)) {
    throw new Error(`Code block ${blockNumber} ${attribute} must be a positive integer`);
  }

  return parsed;
};

const validateCodeLocation = async ({ block, blockNumber }) => {
  const title = block.getAttribute('data-code-title')?.trim();
  const file = block.getAttribute('data-code-file');
  const openableSource = block.getAttribute('data-code-openable') ?? 'true';

  if (!title) {
    throw new Error(`Code block ${blockNumber} data-code-title is required`);
  }

  if (!file) {
    throw new Error(`Code block ${blockNumber} data-code-file is required`);
  }

  if (!path.isAbsolute(file) && !path.win32.isAbsolute(file)) {
    throw new Error(`Code block ${blockNumber} data-code-file must be an absolute path`);
  }

  if (openableSource !== 'true' && openableSource !== 'false') {
    throw new Error(`Code block ${blockNumber} data-code-openable must be true or false`);
  }

  const line = parsePositiveInteger({
    value: block.getAttribute('data-code-line'),
    attribute: 'data-code-line',
    blockNumber,
  });
  const column = parsePositiveInteger({
    value: block.getAttribute('data-code-column'),
    attribute: 'data-code-column',
    blockNumber,
    defaultValue: '1',
  });
  const openable = openableSource === 'true';

  if (openable) {
    let stat;

    try {
      stat = await fs.stat(file);
    } catch {
      throw new Error(`Code block ${blockNumber} data-code-file does not exist: ${file}`);
    }

    if (!stat.isFile()) {
      throw new Error(`Code block ${blockNumber} data-code-file must be a regular file: ${file}`);
    }

    const fileLineCount = (await fs.readFile(file, 'utf8')).split('\n').length;

    if (line > fileLineCount) {
      throw new Error(
        `Code block ${blockNumber} data-code-line ${line} exceeds ${fileLineCount} lines: ${file}`,
      );
    }
  }

  return { column, file, line, openable, title };
};

const createLanguageAliases = (bundledLanguagesInfo) => Object.fromEntries(
  bundledLanguagesInfo.flatMap(({ id, aliases = [] }) => [
    [id, id],
    ...aliases.map((alias) => [alias, id]),
  ]),
);

const validateTemplate = ({ root, templateRoot }) => {
  const styles = root.querySelectorAll('style');
  const templateStyle = templateRoot.querySelector('#explain-diff-template-style');

  if (
    styles.length !== 1
    || styles[0].getAttribute('id') !== 'explain-diff-template-style'
    || styles[0].textContent !== templateStyle?.textContent
  ) {
    throw new Error('Input must retain the template stylesheet unchanged');
  }

  const body = root.querySelector('body');
  const scripts = root.querySelectorAll('script');
  const templateScript = templateRoot.querySelector('body > script');
  const lastBodyElement = body?.childNodes.filter((node) => node.nodeType === 1).at(-1);

  if (
    scripts.length !== 1
    || scripts[0].toString() !== templateScript?.toString()
    || scripts[0].parentNode !== body
    || scripts[0] !== lastBodyElement
  ) {
    throw new Error('Input must retain the template page script unchanged');
  }

  const controls = root.querySelectorAll('template#code-block-editor-control-template');
  const templateControl = templateRoot.querySelector('template#code-block-editor-control-template');

  if (controls.length !== 1 || controls[0].toString() !== templateControl?.toString()) {
    throw new Error('Input must retain the code block editor control template unchanged');
  }

  const actualSectionIds = root
    .querySelectorAll('main > section')
    .map((section) => section.getAttribute('id'));

  if (actualSectionIds.join(',') !== sectionIds.join(',')) {
    throw new Error(`Input must retain section order: ${sectionIds.join(', ')}`);
  }
};

const embedEditorIcons = async (root) => {
  const icons = root.querySelectorAll('[data-editor-icon-source]');
  const source = await fs.readFile(webstormIconPath);
  const dataUri = `data:image/svg+xml;base64,${source.toString('base64')}`;

  for (const icon of icons) {
    const name = icon.getAttribute('data-editor-icon-source');

    if (name !== 'webstorm') {
      throw new Error(`Unknown editor icon source: ${name ?? 'missing'}`);
    }

    icon.setAttribute('src', dataUri);
    icon.removeAttribute('data-editor-icon-source');
  }
};

const render = async ({ inputPath, parse, shiki }) => {
  const [sourceHtml, templateHtml] = await Promise.all([
    fs.readFile(inputPath, 'utf8'),
    fs.readFile(templatePath, 'utf8'),
  ]);

  const unresolvedSlot = sourceHtml.match(templateSlotPattern)?.[0];

  if (unresolvedSlot) {
    throw new Error(`Unresolved template slot: ${unresolvedSlot}`);
  }

  const parseOptions = {
    comment: true,
    blockTextElements: {
      script: true,
      style: true,
    },
  };
  const root = parse(sourceHtml, {
    ...parseOptions,
  });
  const templateRoot = parse(templateHtml, { ...parseOptions });

  validateTemplate({ root, templateRoot });

  if (root.querySelector('figure.code-block')) {
    throw new Error('Input must not contain rendered figure.code-block elements');
  }

  const blocks = root.querySelectorAll('pre[data-code-source]');

  if (blocks.length === 0) {
    throw new Error('No pre[data-code-source] blocks found');
  }

  for (const element of root.querySelectorAll('*')) {
    const dataCodeAttributes = Object.keys(element.attributes).filter((attribute) => (
      attribute.startsWith('data-code-')
    ));

    if (dataCodeAttributes.length === 0) {
      continue;
    }

    const blockIndex = blocks.indexOf(element);

    if (blockIndex === -1) {
      throw new Error(
        `${dataCodeAttributes[0]} is only allowed on a pre[data-code-source] element`,
      );
    }

    const unsupportedAttribute = dataCodeAttributes.find((attribute) => (
      !codeSourceAttributes.includes(attribute)
    ));

    if (unsupportedAttribute) {
      throw new Error(`Code block ${blockIndex + 1} has unsupported attribute: ${unsupportedAttribute}`);
    }
  }

  const languageAliases = createLanguageAliases(shiki.bundledLanguagesInfo);
  const parsedBlocks = await Promise.all(blocks.map(async (block, index) => {
    const codeNode = block.querySelector('code');
    const blockNumber = index + 1;

    if (!codeNode) {
      throw new Error(`Code block ${blockNumber} must contain a <code> element`);
    }

    const code = codeNode.textContent;
    const lineCount = code.split('\n').length;
    const rawLanguage = (block.getAttribute('data-code-lang') ?? 'text').trim().toLowerCase();
    const normalizedLanguage = languageAliases[rawLanguage] ?? 'text';
    const addedLineSource = block.getAttribute('data-code-add-lines');
    const highlightedLineSource = block.getAttribute('data-code-highlight-lines');
    const removedLineSource = block.getAttribute('data-code-remove-lines');
    const addedLines = parseLineSet({
      value: addedLineSource,
      attribute: 'data-code-add-lines',
      lineCount,
    });
    const removedLines = parseLineSet({
      value: removedLineSource,
      attribute: 'data-code-remove-lines',
      lineCount,
    });
    const highlightedLines = parseLineSet({
      value: highlightedLineSource,
      attribute: 'data-code-highlight-lines',
      lineCount,
    });

    for (const line of addedLines) {
      if (removedLines.has(line)) {
        throw new Error(`Code block ${blockNumber} marks line ${line} as both added and removed`);
      }
    }

    const location = await validateCodeLocation({ block, blockNumber });

    return {
      addedLines,
      block,
      code,
      highlightedLines,
      language: normalizedLanguage,
      ...location,
      removedLines,
    };
  }));
  const languages = [...new Set(
    parsedBlocks.map(({ language }) => language).filter((language) => language !== 'text'),
  )];
  const highlighter = await shiki.createHighlighter({
    themes: [codeTheme],
    langs: languages,
  });

  try {
    for (const {
      addedLines,
      block,
      code,
      highlightedLines,
      language,
      column,
      file,
      line,
      openable,
      removedLines,
      title,
    } of parsedBlocks) {
      const highlightedHtml = highlighter.codeToHtml(code, {
        lang: language,
        theme: codeTheme,
        transformers: [{
          line(node, line) {
            if (addedLines.has(line)) {
              this.addClassToHast(node, 'diff');
              this.addClassToHast(node, 'add');
            }

            if (removedLines.has(line)) {
              this.addClassToHast(node, 'diff');
              this.addClassToHast(node, 'remove');
            }

            if (highlightedLines.has(line)) {
              this.addClassToHast(node, 'highlighted');
            }
          },
        }],
      });
      const highlightedRoot = parse(highlightedHtml);
      const pre = highlightedRoot.querySelector('pre.shiki');

      if (!pre) {
        throw new Error('Shiki did not return a <pre class="shiki"> block');
      }

      for (const attribute of Object.keys(pre.attributes)) {
        if (attribute !== 'class') {
          pre.removeAttribute(attribute);
        }
      }
      const locationAttributes = [
        `data-editor-file="${escapeHtml(file)}"`,
        `data-editor-line="${line}"`,
        `data-editor-column="${column}"`,
        `data-editor-openable="${openable}"`,
      ].join(' ');
      const header = [
        '<figcaption class="code-block__header">',
        `<span class="code-block__title" title="${escapeHtml(title)}">${escapeHtml(title)}</span>`,
        '<span class="code-block__actions"></span>',
        '</figcaption>',
      ].join('');
      block.replaceWith(
        `<figure class="code-block" ${locationAttributes}>${header}${pre.toString()}</figure>`,
      );
    }
  } finally {
    highlighter.dispose();
  }

  await embedEditorIcons(root);

  const hasSourceAttribute = root.querySelectorAll('*').some((element) => (
    Object.keys(element.attributes).some((attribute) => attribute.startsWith('data-code-'))
  ));

  if (hasSourceAttribute) {
    throw new Error('Unrendered data-code-* source attributes remain');
  }

  if (root.querySelector('[data-editor-icon-source]')) {
    throw new Error('Unresolved editor icon source remains');
  }

  return { html: root.toString(), blockCount: parsedBlocks.length };
};

const writeAtomically = async ({ inputPath, html }) => {
  const temporaryPath = path.join(
    '/tmp',
    `.${path.basename(inputPath)}.${process.pid}.${Date.now()}.tmp`,
  );
  const mode = (await fs.stat(inputPath)).mode & 0o7777;

  try {
    await fs.writeFile(temporaryPath, html, {
      encoding: 'utf8',
      flag: 'wx',
      mode,
    });
    await fs.chmod(temporaryPath, mode);
    await fs.rename(temporaryPath, inputPath);
  } catch (error) {
    await fs.unlink(temporaryPath).catch(() => {});
    throw error;
  }
};

const run = async () => {
  const inputPath = await resolveInputPath(process.argv[2]);
  await ensureDependencies();
  const [{ parse }, shiki] = await Promise.all([
    import('node-html-parser'),
    import('shiki'),
  ]);
  const result = await render({ inputPath, parse, shiki });
  await writeAtomically({ inputPath, html: result.html });
  console.log(`Rendered ${result.blockCount} Shiki code block(s) in ${inputPath}`);
};

run().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
