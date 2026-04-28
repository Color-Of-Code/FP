# Architecture Decision Records

One file per significant decision. Each ADR has a `Status`, a `Context`, the `Decision`, and its
`Consequences`. Superseded ADRs stay in place; new ones get the next free number.

## Index

| #    | Title                                                                  | Status   |
| ---- | ---------------------------------------------------------------------- | -------- |
| 0001 | [Build orchestration via Make + pnpm](0001-build-orchestration.md)     | Accepted |
| 0002 | [Snapshot-based testing](0002-snapshot-tests.md)                       | Accepted |
| 0003 | [Langium-generated parser](0003-langium-parser.md)                     | Accepted |
| 0004 | [xmlbuilder2 for SVG serialization](0004-xmlbuilder2-serialization.md) | Accepted |
| 0005 | [Diagram renderer registry + theme](0005-diagram-registry.md)          | Accepted |
| 0006 | [Local-only VS Code extension](0006-local-vscode-extension.md)         | Accepted |
| 0007 | [ELK orthogonal routing with real ports](0007-orthogonal-routing.md)   | Accepted |

## Template

```markdown
# NNNN — Short title

- **Status**: Proposed | Accepted | Superseded by NNNN | Deprecated
- **Date**: YYYY-MM-DD

## Context

What problem are we solving? What were the constraints?

## Decision

What we chose, and the alternatives we rejected.

## Consequences

What follows from the choice — good and bad — and what stays open.
```
