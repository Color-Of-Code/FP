# 0007 — ELK orthogonal routing with real ports

- **Status**: Accepted
- **Date**: 2026-04-28

## Context

Current routing uses dagre or elkjs for **node placement only**. Edge geometry is hand-rolled in
[sysml/render/edges.ts](../../sysml/render/edges.ts): each edge becomes a single cubic Bézier with
manual endpoint clipping per node shape, plus a small custom indexer that snaps action-node edges to
pin slots. Symptoms observed:

- Curvy edges that overlap node bodies on dense diagrams.
- Strong directional bias from layered layout, with no orthogonal recovery.
- Branch-spacing band-aided by injecting invisible separator nodes
  (`activity.ts:injectBranchSeparators`).
- Decision-to-merge "null branch" edges need a manual south-exit hack.

Alternatives considered:

| Option                           | Verdict                                                                       |
| -------------------------------- | ----------------------------------------------------------------------------- |
| `d3-force` / physics             | Rejected — organic & non-deterministic; breaks snapshots and the visual goal. |
| Graphviz `dot` (native binary)   | Rejected — best orthogonal output, but breaks the pure-JS pipeline.           |
| Mermaid                          | Not a layout engine.                                                          |
| `libavoid` JS port               | Unmaintained.                                                                 |
| Cytoscape orthogonal             | Comparable to ELK but less polished.                                          |
| Hand-rolled Manhattan A\* router | Large effort; ELK already does this.                                          |

## Decision

Switch ELK from "node placer" to **full layout + routing** with real ports. Drop dagre.

Phases:

1. Make ELK the only engine. Pass `elk.algorithm: layered`, `elk.edgeRouting: ORTHOGONAL`,
   `elk.layered.crossingMinimization.semiInteractive: true`,
   `elk.layered.nodePlacement.strategy: NETWORK_SIMPLEX`, and tuned `spacing.*` knobs.
2. Give action nodes real ELK child ports (`elk.portConstraints: FIXED_SIDE`, west = inputs, east =
   outputs; flipped for `TB`). Edges reference port ids in `sources` / `targets`.
3. Replace cubic-Bézier emission with polylines built from `edge.sections[0]`
   (`M x0,y0 L … L xn,yn`, optional `stroke-linejoin round`). Drop manual
   `clipToBox / Diamond / Circle`.
4. Use ELK `position` hints derived from SysML source order to bias layer placement; remove the
   separator-node hack.
5. Refresh all 41 SVG snapshots; keep AST snapshots untouched.

## Consequences

### Wins

- Clean axis-aligned routing with proper obstacle avoidance.
- Routing logic moves out of our codebase into ELK; less hand-rolled geometry to maintain.
- Source-order hints replace the separator-node hack.
- Dropping dagre simplifies dependencies (one engine, one set of options).

### Costs

- Wholesale visual diff on every committed SVG; one-time review burden.
- ELK port wiring is more verbose at the renderer level (must build child ports + reference them by
  id).
- Loss of fine-grained Bézier control we currently exercise (e.g. the decision-to-merge custom
  routing). Need to verify ELK's output covers these cases acceptably.
- IBD frame ports stay decorative for now; promoting them to real graph ports is a separate optional
  follow-up.

### Verification

- `make -C .tools test` after `test-update`.
- Visual spot-check of 6–8 representative diagrams.
- Optional new test: every emitted `<path>` uses only `M`/`L` commands (guards against regressions
  back to curved routing).

Related: [0005](0005-diagram-registry.md).

## Implementation

Landed as a single rewrite touching:

- [sysml/layout.ts](../../sysml/layout.ts) — single `layoutGraph(nodes, edges, rankdir)` returning
  `{ width, height, edgePaths }`. Builds ELK children with action-node ports
  (`portConstraints: FIXED_ORDER`, side derived from `rankdir`, port id =
  `<nodeId>__<in|out>__<pinName>`) and ELK edges that reference those port ids when an endpoint is
  an action with a known pin.
- [sysml/render/edges.ts](../../sysml/render/edges.ts) — polyline emission from `edge.sections[0]`
  with `stroke-linejoin/linecap: round`. Final segment shortened by `ARROW_DEPTH` so the marker tip
  lands exactly on the boundary. Label placed at the midpoint of the longest segment.
- [sysml/render/pin.ts](../../sysml/render/pin.ts) — replaced slot-index logic with
  `assignActionPins(edges, nodeMap)` which sets `e.srcPin` / `e.dstPin` to **pin names** matched by
  shared name, then by object id, then by declaration order.
- [sysml/render/activity.ts](../../sysml/render/activity.ts) and
  [sysml/render/ibd.ts](../../sysml/render/ibd.ts) — call `assignActionPins` then await
  `layoutGraph`; shift node coords and edge polylines by the frame padding.
- [sysml/types/graph.ts](../../sysml/types/graph.ts) — `GEdge` gained `srcPin?` / `dstPin?`; removed
  `isSeparator`, `isSouthExit`, `minlen`, and the `"separator"` node kind.
- Theme: removed `BRANCH_SEP_H`; updated layout-spacing comments to reference ELK.
- Dropped `@dagrejs/dagre` from `dependencies`.
- Parser still accepts `layout = dagre|elk` for backward compat with existing SysML fixtures, but
  the value is ignored at render time.

All 82 snapshots green (41 AST unchanged, 41 SVG refreshed in the same commit).
