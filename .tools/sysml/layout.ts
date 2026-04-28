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
  // Side perpendicular to the layout flow.  In a left-to-right diagram this
  // is SOUTH; in a top-to-bottom diagram it is EAST.  We use it to route
  // decision → merge edges so they form a perpendicular "alternate-exit"
  // rail (UML/SysML convention: forward = primary path, perpendicular =
  // failure / null path).
  const altSide = rankdir === "TB" ? "EAST" : "SOUTH";
  const nodeIndex = new Map(nodes.map(n => [n.id, n]));

  // ── Build ELK children with per-action ports ─────────────────────────────
  const portIdOf = (nodeId: string, side: "in" | "out", pin: string): string =>
    `${nodeId}__${side}__${pin}`;

  // Pre-compute which nodes are merges (used for decision-port routing).
  const mergeIds = new Set(nodes.filter(n => n.kind === "merge").map(n => n.id));
  // Pre-compute which nodes are terminal sinks: object/final nodes with no
  // outgoing edges.  We pin them to the LAST layer so independent end-points
  // (e.g. `cityName` on the happy path and `nothing` on the failure path)
  // align vertically in the same column instead of stretching the canvas.
  const hasOutgoing = new Set<string>();
  const hasIncoming = new Set<string>();
  for (const e of edges) {
    if (!e.isNoteAttachment) {
      hasOutgoing.add(e.from);
      hasIncoming.add(e.to);
    }
  }
  const isTerminalSink = (n: GNode): boolean =>
    (n.kind === "object" || n.kind === "final") &&
    hasIncoming.has(n.id) &&
    !hasOutgoing.has(n.id);
  const isInitialSource = (n: GNode): boolean =>
    (n.kind === "object" || n.kind === "initial") &&
    hasOutgoing.has(n.id) &&
    !hasIncoming.has(n.id);
  // For each decision/merge node, collect outgoing/incoming edges so we can
  // attach side-hint ports.  Forward outputs exit on `outSide`; outputs that
  // feed a merge exit on `altSide` (forming the perpendicular fail-rail).
  const decisionPortIdOf = (nodeId: string, role: "in" | "outFwd" | "outAlt", i: number): string =>
    `${nodeId}__d__${role}__${i}`;

  // edgeIdx → port id, populated for edges that touch decision/merge nodes.
  const edgeSrcPort = new Map<number, string>();
  const edgeTgtPort = new Map<number, string>();

  const children: ElkNode[] = nodes.map(n => {
    if (n.kind === "decision" || n.kind === "merge") {
      // Index the edges in stable order so port ids match what we record.
      const inEdges:  { edge: GEdge; idx: number }[] = [];
      const outEdges: { edge: GEdge; idx: number }[] = [];
      edges.forEach((e, idx) => {
        if (e.to   === n.id) inEdges .push({ edge: e, idx });
        if (e.from === n.id) outEdges.push({ edge: e, idx });
      });
      const ports: ElkPort[] = [];
      // Merge nodes: all incoming edges share a single inbound port so ELK
      // routes them through one converging junction (the "bottom rail" look)
      // rather than distributing them across distinct points on the WEST side.
      // Decisions still get one inbound port per edge — they only ever have
      // one inbound edge in practice but the per-edge mapping is harmless.
      if (n.kind === "merge" && inEdges.length > 0) {
        const pid = decisionPortIdOf(n.id, "in", 0);
        ports.push({
          id: pid, width: 1, height: 1,
          layoutOptions: { "port.side": inSide },
        });
        inEdges.forEach(({ idx }) => edgeTgtPort.set(idx, pid));
      } else {
        inEdges.forEach(({ idx }, i) => {
          const pid = decisionPortIdOf(n.id, "in", i);
          ports.push({
            id: pid, width: 1, height: 1,
            layoutOptions: { "port.side": inSide },
          });
          edgeTgtPort.set(idx, pid);
        });
      }
      outEdges.forEach(({ edge, idx }, i) => {
        const toMerge = mergeIds.has(edge.to);
        // Decision → merge exits on the perpendicular side; everything else
        // continues forward.  Merges always emit forward.
        const side = (n.kind === "decision" && toMerge) ? altSide : outSide;
        const role = side === outSide ? "outFwd" : "outAlt";
        const pid = decisionPortIdOf(n.id, role, i);
        ports.push({
          id: pid, width: 1, height: 1,
          layoutOptions: { "port.side": side },
        });
        edgeSrcPort.set(idx, pid);
      });
      return {
        id: n.id, width: n.w, height: n.h, ports,
        layoutOptions: {
          "portConstraints":           "FIXED_SIDE",
          "elk.portAlignment.default": "CENTER",
        },
      };
    }
    if (n.kind !== "action") {
      const layoutOptions: Record<string, string> = {};
      if (isTerminalSink(n)) {
        layoutOptions["elk.layered.layering.layerConstraint"] = "LAST";
      } else if (isInitialSource(n)) {
        layoutOptions["elk.layered.layering.layerConstraint"] = "FIRST";
      }
      const child: ElkNode = { id: n.id, width: n.w, height: n.h };
      if (Object.keys(layoutOptions).length > 0) child.layoutOptions = layoutOptions;
      return child;
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

  const EDGE_LABEL_CHAR_W = 5.0;
  const EDGE_LABEL_PAD    = 4;
  const EDGE_LABEL_H      = 14;

  edges.forEach((e, i) => {
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt) return;

    const sourceId =
      edgeSrcPort.get(i) ??
      (src.kind === "action" && e.isObjectFlow && e.srcPin
        ? portIdOf(src.id, "out", e.srcPin)
        : src.id);
    const targetId =
      edgeTgtPort.get(i) ??
      (tgt.kind === "action" && e.isObjectFlow && e.dstPin
        ? portIdOf(tgt.id, "in", e.dstPin)
        : tgt.id);

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
      "elk.spacing.edgeNode":                              "8",
      "elk.spacing.edgeEdge":                              "10",
      "elk.spacing.edgeLabel":                             "4",
      "elk.edgeLabels.inline":                             "false",
      "elk.edgeLabels.placement":                          "CENTER",
      "elk.layered.edgeLabels.sideSelection":              "ALWAYS_DOWN",
      "elk.padding":                                       "[top=12,left=30,bottom=12,right=30]",
      "elk.layered.nodePlacement.strategy":                "NETWORK_SIMPLEX",
      "elk.layered.crossingMinimization.semiInteractive":  "true",
      "elk.layered.mergeEdges":                            "true",
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

  // ── Snap decision → merge polylines onto a single shared rail ────────────
  // ELK routes every alt-exit independently and pushes them to distinct
  // y-rails to avoid edge-edge overlap, producing visual zig-zags.  For the
  // "failure rail" idiom we *want* them on the same horizontal line; the
  // resulting overlap reads as one trunk being joined by tributaries.  Each
  // such edge is rewritten to a clean 2-bend L:  drop straight from the
  // source's exit port to the merge's inbound y, then run perpendicular into
  // the merge.  Also flag the edge so the renderer puts the label on the
  // short vertical (drop) segment near the decision, out of the rail.
  for (let i = 0; i < edges.length; i++) {
    const e = edges[i];
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt) continue;
    if (src.kind !== "decision" || tgt.kind !== "merge") continue;
    const path = edgePaths[i];
    if (path.length < 2) continue;
    const [sx, sy] = path[0];
    const [, ty] = path[path.length - 1];
    const tx = path[path.length - 1][0];
    if (rankdir === "LR") {
      // Drop south, then run east into the merge (or west if merge is left).
      edgePaths[i] = sx === tx
        ? [[sx, sy], [tx, ty]]
        : [[sx, sy], [sx, ty], [tx, ty]];
    } else {
      // TB layout: shift east, then run south into the merge.
      edgePaths[i] = sy === ty
        ? [[sx, sy], [tx, ty]]
        : [[sx, sy], [tx, sy], [tx, ty]];
    }
    e.labelNearSource = true;
  }

  return {
    width:  result.width  ?? 200,
    height: result.height ?? 100,
    edgePaths,
  };
}
