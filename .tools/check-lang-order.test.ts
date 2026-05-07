import { describe, expect, it } from "vitest";
import { matchLang, checkFile, REQUIRED } from "./check-lang-order.ts";

// ── matchLang ─────────────────────────────────────────────────────────────

describe("matchLang", () => {
  it("matches a plain language heading", () => {
    expect(matchLang("### Haskell")).toBe("Haskell");
  });

  it("matches a heading with a suffix", () => {
    expect(matchLang("### C# (async CE)")).toBe("C#");
  });

  it("matches markdown-escaped C#", () => {
    expect(matchLang("### C\\#")).toBe("C#");
  });

  it("matches markdown-escaped C++", () => {
    expect(matchLang("### C\\+\\+")).toBe("C++");
  });

  it("returns null for non-language headings", () => {
    expect(matchLang("### Overview")).toBeNull();
  });

  it("returns null for wrong heading level", () => {
    expect(matchLang("## Haskell")).toBeNull();
  });
});

// ── checkFile ─────────────────────────────────────────────────────────────

describe("checkFile", () => {
  const allLangs = REQUIRED.map(l => `### ${l}`).join("\n\nSome code\n\n");

  it("returns no errors for a file with all 9 languages in order", () => {
    expect(checkFile(allLangs, "test.md")).toEqual([]);
  });

  it("reports missing languages", () => {
    const content = "### C#\n\n### Ruby\n\n### Haskell\n";
    const errors = checkFile(content, "test.md");
    expect(errors.some(e => e.includes('missing "### F#"'))).toBe(true);
    expect(errors.some(e => e.includes('missing "### Go"'))).toBe(true);
  });

  it("reports duplicate languages", () => {
    const lines = [...REQUIRED.map(l => `### ${l}`), "### Rust"]; // duplicate
    const content = lines.join("\n\n");
    const errors = checkFile(content, "test.md");
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('"### Rust" appears 2 times');
  });

  it("reports wrong order", () => {
    const reversed = [...REQUIRED].reverse();
    const content = reversed.map(l => `### ${l}`).join("\n\n");
    const errors = checkFile(content, "test.md");
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain("wrong language order");
  });

  it("handles escaped heading characters", () => {
    const content = REQUIRED.map(l => {
      const escaped = l.replace(/#/g, "\\#").replace(/\+/g, "\\+");
      return `### ${escaped}`;
    }).join("\n\n");
    expect(checkFile(content, "test.md")).toEqual([]);
  });

  it("includes the file path in error messages", () => {
    const errors = checkFile("### Rust\n", "docs/07-adt.md");
    expect(errors.every(e => e.startsWith("docs/07-adt.md:"))).toBe(true);
  });
});
