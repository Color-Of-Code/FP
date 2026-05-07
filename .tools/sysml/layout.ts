/**
 * Graph layout: ELK-based layered placement plus orthogonal edge routing.
 *
 * The public entry point is `layoutGraph`, which orchestrates a pipeline of
 * smaller, focused functions:
 *
 *   buildContext  →  buildElkGraph  →  ELK  →  applyElkPositions
 *     →  adjustLanePositions  →  computeCanvasAndLanes
 *     →  extractEdgePaths  →  straightenLaneEdges  →  snapDecisionMergeEdges
 *
 * Node `x`/`y` are written back as the centre of each node (matching the
 * existing renderer convention).
 */

import ELK from "elkjs/lib/elk.bundled.js";
import type { GNode, GEdge } from "./types.ts";
import { nodeDims, EDGE_GAP, NODE_VGAP, PIN_SZ } from "./types.ts";
import { indexBy } from "./lib/fp.ts";

// ── Public types ──────────────────────────────────────────────────────────

/** A routed polyline.  Always at least two points (start and end). */
export type EdgePolyline = readonly (readonly [number, number])[];

/** Definition of a swimlane for the layout engine. */
export interface LaneSpec {
  id:      string;
  label?:  string;
  members: string[];
}

/** Geometry of one rendered lane band (absolute SVG coordinates). */
export interface LaneGeom {
  id:     string;
  label?: string;
  x:      number;
  y:      number;
  w:      number;
  h:      number;
}

export interface LayoutResult {
  width:  number;
  height: number;
  /** Polyline geometry per edge, in input order.  Empty array for skipped edges. */
  edgePaths: EdgePolyline[];
  /** Geometry for each lane band, in lane-declaration order.  Empty when no lanes. */
  lanes:    LaneGeom[];
}

// ── Internal ELK types ────────────────────────────────────────────────────

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
  children?: ElkNode[];
  labels?: { text: string; width?: number; height?: number; layoutOptions?: Record<string, string> }[];
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
  children?: (ElkNode & { x?: number; y?: number; ports?: (ElkPort & { x?: number; y?: number })[]; children?: ElkNode[] })[];
  edges?: ElkEdgeOut[];
}
interface ElkLabelIn {
  text: string;
  width: number;
  height: number;
}
interface ElkEdgeIn {
  id: string;
  sources: string[];
  targets: string[];
  labels?: ElkLabelIn[];
}

// ── Constants ─────────────────────────────────────────────────────────────

const EDGE_LABEL_CHAR_W   = 5.0;
const EDGE_LABEL_PAD      = 4;
const EDGE_LABEL_H        = 14;
const LANE_TOP            = 14;
const LANE_ROW            = 74;
const LANE_PAD_Y          = 12;
const LANE_HEADER_H       = 18;
const TOP_LANE_CLEARANCE  = 10;
const TOP_LANE_NODE_SHIFT   = 8;
const LOWER_LANE_NODE_SHIFT = 14;

// ── Port ID helpers (pure, module-level) ──────────────────────────────────

const portIdOf = (nodeId: string, side: "in" | "out", pin: string): string =>
  `${nodeId}__${side}__${pin}`;

const decisionPortIdOf = (nodeId: string, role: "in" | "outFwd" | "outAlt", i: number): string =>
  `${nodeId}__d__${role}__${i}`;

const objectPortIdOf = (nodeId: string, side: string): string =>
  `${nodeId}__obj__${side}`;

// ── LayoutContext ─────────────────────────────────────────────────────────

/** Pre-computed lookup tables shared across layout phases. */
export interface LayoutContext {
  readonly nodeIndex:  Map<string, GNode>;
  readonly mergeIds:   Set<string>;
  readonly hasOutgoing: Set<string>;
  readonly hasIncoming: Set<string>;
  readonly useLanes:   boolean;
  readonly lanes:      readonly LaneSpec[];
  readonly rankdir:    "LR" | "TB";
  readonly direction:  string;
  readonly leafRankdir: "LR" | "TB";
  readonly inSide:     string;
  readonly outSide:    string;
  readonly altSide:    string;
  /** nodeId → laneId (empty when no lanes). */
  readonly laneOf:     Map<string, string>;
  /** nodeId → lane index (empty when no lanes). */
  readonly laneRankOf: Map<string, number>;
}

