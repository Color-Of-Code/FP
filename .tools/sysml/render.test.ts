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
import { describe, expect, it } from "vitest";
import { parse } from "./parser.ts";
import { modelToSvg } from "./render/index.ts";
import { findSysmlFiles, repoRoot } from "./test-utils/fixtures.ts";

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

  files.forEach(file => {
    const rel = path.relative(repoRoot, file);
    it(rel, async () => {
      const svg = await render(file);
      const snapshotPath = file.replace(/\.sysml$/, ".svg");
      await expect(svg).toMatchFileSnapshot(snapshotPath);
    });
  });
});
