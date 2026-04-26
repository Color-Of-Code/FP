/**
 * Graph layout: dagre (default, sync) and elkjs (async, better edge routing).
 * Both mutate GNode positions in-place and return computed [width, height].
 */

import dagre from "@dagrejs/dagre";
import ELK   from "elkjs/lib/elk.bundled.js";
import type { GNode, GEdge } from "./types.ts";
import { nodeDims, EDGE_GAP, NODE_VGAP } from "./types.ts";

// ── Dagre (sync) ───────────────────────────────────────────────────────────

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
      g.setEdge(e.from, e.to, {
        weight: e.isSeparator ? 0 : 1,
        minlen: e.minlen ?? 1,
      }, `e${i}`);
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

// ── ELK (async, better edge routing for HOF inputs) ───────────────────────

const elk = new ELK();

export async function elkLayout(
  nodes: GNode[],
  edges: GEdge[],
  rankdir: "LR" | "TB" = "LR",
): Promise<[number, number]> {
  if (nodes.length === 0) return [200, 100];

  for (const n of nodes) { [n.w, n.h] = nodeDims(n); }

  const direction = rankdir === "TB" ? "DOWN" : "RIGHT";
  const nodeSet   = new Set(nodes.map(n => n.id));

  const graph = {
    id: "root",
    layoutOptions: {
      "elk.algorithm":                              "layered",
      "elk.direction":                              direction,
      "elk.layered.spacing.nodeNodeBetweenLayers":  String(EDGE_GAP),
      "elk.spacing.nodeNode":                       String(NODE_VGAP),
      "elk.padding":                                "[top=30,left=30,bottom=30,right=30]",
      "elk.layered.nodePlacement.strategy":         "BRANDES_KOEPF",
    },
    children: nodes.map(n => ({ id: n.id, width: n.w, height: n.h })),
    edges: edges
      .filter(e => !e.isSeparator && nodeSet.has(e.from) && nodeSet.has(e.to))
      .map((e, i) => ({ id: `e${i}`, sources: [e.from], targets: [e.to] })),
  };

  const result = await elk.layout(graph);

  const childMap = new Map((result.children ?? []).map(c => [c.id, c]));
  for (const n of nodes) {
    const c = childMap.get(n.id);
    if (c?.x !== undefined && c?.y !== undefined) {
      n.x = c.x + n.w / 2;
      n.y = c.y + n.h / 2;
    }
  }

  return [result.width ?? 200, result.height ?? 100];
}

// ── Unified async dispatcher ───────────────────────────────────────────────

export async function autoLayout(
  nodes: GNode[],
  edges: GEdge[],
  engine: "dagre" | "elk" = "dagre",
  rankdir: "LR" | "TB"   = "LR",
): Promise<[number, number]> {
  if (engine === "elk") return elkLayout(nodes, edges, rankdir);
  return Promise.resolve(layeredLayout(nodes, edges, rankdir));
}