export function buildContext(
  nodes: readonly GNode[],
  edges: readonly GEdge[],
  rankdir: "LR" | "TB",
  lanes: readonly LaneSpec[],
): LayoutContext {
  const nodeIndex = indexBy(nodes, n => n.id);
  const mergeIds = new Set(nodes.filter(n => n.kind === "merge").map(n => n.id));
  const hasOutgoing = new Set<string>();
  const hasIncoming = new Set<string>();
  for (const e of edges) {
    if (!e.isNoteAttachment) {
      hasOutgoing.add(e.from);
      hasIncoming.add(e.to);
    }
  }
  const useLanes = lanes.length > 0;
  const direction = rankdir === "TB" ? "DOWN" : "RIGHT";
  const leafRankdir = rankdir;
  const inSide  = leafRankdir === "TB" ? "NORTH" : "WEST";
  const outSide = leafRankdir === "TB" ? "SOUTH" : "EAST";
  const altSide = leafRankdir === "TB" ? "EAST"  : "SOUTH";

  const laneOf = new Map<string, string>();
  const laneRankOf = new Map<string, number>();
  lanes.forEach((l, i) => l.members.forEach(m => {
    laneOf.set(m, l.id);
    laneRankOf.set(m, i);
  }));

  return {
    nodeIndex, mergeIds, hasOutgoing, hasIncoming,
    useLanes, lanes, rankdir, direction, leafRankdir,
    inSide, outSide, altSide, laneOf, laneRankOf,
  };
}

function isTerminalSink(n: GNode, ctx: LayoutContext): boolean {
  return (n.kind === "object" || n.kind === "final") &&
    ctx.hasIncoming.has(n.id) && !ctx.hasOutgoing.has(n.id);
}

function isInitialSource(n: GNode, ctx: LayoutContext): boolean {
  return (n.kind === "object" || n.kind === "initial") &&
    !n.isHof && ctx.hasOutgoing.has(n.id) && !ctx.hasIncoming.has(n.id);
}

// ── ELK graph construction ────────────────────────────────────────────────

interface ElkGraphResult {
  graph: {
    id: string;
    layoutOptions: Record<string, string>;
    children: ElkNode[];
    edges: ElkEdgeIn[];
  };
  /** Map from ELK edge id (`e0`, `e1`, …) back to the original `edges[]` index. */
  elkEdgeIdToOrig: Map<string, number>;
}

/**
 * Build the full ELK input graph from nodes, edges, and context.
 *
 * Side effects: may set `tgt.pinSides` for cross-lane action nodes.
 */
