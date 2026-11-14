# Current state

A snapshot of what exists, what is verified, and what is known to be sub-optimal. Update this in the
same commit as any non-trivial change.

## What exists

### Build & quality gates (all driven by `make -C .tools`)

- `install` — pnpm workspace install.
- `svgs`, `sysml` — SysML → SVG.
- `langium-gen` — regenerate parser/AST from the grammar.
- `vscode-ext`, `vscode-ext-link` — build / install the local VS Code extension.
- `test`, `test-update`, `typecheck`, `lint` — Vitest snapshots, `tsc --noEmit`, and ESLint.
- `fmt-md`, `fmt`, `lint-md`, `lint-langs`, `lint-diagrams`, `check-md`.

### Parser

- Grammar in [sysml/sysml.langium](../sysml/sysml.langium). Generated artefacts in
  `sysml/generated/`.
- Adapter in [sysml/parser.ts](../sysml/parser.ts) flattens Langium's union-typed `members[]` into
  the repo AST shape.
- Custom `SysmlValueConverter` preserves STRING-escape behaviour for snapshot parity.

### Diagrams

Two diagram kinds emitted:

- `ibd` (internal block diagram) — block frame + parts + connections + decorative boundary ports.
- `activity` — actions, objects, decisions, merges, flows, successions.

Layout and orthogonal edge routing both come from ELK
([decisions/0007-orthogonal-routing.md](decisions/0007-orthogonal-routing.md)). Action nodes use
real ELK ports for input/output pins; edges are emitted as polylines from the routed
`edge.sections`. The `layout = dagre | elk` field is still parsed for backward compat with existing
fixtures but is ignored at render time.

### Tests

- SysML source fixtures cover every diagram source under `docs/`; parser and render snapshots guard
  their structure and generated SVGs.
- AST snapshots in [sysml/**ast_snapshots**/](../sysml/__ast_snapshots__).
- SVGs are committed alongside `.sysml` sources in chapter and detail-page folders.
- `make -C .tools test` covers parser/render snapshots and renderer behavior.

### VS Code extension

- Local extension at [vscode-sysml/](../vscode-sysml/) — TextMate highlighting
  - Langium LSP diagnostics. Install via `make -C .tools vscode-ext-link`. See
    [extension README](../vscode-sysml/README.md).

### Toolchain pinning

- `packageManager: "pnpm@10.28.2"` in [package.json](../package.json).
- `langium` and `langium-cli` `^4.2.x`.
- `typescript ^6.0.3` (uses `--experimental-strip-types` so source `.ts` runs via `node` directly
  without a build step).

## What works well

- Snapshot tests catch every layout / serialisation regression.
- Single source of truth for the grammar; adding a keyword is one grammar edit +
  `make -C .tools langium-gen`.
- pnpm workspace shares `langium` / `typescript` between the tooling and the extension; no
  per-package duplication.
- Markdown and TypeScript are formatted by separate idempotent tools, no cross-contamination.

## Known issues / open work

- **`lint-langs` skip list** — `.tools/check-lang-order.ts` carries a `SKIP_FILES` set; only
  discussion chapters belong there. See [AGENTS.md](../../AGENTS.md). No tooling change required,
  but the list must be reviewed when chapters are renamed.
- **Latent activity nodes** — `initial` / `final` are typed in
  [sysml/types/graph.ts](../sysml/types/graph.ts) but the activity renderer doesn't emit them.
  Either implement or remove.
- **IBD frame ports** — drawn decoratively; not first-class graph nodes, so edges cannot connect to
  them. Tracked alongside the routing redesign.
- **Langium grammar warning** — `langium-cli` emits _"Found multiple assignments to 'diagram' with
  the '=' assignment operator"_ on every run. Cosmetic; rules with `+=` would be a future tidy.

## Versions in use (snapshot)

| Tool        | Version                                       |
| ----------- | --------------------------------------------- |
| pnpm        | 10.28.2                                       |
| Node        | ≥ 22 (relies on `--experimental-strip-types`) |
| TypeScript  | 6.0.3                                         |
| Langium     | 4.2.2                                         |
| langium-cli | 4.2.1                                         |
| Vitest      | 4.1.5                                         |
| elkjs       | 0.11.x                                        |
| d3          | 7.9.x                                         |
| jsdom       | 26.1.x                                        |
| xmlbuilder2 | 4.0.x                                         |

## Out of scope (intentionally)

- No npm publishing, no marketplace publishing.
- No CI workflow definitions; build is local-only by design.
- No watch mode; SVGs are produced on demand or in bulk via `make`.
