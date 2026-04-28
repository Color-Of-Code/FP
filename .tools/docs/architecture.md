# Architecture

This document describes how the `.tools/` pipeline is structured. For the _why_ behind individual
choices, see [decisions/](decisions/README.md).

## High-level pipeline

```text
.sysml source
     │
     ▼
┌──────────────────────────────┐
│ Langium-generated parser     │  sysml/sysml.langium
│ (sysml/generated/*.ts)       │  → langium-cli generate
└──────────────────────────────┘
     │  AST (Langium union types)
     ▼
┌──────────────────────────────┐
│ Adapter: parser.ts           │  custom SysmlValueConverter
│ → repo AST (types/ast.ts)    │  partitions members into
└──────────────────────────────┘  parts/ports/connections/...
     │  Model (kind-discriminated)
     ▼
┌──────────────────────────────┐
│ Diagram renderer registry    │  render/index.ts
│ ibd | activity               │
└──────────────────────────────┘
     │  GNode[] + GEdge[]
     ▼
┌──────────────────────────────┐
│ Layout + orthogonal routing  │  layout.ts
│ elkjs                        │
└──────────────────────────────┘
     │  positioned nodes + edge polylines
     ▼
┌──────────────────────────────┐
│ SVG synthesis                │  d3 selections + jsdom,
│ render/{nodes,edges,…}.ts    │  serialised by xmlbuilder2
└──────────────────────────────┘
     │
     ▼
   *.svg  (committed alongside the .sysml source)
```

## Source tree

| Path                          | Role                                                     |
| ----------------------------- | -------------------------------------------------------- |
| `Makefile`                    | One entry point per task; orchestrates everything        |
| `package.json`                | Root of the pnpm workspace (`fp-tools`)                  |
| `pnpm-workspace.yaml`         | Declares `vscode-sysml/` as a workspace member           |
| `tsconfig.json`               | TS config for `--experimental-strip-types` + strict mode |
| `vitest.config.ts`            | Snapshot test runner config                              |
| `check-lang-order.ts`         | Lints 9-language sections in `docs/*.md`                 |
| `langium-config.json`         | Drives `langium-cli generate`                            |
| `sysml/sysml.langium`         | Authoritative grammar (source of truth)                  |
| `sysml/generated/`            | langium-cli output: `ast.ts`, `grammar.ts`, `module.ts`  |
| `sysml/sysml.tmLanguage.json` | TextMate grammar (also generated)                        |
| `sysml/parser.ts`             | Langium-services bootstrap + adapter to the repo AST     |
| `sysml/types/`                | Repo-internal AST types (kind-discriminated unions)      |
| `sysml/cli.ts`                | CLI wrapper used by Makefile rules                       |
| `sysml/layout.ts`             | ELK layered layout + orthogonal edge routing             |
| `sysml/render/`               | Per-diagram renderers + shared edge/arrow/frame helpers  |
| `sysml/lib/svg.ts`            | jsdom + d3 + xmlbuilder2 plumbing                        |
| `sysml/parser.test.ts`        | AST snapshot tests (41 fixtures)                         |
| `sysml/render.test.ts`        | SVG snapshot tests (41 fixtures)                         |
| `sysml/__ast_snapshots__/`    | Committed AST JSON snapshots                             |
| `vscode-sysml/`               | Local VS Code extension (highlighting + LSP)             |

See also [decisions/0001-build-orchestration.md](decisions/0001-build-orchestration.md) for why we
picked this exact split.

## Build orchestration

Everything goes through `make -C .tools`. The Makefile targets fall into four groups:

- **Generation**: `svgs`, `sysml`, `langium-gen`, `vscode-ext`.
- **Quality**: `test`, `test-update`, `typecheck`, `lint-md`, `lint-langs`, `check-md`.
- **Formatting**: `fmt-md`, `fmt-d2`, `fmt`.
- **Setup**: `install`, `vscode-ext-link`.

