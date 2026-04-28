/**
 * Graph layout: ELK-based layered placement plus orthogonal edge routing.
 *
 * `layoutGraph` returns both node positions (mutated in place) AND the
 * polyline geometry of every routed edge.  Action nodes contribute one ELK
 * port per pin so edges connect to the correct slot — there is no
 * post-layout boundary clipping or pin-slot snapping any more.
 */

import ELK from "elkjs/lib/elk.bundled.js";
import type { GNode, GEdge } from "./types.ts";
import { nodeDims, EDGE_GAP, NODE_VGAP, PIN_SZ } from "./types.ts";

/** A routed polyline.  Always at least two points (start and end). */
export type EdgePolyline = readonly (readonly [number, number])[];

export interface LayoutResult {
  width:  number;
  height: number;
  /** Polyline geometry per edge, in input order.  Empty array for skipped edges. */
  edgePaths: EdgePolyline[];
}

const elk = new ELK();

// ── ELK graph types (only the bits we use) ────────────────────────────────

interface ElkPort {
  id: string;
  width?: number;
  height?: number;
  layoutOptions?: Record<string, string>;
  x?: number; y?: number;
}

interface ElkNode {
  id: string;
  width?: number; height?: number;
  ports?: ElkPort[];
  layoutOptions?: Record<string, string>;
  x?: number; y?: number;
}

interface ElkPoint { x: number; y: number; }
interface ElkEdgeSection {
  startPoint: ElkPoint;
  endPoint: ElkPoint;
  bendPoints?: ElkPoint[];
}
interface ElkEdgeOut {
  id: string;
  sections?: ElkEdgeSection[];
}

interface ElkResult {
  width?: number;
  height?: number;
  children?: (ElkNode & { x?: number; y?: number; ports?: (ElkPort & { x?: number; y?: number })[] })[];
  edges?: ElkEdgeOut[];
}

// ── Public API ─────────────────────────────────────────────────────────────

/**
 * Run ELK layered + orthogonal routing on the graph.
 *
 * Node `x`/`y` are written back as the centre of each node (matching the
 * existing renderer convention).  The returned `edgePaths[i]` is the routed
 * polyline for `edges[i]`, in absolute SVG coordinates, including the start
 * and end points.  Skipped edges (separator / unknown endpoints) get `[]`.
 */