export function buildElkGraph(
  nodes: readonly GNode[],
  edges: readonly GEdge[],
  ctx: LayoutContext,
): ElkGraphResult {
  const { nodeIndex, mergeIds, inSide, outSide, altSide, leafRankdir, useLanes } = ctx;

  // ── Cross-lane pin-side overrides ──────────────────────────────────────
  const pinSideOverride = new Map<string, string>();
  const objectSrcPort = new Map<number, string>();
  const objectPorts = new Map<string, { side: string; portId: string }[]>();

  if (useLanes) {
    edges.forEach((e, idx) => {
      if (!e.isObjectFlow || !e.dstPin) return;
      const src = nodeIndex.get(e.from);
      const tgt = nodeIndex.get(e.to);
      if (!src || !tgt || src.kind !== "object" || tgt.kind !== "action") return;
      const sr = ctx.laneRankOf.get(src.id);
      const tr = ctx.laneRankOf.get(tgt.id);
      if (sr === undefined || tr === undefined || sr === tr) return;
      let actSide: string, objSide: string;
      if (leafRankdir === "TB") {
        actSide = sr < tr ? "WEST"  : "EAST";
        objSide = sr < tr ? "EAST"  : "WEST";
      } else {
        actSide = sr < tr ? "NORTH" : "SOUTH";
        objSide = sr < tr ? "SOUTH" : "NORTH";
      }
      pinSideOverride.set(portIdOf(tgt.id, "in", e.dstPin), actSide);
      const compass = actSide[0] as "N" | "S" | "E" | "W";
      tgt.pinSides = { ...(tgt.pinSides ?? {}), [e.dstPin]: compass };

      const portId = objectPortIdOf(src.id, objSide);
      const list = objectPorts.get(src.id) ?? [];
      if (!list.find(p => p.portId === portId)) list.push({ side: objSide, portId });
      objectPorts.set(src.id, list);
      objectSrcPort.set(idx, portId);
    });
  }

  // ── Build decision/merge port tables ───────────────────────────────────
  const edgeSrcPort = new Map<number, string>();
  const edgeTgtPort = new Map<number, string>();

  // ── Build ELK children ─────────────────────────────────────────────────
  const children: ElkNode[] = nodes.map(n => {
    if (n.kind === "decision" || n.kind === "merge") {
      const inEdges:  { edge: GEdge; idx: number }[] = [];
      const outEdges: { edge: GEdge; idx: number }[] = [];
      edges.forEach((e, idx) => {
        if (e.to   === n.id) inEdges .push({ edge: e, idx });
        if (e.from === n.id) outEdges.push({ edge: e, idx });
      });
      const ports: ElkPort[] = [];
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
      if (isTerminalSink(n, ctx)) {
        layoutOptions["elk.layered.layering.layerConstraint"] = "LAST";
      } else if (isInitialSource(n, ctx)) {
        layoutOptions["elk.layered.layering.layerConstraint"] = "FIRST";
      }
      const child: ElkNode = { id: n.id, width: n.w, height: n.h };
      if (Object.keys(layoutOptions).length > 0) child.layoutOptions = layoutOptions;
      const ports = objectPorts.get(n.id);
      if (ports && ports.length > 0) {
        child.ports = ports.map(p => ({
          id: p.portId, width: 1, height: 1,
          layoutOptions: { "port.side": p.side },
        }));
        child.layoutOptions = {
          ...(child.layoutOptions ?? {}),
          "portConstraints": "FIXED_SIDE",
        };
      }
      return child;
    }
    // Action node — one port per pin.
    const ports: ElkPort[] = [];
    n.inPins.forEach((pin, i) => {
      const pid = portIdOf(n.id, "in", pin);
      const side = pinSideOverride.get(pid) ?? inSide;
      ports.push({
        id: pid,
        width: PIN_SZ, height: PIN_SZ,
        layoutOptions: {
          "port.side":  side,
          "port.index": String(n.inPins.length - 1 - i),
        },
      });
    });
    n.outPins.forEach((pin, i) => {
      const pid = portIdOf(n.id, "out", pin);
      const side = pinSideOverride.get(pid) ?? outSide;
      ports.push({
        id: pid,
        width: PIN_SZ, height: PIN_SZ,
        layoutOptions: {
          "port.side":  side,
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

  // ── Build ELK edges ────────────────────────────────────────────────────
  const elkEdges: ElkEdgeIn[] = [];
  const elkEdgeIdToOrig = new Map<string, number>();

  edges.forEach((e, i) => {
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt) return;

    const sourceId =
      edgeSrcPort.get(i) ??
      objectSrcPort.get(i) ??
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

  // ── Layout options ─────────────────────────────────────────────────────
  const rootLayoutOptions: Record<string, string> = {
    "elk.algorithm":                                     "layered",
    "elk.direction":                                     ctx.direction,
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
  };
  if (useLanes) {
    rootLayoutOptions["elk.layered.spacing.nodeNodeBetweenLayers"] = String(Math.max(34, Math.floor(EDGE_GAP * 0.6)));
    rootLayoutOptions["elk.layered.nodePlacement.strategy"] = "INTERACTIVE";
    rootLayoutOptions["elk.layered.mergeEdges"]              = "false";
    rootLayoutOptions["elk.edgeLabels.inline"]               = "true";
  }

  // ── Anchor lane rows ──────────────────────────────────────────────────
  if (useLanes) {
    for (const c of children) {
      const r = ctx.laneRankOf.get(c.id);
      if (r === undefined) continue;
      c.y = LANE_TOP + r * LANE_ROW;
    }
  }

  return {
    graph: { id: "root", layoutOptions: rootLayoutOptions, children, edges: elkEdges },
    elkEdgeIdToOrig,
  };
}

// ── Post-layout: node positions ───────────────────────────────────────────

/** Write ELK-computed positions back onto GNode centre coordinates. */
export function applyElkPositions(
  elkResult: ElkResult,
  nodes: readonly GNode[],
  _ctx: LayoutContext,
): void {
  const childMap = new Map<string, { x: number; y: number; w: number; h: number }>();
  for (const c of elkResult.children ?? []) {
    childMap.set(c.id, { x: c.x ?? 0, y: c.y ?? 0, w: c.width ?? 0, h: c.height ?? 0 });
  }
  for (const n of nodes) {
    const c = childMap.get(n.id);
    if (c) {
      n.x = c.x + n.w / 2;
      n.y = c.y + n.h / 2;
    }
  }
}

// ── Post-layout: lane position adjustments ────────────────────────────────

/**
 * All lane-specific position adjustments: cross-lane column alignment,
 * lower-lane compaction, HOF re-alignment, terminal sink pull-back,
 * and vertical lane-member shifts.
 *
 * Only called when `ctx.useLanes` is true.
 */
export function adjustLanePositions(
  nodes: readonly GNode[],
  edges: readonly GEdge[],
  ctx: LayoutContext,
): void {
  const { nodeIndex, laneOf, lanes, hasOutgoing } = ctx;

  // ── Column-align cross-lane objects above their target action ──────────
  const objectTargets = new Map<string, string[]>();
  for (const e of edges) {
    if (!e.isObjectFlow) continue;
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt || src.kind !== "object" || tgt.kind !== "action") continue;
    const sLane = laneOf.get(e.from);
    const tLane = laneOf.get(e.to);
    if (!sLane || !tLane || sLane === tLane) continue;
    const list = objectTargets.get(e.from) ?? [];
    list.push(e.to);
    objectTargets.set(e.from, list);
  }
  for (const [objectId, targets] of objectTargets) {
    if (targets.length !== 1) continue;
    const obj    = nodeIndex.get(objectId);
    const target = nodeIndex.get(targets[0]);
    if (!obj || !target) continue;
    obj.x = target.x;
  }

  // ── Compact lower lanes horizontally ──────────────────────────────────
  const laneIndexOf = ctx.laneRankOf;
  const incomingHofWidth = new Map<string, number>();
  for (const e of edges) {
    if (!e.isObjectFlow || !e.isHof) continue;
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt) continue;
    const srcLane = laneIndexOf.get(src.id);
    const tgtLane = laneIndexOf.get(tgt.id);
    if (srcLane === undefined || tgtLane === undefined || srcLane === tgtLane) continue;
    incomingHofWidth.set(tgt.id, Math.max(incomingHofWidth.get(tgt.id) ?? 0, src.w));
  }
  for (let laneIdx = 1; laneIdx < lanes.length; laneIdx++) {
    const members = lanes[laneIdx].members
      .map(id => nodeIndex.get(id))
      .filter((node): node is GNode => Boolean(node));
    for (let i = 1; i < members.length; i++) {
      const prev = members[i - 1];
      const cur = members[i];
      const edge = edges.find(e => e.from === prev.id && e.to === cur.id);
      const labelSpan = edge?.label
        ? Math.ceil(edge.label.length * EDGE_LABEL_CHAR_W) + EDGE_LABEL_PAD + 24
        : 40;
      const nodeDistance = prev.w / 2 + cur.w / 2 + labelSpan;
      const hofDistance = (incomingHofWidth.get(prev.id) ?? 0) / 2
        + (incomingHofWidth.get(cur.id) ?? 0) / 2
        + 24;
      const desiredX = prev.x + Math.max(nodeDistance, hofDistance);
      if (cur.x > desiredX) cur.x = desiredX;
    }
  }

  // ── Re-align HOFs after compaction ────────────────────────────────────
  for (const e of edges) {
    if (!e.isObjectFlow || !e.isHof) continue;
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt) continue;
    const srcLane = laneIndexOf.get(src.id);
    const tgtLane = laneIndexOf.get(tgt.id);
    if (srcLane === undefined || tgtLane === undefined || srcLane === tgtLane) continue;
    src.x = tgt.x;
  }

  // ── Pull terminal top-lane sinks toward producing action ──────────────
  for (const e of edges) {
    if (!e.isObjectFlow || e.isHof) continue;
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt || src.kind !== "action" || tgt.kind !== "object") continue;
    const srcLane = laneIndexOf.get(src.id);
    const tgtLane = laneIndexOf.get(tgt.id);
    if (srcLane === undefined || tgtLane === undefined || srcLane <= tgtLane) continue;
    if (hasOutgoing.has(tgt.id)) continue;
    const desiredX = src.x + src.w / 2 + tgt.w / 2 + 72;
    if (tgt.x > desiredX) tgt.x = desiredX;
  }

  // ── Shift lane members vertically ─────────────────────────────────────
  for (const member of lanes[0]?.members ?? []) {
    const node = nodeIndex.get(member);
    if (!node) continue;
    node.y += TOP_LANE_NODE_SHIFT;
  }
  for (let laneIdx = 1; laneIdx < lanes.length; laneIdx++) {
    for (const member of lanes[laneIdx].members) {
      const node = nodeIndex.get(member);
      if (!node) continue;
      node.y += LOWER_LANE_NODE_SHIFT;
    }
  }
}

// ── Canvas size & lane geometry ───────────────────────────────────────────

interface CanvasAndLanes {
  totalW: number;
  totalH: number;
  laneGeoms: LaneGeom[];
}

/** Compute final canvas size and lane band geometry from positioned nodes. */
export function computeCanvasAndLanes(
  nodes: readonly GNode[],
  ctx: LayoutContext,
  elkWidth: number,
  elkHeight: number,
): CanvasAndLanes {
  const { nodeIndex, useLanes, lanes } = ctx;

  const totalW = useLanes
    ? Math.max(200, ...nodes.map(n => n.x + n.w / 2)) + 30
    : elkWidth;
  const totalH = useLanes
    ? Math.max(100, ...nodes.map(n => n.y + n.h / 2)) + 12
    : elkHeight;

  const laneBoxes: { id: string; label?: string; minY: number; maxY: number }[] = [];
  for (const l of lanes) {
    let minY = Infinity, maxY = -Infinity;
    for (const m of l.members) {
      const n = nodeIndex.get(m);
      if (!n) continue;
      minY = Math.min(minY, n.y - n.h / 2);
      maxY = Math.max(maxY, n.y + n.h / 2);
    }
    if (minY === Infinity) { minY = 0; maxY = 0; }
    laneBoxes.push({ id: l.id, label: l.label, minY, maxY });
  }

  const laneOrder = laneBoxes
    .map((b, i) => ({ b, i }))
    .sort((a, b) => a.b.minY - b.b.minY);
  const rawExtents = laneOrder.map(({ b }) => ({ minY: b.minY, maxY: b.maxY }));

  for (let k = 0; k < laneOrder.length; k++) {
    const cur = laneOrder[k].b;
    const curRaw  = rawExtents[k];
    const prevRaw = k > 0 ? rawExtents[k - 1] : null;
    const nextRaw = k + 1 < laneOrder.length ? rawExtents[k + 1] : null;
    const top = prevRaw
      ? (prevRaw.maxY + curRaw.minY) / 2
      : Math.max(0, curRaw.minY - LANE_PAD_Y - LANE_HEADER_H - TOP_LANE_CLEARANCE);
    const bot = nextRaw
      ? (curRaw.maxY + nextRaw.minY) / 2
      : Math.min(totalH, curRaw.maxY + LANE_PAD_Y);
    cur.minY = top;
    cur.maxY = bot;
  }

  const laneGeoms: LaneGeom[] = laneBoxes.map(b => ({
    id:    b.id,
    label: b.label,
    x:     0,
    y:     b.minY,
    w:     totalW,
    h:     Math.max(0, b.maxY - b.minY),
  }));

  return { totalW, totalH, laneGeoms };
}

// ── Edge path extraction ──────────────────────────────────────────────────

/** Extract routed polylines from ELK's edge sections. */
export function extractEdgePaths(
  elkResult: ElkResult,
  elkEdgeIdToOrig: ReadonlyMap<string, number>,
  edgeCount: number,
): EdgePolyline[] {
  const edgePaths: EdgePolyline[] = Array.from({ length: edgeCount }, () => []);
  for (const re of elkResult.edges ?? []) {
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
  return edgePaths;
}

// ── Edge rewriting: same-lane straightening ───────────────────────────────

/**
 * Rewrite edge polylines for lane diagrams:
 * - Same-lane horizontal chain edges → straight segment.
 * - Cross-lane object→action edges → clean vertical drop.
 * - Action→top-lane terminal object edges → L-shaped.
 * - Other cross-lane object flows → rebuilt from current positions.
 *
 * Only called when `ctx.useLanes` is true.
 */
export function straightenLaneEdges(
  edges: readonly GEdge[],
  edgePaths: EdgePolyline[],
  ctx: LayoutContext,
): void {
  const { nodeIndex, laneOf, lanes, hasOutgoing } = ctx;

  for (let i = 0; i < edges.length; i++) {
    const e = edges[i];
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt) continue;
    const path = edgePaths[i];
    if (path.length < 2) continue;
    const sLane = laneOf.get(e.from);
    const tLane = laneOf.get(e.to);

    // Same-lane horizontal: collapse to a straight line on shared y.
    if (sLane && sLane === tLane && src.kind === "action" && tgt.kind === "action") {
      if (Math.abs(src.y - tgt.y) <= 0.5) {
        const sx = src.x + src.w / 2 + (e.srcPin ? PIN_SZ / 2 : 0);
        const tx = tgt.x - tgt.w / 2 - (e.dstPin ? PIN_SZ / 2 : 0);
        edgePaths[i] = [[sx, src.y], [tx, tgt.y]];
      }
      continue;
    }
    // Cross-lane object → action: route as a clean vertical drop.
    if (sLane && tLane && sLane !== tLane && e.isObjectFlow && src.kind === "object" && tgt.kind === "action") {
      const sx = src.x;
      const sy = src.y + src.h / 2;
      const fx = tgt.x;
      const ty = tgt.y - tgt.h / 2 - PIN_SZ / 2;
      if (Math.abs(sx - fx) <= 0.5) {
        edgePaths[i] = [[sx, sy], [fx, ty]];
      } else {
        edgePaths[i] = [[sx, sy], [sx, ty], [fx, ty]];
      }
      continue;
    }
    // Final action → top-lane object: leave via east pin, then rise.
    if (
      sLane && tLane && sLane !== tLane && e.isObjectFlow && !e.isHof &&
      src.kind === "action" && tgt.kind === "object" &&
      (laneOf.get(src.id) === lanes[1]?.id) && (laneOf.get(tgt.id) === lanes[0]?.id) &&
      !hasOutgoing.has(tgt.id)
    ) {
      const sx = src.x + src.w / 2;
      const sy = src.y;
      const tx = tgt.x;
      const ty = tgt.y + tgt.h / 2;
      edgePaths[i] = [[sx, sy], [tx, sy], [tx, ty]];
      continue;
    }
    // Other cross-lane object/action edges: rebuilt from current positions.
    if (sLane && tLane && sLane !== tLane && e.isObjectFlow) {
      const sx = src.kind === "action"
        ? src.x + src.w / 2
        : (src.x <= tgt.x ? src.x + src.w / 2 : src.x - src.w / 2);
      const sy = src.y;
      const tx = tgt.kind === "action"
        ? tgt.x - tgt.w / 2
        : (sx <= tgt.x ? tgt.x - tgt.w / 2 : tgt.x + tgt.w / 2);
      const ty = tgt.y;
      if (Math.abs(sx - tx) <= 0.5 || Math.abs(sy - ty) <= 0.5) {
        edgePaths[i] = [[sx, sy], [tx, ty]];
      } else {
        edgePaths[i] = [[sx, sy], [sx, ty], [tx, ty]];
      }
    }
  }
}

// ── Edge rewriting: decision → merge snapping ─────────────────────────────

/**
 * Snap decision→merge polylines onto a single shared rail.
 * Sets `e.labelNearSource = true` so the renderer places the label on the
 * short vertical segment near the decision.
 */
export function snapDecisionMergeEdges(
  edges: GEdge[],
  edgePaths: EdgePolyline[],
  ctx: LayoutContext,
): void {
  const { nodeIndex, rankdir } = ctx;

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
      edgePaths[i] = sx === tx
        ? [[sx, sy], [tx, ty]]
        : [[sx, sy], [sx, ty], [tx, ty]];
    } else {
      edgePaths[i] = sy === ty
        ? [[sx, sy], [tx, ty]]
        : [[sx, sy], [tx, sy], [tx, ty]];
    }
    e.labelNearSource = true;
  }
}

// ── Main pipeline ─────────────────────────────────────────────────────────

const elk = new ELK();

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
  lanes: LaneSpec[] = [],
): Promise<LayoutResult> {
  if (nodes.length === 0) {
    return { width: 200, height: 100, edgePaths: edges.map(() => []), lanes: [] };
  }

  // Ensure widths/heights are up to date with current label content.
  for (const n of nodes) { [n.w, n.h] = nodeDims(n); }

  const ctx = buildContext(nodes, edges, rankdir, lanes);
  const { graph, elkEdgeIdToOrig } = buildElkGraph(nodes, edges, ctx);
  const elkResult = (await elk.layout(graph as never)) as ElkResult;

  applyElkPositions(elkResult, nodes, ctx);
  if (ctx.useLanes) adjustLanePositions(nodes, edges, ctx);

  const { totalW, totalH, laneGeoms } = computeCanvasAndLanes(
    nodes, ctx, elkResult.width ?? 200, elkResult.height ?? 100,
  );

  const edgePaths = extractEdgePaths(elkResult, elkEdgeIdToOrig, edges.length);
  if (ctx.useLanes) straightenLaneEdges(edges, edgePaths, ctx);
  snapDecisionMergeEdges(edges, edgePaths, ctx);

  return { width: totalW, height: totalH, edgePaths, lanes: laneGeoms };
}
