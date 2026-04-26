/**
 * Graph layout using dagre (Sugiyama-style layered layout, left→right by default).
 * Mutates GNode positions in-place, returns computed [width, height].
 */

import dagre from "@dagrejs/dagre";
import type { GNode, GEdge } from "./types.ts";
import { nodeDims, EDGE_GAP, NODE_VGAP } from "./types.ts";

export function layeredLayout(
  nodes: GNode[],
  edges: GEdge[],
  rankdir: "LR" | "TB" = "LR",
): [number, number] {
  if (nodes.length === 0) return [200, 100];

  // Ensure w/h are set from label content
  for (const n of nodes) { [n.w, n.h] = nodeDims(n); }

  const g = new dagre.graphlib.Graph({ multigraph: true });
  g.setGraph({
    rankdir,
    nodesep: NODE_VGAP,
    ranksep: EDGE_GAP,
    marginx: 30,
    marginy: 30,
  });
  g.setDefaultEdgeLabel(() => ({}));

  for (const n of nodes) {
    g.setNode(n.id, { width: n.w, height: n.h });
  }
  edges.forEach((e, i) => {
    if (g.hasNode(e.from) && g.hasNode(e.to)) {
      g.setEdge(e.from, e.to, {}, `e${i}`);
    }
  });

  dagre.layout(g);

  for (const n of nodes) {
    const pos = g.node(n.id);
    n.x = pos.x;
    n.y = pos.y;
  }

  const meta = g.graph();
  return [meta.width ?? 200, meta.height ?? 100];
}
