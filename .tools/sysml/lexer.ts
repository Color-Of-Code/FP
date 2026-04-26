/**
 * Lexer for SysML v2 textual notation subset.
 * Produces a flat token array from source text.
 */

export function tokenise(src: string): string[] {
  const tokens: string[] = [];
  let i = 0;
  while (i < src.length) {
    // whitespace
    if (/\s/.test(src[i])) { i++; continue; }
    // line comment
    if (src[i] === "/" && src[i + 1] === "/") {
      while (i < src.length && src[i] !== "\n") i++;
      continue;
    }
    // block comment
    if (src[i] === "/" && src[i + 1] === "*") {
      i += 2;
      while (i < src.length && !(src[i] === "*" && src[i + 1] === "/")) i++;
      i += 2;
      continue;
    }
    // quoted string
    if (src[i] === '"') {
      let s = '"'; i++;
      while (i < src.length && src[i] !== '"') {
        if (src[i] === "\\" && i + 1 < src.length) { s += src[i] + src[i + 1]; i += 2; }
        else { s += src[i++]; }
      }
      s += '"'; i++;
      tokens.push(s);
      continue;
    }
    // punctuation
    if ("{}:;,#=.[]".includes(src[i])) { tokens.push(src[i++]); continue; }
    // identifier (may include <> for generics)
    let id = "";
    while (i < src.length && /[\w<>]/.test(src[i])) id += src[i++];
    if (id) { tokens.push(id); continue; }
    i++;
  }
  return tokens;
}
