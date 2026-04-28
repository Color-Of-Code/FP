# 0004 — xmlbuilder2 for SVG serialization

- **Status**: Accepted
- **Date**: 2026-04-28
- **Supersedes**: hand-rolled string concatenation.

## Context

Earlier the SVG output was produced by manual string concatenation + `outerHTML` from jsdom. The
output was sensitive to attribute order, quote style, and self-closing-tag rules — exactly the kind
of churn that wrecks snapshot tests.

## Decision

- All SVG attributes / elements are built via d3 selections on a jsdom-backed `<svg>` document.
- The final tree is serialised by **xmlbuilder2** with deterministic formatting: stable attribute
  order, double-quoted values, indentation, pretty-print on.
- See [sysml/lib/svg.ts](../../sysml/lib/svg.ts) for the wrapper.

## Consequences

- Output is deterministic across Node / jsdom versions (snapshot-safe).
- Visual constants (sizes, colours, fonts) are _not_ in the serialiser; they live in
  [sysml/render/theme.ts](../../sysml/render/theme.ts), see [0005](0005-diagram-registry.md).
- Adding new attributes is a single d3 `.attr()` call; no need to think about serialisation rules.
- xmlbuilder2 is one extra runtime dep but it's small and pure JS.

Related: [0002](0002-snapshot-tests.md).
