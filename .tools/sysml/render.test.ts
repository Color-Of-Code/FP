/**
 * Snapshot tests for the SysML → SVG rendering pipeline.
 *
 * For every *.sysml source under docs/ this test renders the model and
 * compares the result against the committed *.svg sibling using vitest's
 * `toMatchFileSnapshot`.  Any rendering change therefore produces a
 * reviewable git diff in CI.
 *
 * Update snapshots after intentional changes with:
 *   npx vitest run -u
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { parse } from "./parser.ts";
import { modelToSvg } from "./render/index.ts";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "..", "..");
const docsRoot = path.join(repoRoot, "docs");

// Recursively enumerate every .sysml fixture under docs/.  This is
// agnostic to whether sources live in the historical flat
// docs/<track>/diagrams/ folders or in per-chapter folders alongside
// each Markdown page.
function findSysmlFiles(): string[] {
  const out: string[] = [];
  function walk(dir: string): void {
    for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
      if (ent.name === "node_modules" || ent.name === ".next") continue;
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) walk(full);
      else if (ent.isFile() && ent.name.endsWith(".sysml")) out.push(full);
    }
  }
  if (fs.existsSync(docsRoot)) walk(docsRoot);
  return out.sort();
}

async function render(file: string): Promise<string> {
  const src    = fs.readFileSync(file, "utf8");
  const base   = path.basename(file, ".sysml");
  const model  = parse(src);
  return modelToSvg(model, base);
}

describe("SysML → SVG snapshots", () => {
  const files = findSysmlFiles();
  if (files.length === 0) {
    it("finds at least one SysML source", () => {
      throw new Error("No .sysml fixtures found under docs/");
    });
    return;
  }

  for (const file of files) {
    const rel = path.relative(repoRoot, file);
    it(rel, async () => {
      const svg = await render(file);
      const snapshotPath = file.replace(/\.sysml$/, ".svg");
      await expect(svg).toMatchFileSnapshot(snapshotPath);
    });
  }
});
