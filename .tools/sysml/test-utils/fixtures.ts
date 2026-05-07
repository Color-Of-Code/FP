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
