#!/usr/bin/env node --experimental-strip-types

import fs from "node:fs";
import path from "node:path";

function findD2Files(directory: string, root: string): string[] {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const absolutePath = path.join(directory, entry.name);
    if (entry.isDirectory() && (entry.name === ".git" || entry.name === "node_modules")) return [];
    if (entry.isDirectory()) return findD2Files(absolutePath, root);
    return entry.isFile() && entry.name.endsWith(".d2")
      ? [path.relative(root, absolutePath).split(path.sep).join("/")]
      : [];
  });
}

const repoRoot = path.resolve(process.argv[2] ?? path.join(import.meta.dirname, ".."));
const allowlistPath = path.resolve(
  process.argv[3] ?? path.join(repoRoot, ".tools/d2-allowlist.txt"),
);
const allowed = new Set(
  fs
    .readFileSync(allowlistPath, "utf8")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && !line.startsWith("#")),
);
const current = findD2Files(repoRoot, repoRoot);
const additions = current.filter((file) => !allowed.has(file));

if (additions.length > 0) {
  console.error("D2 ratchet failed: new D2 files are not allowed.");
  additions.forEach((file) => console.error(`  ${file}`));
  process.exit(1);
} else {
  const retiredCount = [...allowed].filter((file) => !current.includes(file)).length;
  console.log(`D2 ratchet passed: ${current.length} existing file(s), ${retiredCount} retired.`);
}
