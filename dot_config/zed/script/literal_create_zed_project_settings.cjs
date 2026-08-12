#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const mergeDeep = (target, source) => {
  for (const key in source) {
    if (
      source[key] &&
      typeof source[key] === "object" &&
      !Array.isArray(source[key])
    ) {
      if (!target[key] || typeof target[key] !== "object") {
        target[key] = {};
      }
      mergeDeep(target[key], source[key]);
    } else {
      target[key] = source[key];
    }
  }
  return target;
};

const createZedProjectSettings = (templateName) => {
  const templatePath = path.join(
    __dirname,
    "templates",
    `${templateName}.json`,
  );

  if (!fs.existsSync(templatePath)) {
    console.error(`Template not found: ${templatePath}`);
    console.error(`Available templates: biome, eslint-prettier`);
    process.exit(1);
  }

  let settingsTemplate;
  try {
    const templateContent = fs.readFileSync(templatePath, "utf8");
    settingsTemplate = JSON.parse(templateContent);
  } catch (error) {
    console.error(`Error reading template file: ${error.message}`);
    process.exit(1);
  }

  const outputPath = path.join(process.cwd(), ".zed", "settings.json");

  // Create .zed directory if it doesn't exist
  const zedDir = path.dirname(outputPath);
  if (!fs.existsSync(zedDir)) {
    fs.mkdirSync(zedDir, { recursive: true });
    console.log(`Created directory: ${zedDir}`);
  }

  let existingSettings = {};

  // Read existing settings if file exists
  if (fs.existsSync(outputPath)) {
    try {
      const existingContent = fs.readFileSync(outputPath, "utf8");
      existingSettings = JSON.parse(existingContent);
      console.log(
        `Found existing settings, merging with ${templateName} configuration...`,
      );
    } catch (error) {
      console.log(
        `Warning: Could not parse existing settings.json, creating new file...`,
      );
    }
  }

  // Merge existing settings with new template
  const mergedSettings = mergeDeep(existingSettings, settingsTemplate);

  // Write merged settings.json
  fs.writeFileSync(outputPath, JSON.stringify(mergedSettings, null, 2));
  console.log(
    `Created/updated ${templateName} project settings at: ${outputPath}`,
  );
};

// Run the script
if (require.main === module) {
  const templateName = process.argv[2];

  if (!templateName) {
    console.error(
      "Usage: node create_zed_project_settings.cjs <template-name>",
    );
    console.error("Available templates: biome, eslint-prettier");
    process.exit(1);
  }

  createZedProjectSettings(templateName);
}

module.exports = createZedProjectSettings;
