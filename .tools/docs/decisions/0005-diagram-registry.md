# 0005 — Diagram renderer registry + central theme

- **Status**: Accepted
- **Date**: 2026-04-28

## Context

Two diagram kinds (`ibd`, `activity`) need to coexist; more may follow. The first version had
per-kind rendering branches scattered across the codebase and visual constants (radii, gaps,
colours) inlined wherever they were used.

## Decision

- [sysml/render/index.ts](../../sysml/render/index.ts) holds a typed
  `Record<DiagramType, DiagramRenderer>` registry. A renderer is a small object exposing
  `plan(model, diag) → Plan`. Adding a new kind = one new module + one entry in the registry.
- All visual constants (sizes, paddings, palette, font sizes) live in
  [sysml/render/theme.ts](../../sysml/render/theme.ts). Renderers and edge helpers import from
  there; nothing visual is inline.
- Shared per-shape helpers (`render/nodes.ts`, `render/edges.ts`, `render/arrows.ts`,
  `render/frame.ts`, `render/title.ts`, `render/pin.ts`) are kind-agnostic.

## Consequences

- New diagram kind costs a single module + one registry entry, and inherits the shared shape
  primitives for free.
- Theme changes are one-file edits with predictable visual impact (snapshots catch the rest).
- The plan/render split keeps measurement-style logic out of the SVG emission code, which makes the
  latter easier to read.

Related: [0004](0004-xmlbuilder2-serialization.md).