`make -C .tools all` runs the production set: `svgs sysml fmt lint-md lint-langs typecheck test`.

Detailed table in [tooling spec](../../specs/tooling.md).

## SysML pipeline in detail

### Grammar and parser

- The grammar is defined in [sysml.langium](../sysml/sysml.langium). It is the only hand-written
  grammar artefact.
- `langium-cli generate` produces `sysml/generated/{ast,grammar,module}.ts` and
  `sysml/sysml.tmLanguage.json`.
- [parser.ts](../sysml/parser.ts) wires Langium services with a custom `SysmlValueConverter` that
  preserves the previous STRING semantics (`\"` is unescaped; `\n` etc. stay literal). This keeps
  SVG and AST snapshots byte-stable across the parser swap. See
  [decisions/0003-langium-parser.md](decisions/0003-langium-parser.md).
- The Langium AST uses union-typed `members[]` arrays; the adapter partitions these into the
  existing repo AST shape so the renderer is unchanged.

### Renderer registry

- [render/index.ts](../sysml/render/index.ts) dispatches on `model.diagram.diagType`.
- Currently registered: `ibd`, `activity`. (`initial` / `final` activity nodes are latent in the
  type system but not yet emitted.)
- Each renderer returns a `Plan` consumed by the SVG synthesis layer. See
  [decisions/0005-diagram-registry.md](decisions/0005-diagram-registry.md).

### Layout

- [layout.ts](../sysml/layout.ts) drives ELK with `algorithm: layered` and
  `edgeRouting: ORTHOGONAL`. ELK is the only engine.
- Action nodes expose real ELK ports for input/output pins (`portConstraints: FIXED_ORDER`, side
  derived from the diagram's rank direction). Edges that connect a known pin reference the port id
  in `sources` / `targets`; other edges connect to node centres.
- Edge geometry comes from `edge.sections[0]` and is emitted as a polyline (`M x0,y0 L … L xn,yn`)
  with rounded joins. The final segment is shortened by `ARROW_DEPTH` so the marker tip lands
  exactly on the target boundary.
- The `layout = dagre | elk` SysML field is still parsed for backward compat with existing fixtures,
  but its value is ignored at render time.
- See [decisions/0007-orthogonal-routing.md](decisions/0007-orthogonal-routing.md).

### SVG synthesis

- [lib/svg.ts](../sysml/lib/svg.ts) creates a jsdom-backed `<svg>` document and exposes d3-style
  selections for shape construction.
- The final output is serialised by **xmlbuilder2** to keep formatting deterministic. See
  [decisions/0004-xmlbuilder2-serialization.md](decisions/0004-xmlbuilder2-serialization.md).
- Visual constants (sizes, colours) live in `sysml/render/theme.ts`. Adding a new visual token is a
  single-file change.

## Tests

- 62 SysML fixtures discovered recursively under `docs/` (one per-chapter folder per concept, e.g.
  `docs/19-monad/`, `docs/monads/maybe/`).
- Each fixture is exercised twice:
  - [parser.test.ts](../sysml/parser.test.ts) → AST JSON snapshot.
  - [render.test.ts](../sysml/render.test.ts) → SVG file alongside the source.
- 124 snapshots in total (62 SysML × 2 layers); refreshed with `make -C .tools test-update` after
  intentional changes.
- See [decisions/0002-snapshot-tests.md](decisions/0002-snapshot-tests.md).

## VS Code extension

- Self-contained under [vscode-sysml/](../vscode-sysml/).
- Bundles the langium-cli-emitted TextMate grammar plus a Langium language server for live
  diagnostics.
- Installed locally either via `make -C .tools vscode-ext-link` (symlink into
  `~/.vscode/extensions/`) or `pnpm dlx @vscode/vsce package` followed by
  `code --install-extension *.vsix`. **No marketplace involvement.**
- See [decisions/0006-local-vscode-extension.md](decisions/0006-local-vscode-extension.md).
