# 0002 — Snapshot-based testing

- **Status**: Accepted
- **Date**: 2026-04-28

## Context

The SysML pipeline produces SVG files that get committed to the repo and referenced by Markdown
chapters. A naïve change to the renderer can silently break dozens of figures. We need a fast
feedback loop that catches regressions in:

- the parser AST shape,
- the SVG output (geometry, colours, escaping, attribute order).

The fixtures already exist as `.sysml` files alongside the expected `.svg` under `docs/diagrams/`,
`docs/monads/diagrams/`, `docs/optics/diagrams/`.

## Decision

Two Vitest test files exercise every fixture:

- [sysml/parser.test.ts](../../sysml/parser.test.ts) parses each `.sysml` and matches the AST
  against a JSON snapshot in [sysml/**ast_snapshots**/](../../sysml/__ast_snapshots__).
- [sysml/render.test.ts](../../sysml/render.test.ts) renders each `.sysml` and matches the SVG
  against the sibling `.svg` file.

Snapshots are intentionally byte-for-byte. Refresh with `make -C .tools test-update` after
intentional changes, then review the diff.

## Consequences

- 82 snapshots gate every renderer or parser change. Cheap (~2 s).
- Refactors that need to keep output stable (e.g. swapping the parser) can prove parity by passing
  the suite without `-u`.
- AST snapshots remain valid even when SVG output is intentionally rewritten, so model-level
  regressions remain catchable independently of layout changes.
- Snapshot churn is expected on visual changes; reviewers must read the diff, not just trust the
  green test.
- We accept that snapshots can't detect overlap / collision issues; for that we rely on visual
  review.

Related: [0003](0003-langium-parser.md), [0004](0004-xmlbuilder2-serialization.md).
