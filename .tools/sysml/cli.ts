#!/usr/bin/env node --experimental-strip-types
/**
 * CLI entry point: SysML v2 → SVG transpiler.
 *
 * Usage:
 *   node --experimental-strip-types .tools/sysml/cli.ts <input.sysml> <output.svg>
 */

import fs from "node:fs";
import path from "node:path";
import { tokenise } from "./lexer.ts";
import { parse } from "./parser.ts";
import { modelToSvg } from "./render/index.ts";

const [, , inFile, outFile] = process.argv;
if (!inFile || !outFile) {
  console.error("Usage: sysml-to-svg <input.sysml> <output.svg>");
  process.exit(1);
}

const src = fs.readFileSync(inFile, "utf8");
const tokens = tokenise(src);
const model = parse(tokens);
const baseName = path.basename(inFile, ".sysml");
const svg = modelToSvg(model, baseName);
fs.writeFileSync(outFile, svg, "utf8");
console.log(`  generated ${outFile}`);
