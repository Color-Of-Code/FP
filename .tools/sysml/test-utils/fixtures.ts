/**
 * Shared test utility: recursively enumerate every .sysml fixture under docs/.
 *
 * Used by both the AST snapshot tests and the SVG render snapshot tests.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "..", "..", "..");
const docsRoot = path.join(repoRoot, "docs");

export { repoRoot, docsRoot };

/**
 * Recursively enumerate every .sysml fixture under docs/.
 *
 * Agnostic to whether sources live in per-chapter folders or in the
 * historical flat layout.
 */
export function findSysmlFiles(): string[] {
  function walk(dir: string): readonly string[] {
    if (!fs.existsSync(dir)) return [];
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap(ent => {
      if (ent.name === "node_modules" || ent.name === ".next") return [];
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) return walk(full);
      return ent.isFile() && ent.name.endsWith(".sysml") ? [full] : [];
    });
  }
  return [...walk(docsRoot)].sort();
}
