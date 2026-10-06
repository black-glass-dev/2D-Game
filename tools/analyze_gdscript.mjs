#!/usr/bin/env node
/**
 * Parse and statically analyse every gameplay script without launching Godot.
 *
 * Usage:
 *   npm ci
 *   npm run test:gdscript
 */
import { AnalysisHandle } from "@gdscript-analyzer/core";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const scripts = [];

function collect_scripts(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      collect_scripts(path);
    } else if (entry.isFile() && entry.name.endsWith(".gd")) {
      scripts.push(path);
    }
  }
}

collect_scripts(join(root, "scripts"));
const analyzer = new AnalysisHandle();
analyzer.setProjectConfig(readFileSync(join(root, "project.godot"), "utf8"));

for (const script of scripts) {
  const resource_path = `res://${relative(root, script).replaceAll("\\", "/")}`;
  analyzer.openDocument(pathToFileURL(script).href, readFileSync(script, "utf8"), resource_path);
}

let errors = 0;
let warnings = 0;
for (const script of scripts) {
  const uri = pathToFileURL(script).href;
  for (const diagnostic of analyzer.diagnostics(uri)) {
    const severity = String(diagnostic.severity).toUpperCase();
    const source_path = relative(root, script);
    console.log(`${source_path}:${diagnostic.range.start}-${diagnostic.range.end} ${severity} ${diagnostic.code}: ${diagnostic.message}`);
    if (severity === "ERROR" || severity === "1") {
      errors += 1;
    } else {
      warnings += 1;
    }
  }
}

console.log(`GDScript analysis: ${scripts.length} scripts, ${errors} errors, ${warnings} warnings.`);
process.exitCode = errors === 0 ? 0 : 1;
