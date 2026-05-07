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
export const REQUIRED: readonly string[] = [
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
export const SKIP_FILES: ReadonlySet<string> = new Set([
  "01-function.md",
  "22-effects.md",
]);

/** Return the language key if the heading line matches one of REQUIRED, else null. */
export function matchLang(line: string): string | null {
  // Normalise markdown-escaped special chars (e.g. "C\#" → "C#", "C\+\+" → "C++")
  const normalised = line.replace(/\\([#+()\[\]{}*!])/g, "$1");
  const match = REQUIRED.find(lang => {
    const escaped = lang.replace(/[+#]/g, "\\$&");
    const re = new RegExp(`^###\\s+${escaped}(\\s|$)`);
    return re.test(normalised);
  });
  return match ?? null;
}

/** Check a single file's content for language section errors. Returns error messages. */
export function checkFile(content: string, relPath: string): string[] {
  const lines = content.split("\n");
  const found = lines.map(matchLang).filter((l): l is string => l !== null);
  const counts = found.reduce<ReadonlyMap<string, number>>(
    (acc, lang) => new Map([...acc, [lang, (acc.get(lang) ?? 0) + 1]]),
    new Map<string, number>(),
  );

  // 1. Missing languages
  const missing = REQUIRED.filter(lang => !counts.has(lang));
  const missingErrors = missing.map(lang => `${relPath}: missing "### ${lang}" section`);

  // 2. Duplicate languages
  const duplicates = REQUIRED.filter(lang => (counts.get(lang) ?? 0) > 1);
  const dupErrors = duplicates.map(lang =>
    `${relPath}: "### ${lang}" appears ${counts.get(lang)} times (expected 1)`,
  );

  // 3. Wrong order (only check if no missing/duplicate errors)
  const orderErrors = (missing.length === 0 && duplicates.length === 0)
    ? (() => {
        const presentInRequired = REQUIRED.filter(l => counts.has(l));
        const presentInFound = found.filter(l => REQUIRED.includes(l));
        const isOutOfOrder = presentInFound.some((l, i) => l !== presentInRequired[i]);
        return isOutOfOrder
          ? [`${relPath}: wrong language order — got [${presentInFound.join(", ")}]` +
             `, want [${REQUIRED.join(", ")}]`]
          : [];
      })()
    : [];

  return [...missingErrors, ...dupErrors, ...orderErrors];
}

/** Collect all .md files under the given directories (non-recursive). */
function collectFiles(dirs: readonly string[]): string[] {
  return dirs
    .filter(dir => fs.existsSync(dir))
    .flatMap(dir =>
      fs.readdirSync(dir)
        .filter(entry => entry.endsWith(".md"))
        .map(entry => path.join(dir, entry)),
    )
    .toSorted();
}

// ── CLI entry point (only when run directly) ────────────────────────────────

const isCli = process.argv[1]?.endsWith("check-lang-order.ts") ?? false;

if (isCli) {
  const repoRoot: string = path.resolve(import.meta.dirname, "..");
  const docDirs: string[] = [
    path.join(repoRoot, "docs"),
    path.join(repoRoot, "docs", "monads"),
    path.join(repoRoot, "docs", "optics"),
  ];

  const allErrors = collectFiles(docDirs)
    .filter(file => !SKIP_FILES.has(path.basename(file)))
    .flatMap(file => {
      const content = fs.readFileSync(file, "utf8");
      const rel = path.relative(repoRoot, file);
      return checkFile(content, rel);
    });

  allErrors.forEach(err => console.error(err));

  if (allErrors.length === 0) {
    console.log(
      "check-lang-order: all files OK (languages complete and in order)",
    );
    process.exit(0);
  } else {
    console.error(`check-lang-order: ${allErrors.length} error(s) found`);
    process.exit(1);
  }
}
