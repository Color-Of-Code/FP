#!/usr/bin/env node --experimental-strip-types
/**
 * check-lang-order.ts
 *
 * Verifies that every docs/*.md and docs/monads/*.md file (except those in
 * SKIP_FILES) contains exactly one section heading for each of the required
 * languages, in the required order:
 *   C#  →  F#  →  Ruby  →  C++  →  JavaScript  →  Python  →  Haskell  →  Rust  →  Go
 *
 * A heading matches a language when it starts with "### <language>" followed
 * by end-of-line or a space (allowing suffixes like "### C# (async CE)").
 */

import fs from "node:fs";
import path from "node:path";

// Languages in required order
const REQUIRED: readonly string[] = [
  "C#",
  "F#",
  "Ruby",
  "C++",
  "JavaScript",
  "Python",
  "Haskell",
  "Rust",
  "Go",
];

// Files that deliberately have no language-example sections
// (discussion/comparison chapters rather than 9-language tutorials)
const SKIP_FILES: ReadonlySet<string> = new Set([
  "01-function.md",
  "22-effects.md",
]);

const repoRoot: string = path.resolve(import.meta.dirname, "..");
const docDirs: string[] = [
  path.join(repoRoot, "docs"),
  path.join(repoRoot, "docs", "monads"),
  path.join(repoRoot, "docs", "optics"),
];

/** Collect all .md files under the given directories (non-recursive). */
function collectFiles(dirs: string[]): string[] {
  const files: string[] = [];
  for (const dir of dirs) {
    if (!fs.existsSync(dir)) continue;
    for (const entry of fs.readdirSync(dir)) {
      if (entry.endsWith(".md")) files.push(path.join(dir, entry));
    }
  }
  return files.sort();
}

/** Return the language key if the heading line matches one of REQUIRED, else null. */
function matchLang(line: string): string | null {
  // Normalise markdown-escaped special chars (e.g. "C\#" → "C#", "C\+\+" → "C++")
  const normalised = line.replace(/\\([#+()\[\]{}*!])/g, "$1");
  for (const lang of REQUIRED) {
    // Escape special regex chars in lang name (C# → C\#, C++ → C\+\+)
    const escaped = lang.replace(/[+#]/g, "\\$&");
    const re = new RegExp(`^###\\s+${escaped}(\\s|$)`);
    if (re.test(normalised)) return lang;
  }
  return null;
}

let errors = 0;

for (const file of collectFiles(docDirs)) {
  const basename = path.basename(file);
  if (SKIP_FILES.has(basename)) continue;

  const lines = fs.readFileSync(file, "utf8").split("\n");
  const found: string[] = []; // langs in the order they appear
  const counts = new Map<string, number>(); // how many times each lang appears

  for (const line of lines) {
    const lang = matchLang(line);
    if (lang) {
      found.push(lang);
      counts.set(lang, (counts.get(lang) ?? 0) + 1);
    }
  }

  const rel = path.relative(repoRoot, file);
  let fileErrors = 0;

  // 1. Missing languages
  for (const lang of REQUIRED) {
    if (!counts.has(lang)) {
      console.error(`${rel}: missing "### ${lang}" section`);
      fileErrors++;
    }
  }

  // 2. Duplicate languages
  for (const lang of REQUIRED) {
    const count = counts.get(lang) ?? 0;
    if (count > 1) {
      console.error(
        `${rel}: "### ${lang}" appears ${count} times (expected 1)`
      );
      fileErrors++;
    }
  }

  // 3. Wrong order (only check if all are present and no duplicates)
  if (fileErrors === 0) {
    const presentInRequired = REQUIRED.filter((l) => counts.has(l));
    const presentInFound = found.filter((l) =>
      (REQUIRED as string[]).includes(l)
    );
    for (let i = 0; i < presentInFound.length; i++) {
      if (presentInFound[i] !== presentInRequired[i]) {
        console.error(
          `${rel}: wrong language order — got [${presentInFound.join(", ")}]` +
            `, want [${REQUIRED.join(", ")}]`
        );
        fileErrors++;
        break;
      }
    }
  }

  errors += fileErrors;
}

if (errors === 0) {
  console.log(
    "check-lang-order: all files OK (languages complete and in order)"
  );
  process.exit(0);
} else {
  console.error(`check-lang-order: ${errors} error(s) found`);
  process.exit(1);
}
