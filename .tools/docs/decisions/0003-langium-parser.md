# 0003 — Langium-generated parser

- **Status**: Accepted
- **Date**: 2026-04-28
- **Supersedes**: previous hand-rolled lexer + Chevrotain parser.

## Context

The first version of the SysML pipeline used a hand-rolled lexer plus a Chevrotain parser with
bespoke skip-block recovery. Adding new grammar constructs required edits in three places (lexer,
parser, and AST), which was error-prone, and the language had no editor support.

Alternatives considered:

- **Stay on Chevrotain** — known cost, but no editor support, and grammar changes remain three-place
  edits.
- **Tree-sitter** — excellent editor integration, but C build chain and trickier to embed in
  pure-Node tooling.
- **Langium** — pure TypeScript, code-generates parser + AST + TextMate grammar from a single
  `.langium` file, ships an LSP scaffold.

## Decision

- Grammar lives in [sysml/sysml.langium](../../sysml/sysml.langium).
- `langium-cli` generates `sysml/generated/{ast,grammar,module}.ts` plus
  `sysml/sysml.tmLanguage.json`.
- [sysml/parser.ts](../../sysml/parser.ts) bootstraps Langium services and adapts the generated AST
  into the existing repo AST shape (kind-discriminated unions in `sysml/types/`). The renderer is
  unchanged.
- A custom `SysmlValueConverter extends DefaultValueConverter` overrides `runConverter` for the
  `STRING` rule to keep the previous escape semantics (`\"` → `"`; `\n` etc. left literal). This was
  required to keep the SVG snapshot suite green during the swap.
- Generated files live in `sysml/generated/` and are marked `linguist-generated=true` via
  [.gitattributes](../../../.gitattributes). They are committed so contributors don't need to run
  `langium-gen` to read the code; CI / local builds still regenerate them.
- `chevrotain` removed from direct dependencies (Langium uses its own copy).

## Consequences

- Adding a new construct now means: edit `sysml.langium` → `make -C .tools langium-gen` → extend the
  adapter → done.
- Free TextMate grammar exported on every grammar change; consumed by the local VS Code extension
  ([0006](0006-local-vscode-extension.md)).
- Free LSP scaffold for live diagnostics, also consumed by that extension.
- One-time pain: Langium's `parse<T>` typing fights generic narrowing. We use `as any` at the single
  bootstrap site and immediately cast to a hand-written `{ value, lexerErrors, parserErrors }`
  shape.
- Langium's `DefaultValueConverter` auto-unescapes string content, which diverged from the previous
  behaviour. Locked down by the custom converter.
- The grammar still emits one cosmetic warning about `=` vs `+=` on the `diagram` assignment.
  Tracked in [state.md](../state.md).

Related: [0002](0002-snapshot-tests.md), [0006](0006-local-vscode-extension.md).