export async function layoutGraph(
  nodes: GNode[],
  edges: GEdge[],
  rankdir: "LR" | "TB" = "LR",
): Promise<LayoutResult> {
  if (nodes.length === 0) {
    return { width: 200, height: 100, edgePaths: edges.map(() => []) };
  }

  // Make sure widths/heights are up to date with current label content.
  for (const n of nodes) { [n.w, n.h] = nodeDims(n); }

  const direction = rankdir === "TB" ? "DOWN" : "RIGHT";
  const inSide  = rankdir === "TB" ? "NORTH" : "WEST";
  const outSide = rankdir === "TB" ? "SOUTH" : "EAST";
  const nodeIndex = new Map(nodes.map(n => [n.id, n]));

  // ── Build ELK children with per-action ports ─────────────────────────────
  const portIdOf = (nodeId: string, side: "in" | "out", pin: string): string =>
    `${nodeId}__${side}__${pin}`;

  const children: ElkNode[] = nodes.map(n => {
    if (n.kind !== "action") {
      return { id: n.id, width: n.w, height: n.h };
    }
    const ports: ElkPort[] = [];
    n.inPins.forEach((pin, i) => {
      ports.push({
        id: portIdOf(n.id, "in", pin),
        width: PIN_SZ, height: PIN_SZ,
        layoutOptions: {
          "port.side":  inSide,
          "port.index": String(n.inPins.length - 1 - i),
        },
      });
    });
    n.outPins.forEach((pin, i) => {
      ports.push({
        id: portIdOf(n.id, "out", pin),
        width: PIN_SZ, height: PIN_SZ,
        layoutOptions: {
          "port.side":  outSide,
          "port.index": String(i),
        },
      });
    });
    return {
      id: n.id,
      width: n.w, height: n.h,
      ports,
      layoutOptions: {
        "portConstraints":            "FIXED_ORDER",
        "elk.portAlignment.default":  "DISTRIBUTED",
      },
    };
  });

  // ── Build ELK edges ──────────────────────────────────────────────────────
  // We attach the user-supplied edge label as an ELK edge label with
  // approximate width/height so ELK reserves enough horizontal space between
  // layers for the text to render legibly.  Without this, long labels
  // ("f(a0) — Right b' or Left e'") get clipped or visually overlap nearby
  // nodes.  The empirical char-width of 5.5 matches the 9pt sans-serif the
  // edge renderer uses; the +12 padding is breathing room either side.
  interface ElkLabelIn {
    text: string;
    width: number;
    height: number;
  }
  type ElkEdgeIn = {
    id: string;
    sources: string[];
    targets: string[];
    labels?: ElkLabelIn[];
  };
  const elkEdges: ElkEdgeIn[] = [];
  /** Map from `e<i>` ids back into the original `edges[]` index. */
  const elkEdgeIdToOrig = new Map<string, number>();

  const EDGE_LABEL_CHAR_W = 5.5;
  const EDGE_LABEL_PAD    = 12;
  const EDGE_LABEL_H      = 14;

  edges.forEach((e, i) => {
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt) return;

    const sourceId = src.kind === "action" && e.isObjectFlow && e.srcPin
      ? portIdOf(src.id, "out", e.srcPin)
      : src.id;
    const targetId = tgt.kind === "action" && e.isObjectFlow && e.dstPin
      ? portIdOf(tgt.id, "in", e.dstPin)
      : tgt.id;

    const id = `e${i}`;
    elkEdgeIdToOrig.set(id, i);
    const elkEdge: ElkEdgeIn = { id, sources: [sourceId], targets: [targetId] };
    if (e.label && e.label.length > 0) {
      elkEdge.labels = [{
        text: e.label,
        width:  Math.ceil(e.label.length * EDGE_LABEL_CHAR_W) + EDGE_LABEL_PAD,
        height: EDGE_LABEL_H,
      }];
    }
    elkEdges.push(elkEdge);
  });

  // ── Run ELK ──────────────────────────────────────────────────────────────
  const graph = {
    id: "root",
    layoutOptions: {
      "elk.algorithm":                                     "layered",
      "elk.direction":                                     direction,
      "elk.edgeRouting":                                   "ORTHOGONAL",
      "elk.layered.spacing.nodeNodeBetweenLayers":         String(EDGE_GAP),
      "elk.spacing.nodeNode":                              String(NODE_VGAP),
      "elk.spacing.edgeNode":                              "16",
      "elk.spacing.edgeEdge":                              "10",
      "elk.spacing.edgeLabel":                             "4",
      "elk.edgeLabels.inline":                             "false",
      "elk.edgeLabels.placement":                          "CENTER",
      "elk.layered.edgeLabels.sideSelection":              "ALWAYS_DOWN",
      "elk.padding":                                       "[top=12,left=30,bottom=12,right=30]",
      "elk.layered.nodePlacement.strategy":                "NETWORK_SIMPLEX",
      "elk.layered.crossingMinimization.semiInteractive":  "true",
      "elk.layered.mergeEdges":                            "false",
    },
    children,
    edges: elkEdges,
  };

  const result = (await elk.layout(graph as never)) as ElkResult;

  // ── Scatter node positions back ──────────────────────────────────────────
  const childMap = new Map((result.children ?? []).map(c => [c.id, c]));
  for (const n of nodes) {
    const c = childMap.get(n.id);
    if (c?.x !== undefined && c?.y !== undefined) {
      n.x = c.x + n.w / 2;
      n.y = c.y + n.h / 2;
    }
  }

  // ── Scatter routed edge polylines back ───────────────────────────────────
  const edgePaths: EdgePolyline[] = edges.map(() => [] as EdgePolyline);
  for (const re of result.edges ?? []) {
    const origIdx = elkEdgeIdToOrig.get(re.id);
    if (origIdx === undefined) continue;
    const sec = re.sections?.[0];
    if (!sec) continue;
    const pts: [number, number][] = [
      [sec.startPoint.x, sec.startPoint.y],
      ...(sec.bendPoints ?? []).map(p => [p.x, p.y] as [number, number]),
      [sec.endPoint.x, sec.endPoint.y],
    ];
    edgePaths[origIdx] = pts;
  }

  return {
    width:  result.width  ?? 200,
    height: result.height ?? 100,
    edgePaths,
  };
}
