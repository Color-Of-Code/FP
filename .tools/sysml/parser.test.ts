/**
 * Snapshot tests for the SysML → AST parser.
 *
 * Captures the parsed Model for every fixture under docs/ so parser changes
 * surface as reviewable JSON diffs independently from the renderer's SVG
 * snapshots.  Update with `npx vitest run -u` after intentional grammar
 * changes.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { parse } from "./parser.ts";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "..", "..");
const snapshotDir = path.join(here, "__ast_snapshots__");
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

describe("SysML → AST snapshots", () => {
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
      const src   = fs.readFileSync(file, "utf8");
      const model = parse(src);
      const json  = JSON.stringify(model, null, 2) + "\n";
      const base  = path.basename(file, ".sysml");
      await expect(json).toMatchFileSnapshot(path.join(snapshotDir, `${base}.json`));
    });
  }
});
