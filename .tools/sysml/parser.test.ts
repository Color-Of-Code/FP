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
import { findSysmlFiles, repoRoot } from "./test-utils/fixtures.ts";

const here = path.dirname(fileURLToPath(import.meta.url));
const snapshotDir = path.join(here, "__ast_snapshots__");

describe("SysML → AST snapshots", () => {
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
      const src   = fs.readFileSync(file, "utf8");
      const model = parse(src);
      const json  = JSON.stringify(model, null, 2) + "\n";
      const base  = path.basename(file, ".sysml");
      await expect(json).toMatchFileSnapshot(path.join(snapshotDir, `${base}.json`));
    });
  });
});
