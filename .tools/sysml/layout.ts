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
import { indexBy, sortBy, times } from "./lib/fp.ts";

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
  /** Positioned nodes with updated x/y centre coordinates. */
  nodes:    GNode[];
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
  const nonNoteEdges = edges.filter(e => !e.isNoteAttachment);
  const hasOutgoing = new Set(nonNoteEdges.map(e => e.from));
  const hasIncoming = new Set(nonNoteEdges.map(e => e.to));
  const useLanes = lanes.length > 0;
  const direction = rankdir === "TB" ? "DOWN" : "RIGHT";
  const leafRankdir = rankdir;
  const inSide  = leafRankdir === "TB" ? "NORTH" : "WEST";
  const outSide = leafRankdir === "TB" ? "SOUTH" : "EAST";
  const altSide = leafRankdir === "TB" ? "EAST"  : "SOUTH";

  const laneOf = new Map<string, string>(
    lanes.flatMap(l => l.members.map(m => [m, l.id] as const)),
  );
  const laneRankOf = new Map<string, number>(
    lanes.flatMap((l, i) => l.members.map(m => [m, i] as const)),
  );

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
  interface CrossLaneState {
    readonly pinSideOverride: ReadonlyMap<string, string>;
    readonly objectSrcPort:   ReadonlyMap<number, string>;
    readonly objectPorts:     ReadonlyMap<string, readonly { side: string; portId: string }[]>;
    readonly pinSidePatches:  ReadonlyMap<string, Record<string, string>>;
  }

  const crossLane: CrossLaneState = useLanes
    ? edges.reduce<CrossLaneState>((acc, e, idx) => {
        if (!e.isObjectFlow || !e.dstPin) return acc;
        const src = nodeIndex.get(e.from);
        const tgt = nodeIndex.get(e.to);
        if (!src || !tgt || src.kind !== "object" || tgt.kind !== "action") return acc;
        const sr = ctx.laneRankOf.get(src.id);
        const tr = ctx.laneRankOf.get(tgt.id);
        if (sr === undefined || tr === undefined || sr === tr) return acc;
        const [actSide, objSide] = leafRankdir === "TB"
          ? (sr < tr ? ["WEST", "EAST"] : ["EAST", "WEST"])
          : (sr < tr ? ["NORTH", "SOUTH"] : ["SOUTH", "NORTH"]);

        const newPinSide = new Map([...acc.pinSideOverride, [portIdOf(tgt.id, "in", e.dstPin), actSide]]);
        const compass = actSide[0] as "N" | "S" | "E" | "W";
        const existingPatch = acc.pinSidePatches.get(tgt.id) ?? {};
        const newPatches = new Map([...acc.pinSidePatches, [tgt.id, { ...existingPatch, [e.dstPin]: compass }]]);

        const portId = objectPortIdOf(src.id, objSide);
        const list = acc.objectPorts.get(src.id) ?? [];
        const newObjPorts = list.find(p => p.portId === portId)
          ? acc.objectPorts
          : new Map([...acc.objectPorts, [src.id, [...list, { side: objSide, portId }]]]);
        const newSrcPort = new Map([...acc.objectSrcPort, [idx, portId]]);

        return { pinSideOverride: newPinSide, objectSrcPort: newSrcPort, objectPorts: newObjPorts, pinSidePatches: newPatches };
      }, { pinSideOverride: new Map(), objectSrcPort: new Map(), objectPorts: new Map(), pinSidePatches: new Map() })
    : { pinSideOverride: new Map(), objectSrcPort: new Map(), objectPorts: new Map(), pinSidePatches: new Map() };

  const { pinSideOverride, objectSrcPort, objectPorts } = crossLane;
  // Apply pinSides patches to nodes (produces new array for pure callers)
  const patchedNodes = nodes.map(n => {
    const patch = crossLane.pinSidePatches.get(n.id);
    return patch ? { ...n, pinSides: { ...(n.pinSides ?? {}), ...patch } } : n;
  });

  // ── Build decision/merge port tables ───────────────────────────────────
  // Pre-compute edge→port assignments for decision/merge nodes.
  interface PortAssignments {
    readonly edgeSrcPort: ReadonlyMap<number, string>;
    readonly edgeTgtPort: ReadonlyMap<number, string>;
  }
  const decMergeNodes = patchedNodes.filter(n => n.kind === "decision" || n.kind === "merge");
  const portAssignments = decMergeNodes.reduce<PortAssignments>((acc, n) => {
    const inEdges  = edges.flatMap((e, idx) => e.to   === n.id ? [{ edge: e, idx }] : []);
    const outEdges = edges.flatMap((e, idx) => e.from === n.id ? [{ edge: e, idx }] : []);

    const inTgt = (n.kind === "merge" && inEdges.length > 0)
      ? (() => {
          const pid = decisionPortIdOf(n.id, "in", 0);
          return inEdges.map(({ idx }) => [idx, pid] as const);
        })()
      : inEdges.map(({ idx }, i) => [idx, decisionPortIdOf(n.id, "in", i)] as const);

    const outSrc = outEdges.map(({ edge, idx }, i) => {
      const toMerge = mergeIds.has(edge.to);
      const side = (n.kind === "decision" && toMerge) ? altSide : outSide;
      const role = side === outSide ? "outFwd" : "outAlt";
      return [idx, decisionPortIdOf(n.id, role, i)] as const;
    });

    return {
      edgeSrcPort: new Map([...acc.edgeSrcPort, ...outSrc]),
      edgeTgtPort: new Map([...acc.edgeTgtPort, ...inTgt]),
    };
  }, { edgeSrcPort: new Map(), edgeTgtPort: new Map() });
  const { edgeSrcPort, edgeTgtPort } = portAssignments;

  // ── Build ELK children ─────────────────────────────────────────────────
  const children: ElkNode[] = patchedNodes.map(n => {
    if (n.kind === "decision" || n.kind === "merge") {
      const inEdges  = edges.flatMap((e, idx) => e.to   === n.id ? [{ edge: e, idx }] : []);
      const outEdges = edges.flatMap((e, idx) => e.from === n.id ? [{ edge: e, idx }] : []);

      const inPorts: ElkPort[] = (n.kind === "merge" && inEdges.length > 0)
        ? [{
            id: decisionPortIdOf(n.id, "in", 0), width: 1, height: 1,
            layoutOptions: { "port.side": inSide },
          }]
        : inEdges.map((_, i) => ({
            id: decisionPortIdOf(n.id, "in", i), width: 1, height: 1,
            layoutOptions: { "port.side": inSide },
          }));

      const outPorts: ElkPort[] = outEdges.map(({ edge }, i) => {
        const toMerge = mergeIds.has(edge.to);
        const side = (n.kind === "decision" && toMerge) ? altSide : outSide;
        const role = side === outSide ? "outFwd" : "outAlt";
        return {
          id: decisionPortIdOf(n.id, role, i), width: 1, height: 1,
          layoutOptions: { "port.side": side },
        };
      });

      return {
        id: n.id, width: n.w, height: n.h, ports: [...inPorts, ...outPorts],
        layoutOptions: {
          "portConstraints":           "FIXED_SIDE",
          "elk.portAlignment.default": "CENTER",
        },
      };
    }
    if (n.kind !== "action") {
      const isLast  = isTerminalSink(n, ctx);
      const isFirst = isInitialSource(n, ctx);
      const baseLayout = {
        ...(isLast  ? { "elk.layered.layering.layerConstraint": "LAST" }  : {}),
        ...(isFirst ? { "elk.layered.layering.layerConstraint": "FIRST" } : {}),
      };
      const objPorts = objectPorts.get(n.id);
      const hasPorts = objPorts && objPorts.length > 0;
      return {
        id: n.id, width: n.w, height: n.h,
        ...(Object.keys(baseLayout).length > 0 || hasPorts
          ? { layoutOptions: { ...baseLayout, ...(hasPorts ? { "portConstraints": "FIXED_SIDE" } : {}) } }
          : {}),
        ...(hasPorts
          ? { ports: objPorts.map(p => ({ id: p.portId, width: 1, height: 1, layoutOptions: { "port.side": p.side } })) }
          : {}),
      };
    }
    // Action node — one port per pin.
    const inPortList: ElkPort[] = n.inPins.map((pin, i) => {
      const pid = portIdOf(n.id, "in", pin);
      const side = pinSideOverride.get(pid) ?? inSide;
      return {
        id: pid,
        width: PIN_SZ, height: PIN_SZ,
        layoutOptions: {
          "port.side":  side,
          "port.index": String(n.inPins.length - 1 - i),
        },
      };
    });
    const outPortList: ElkPort[] = n.outPins.map((pin, i) => {
      const pid = portIdOf(n.id, "out", pin);
      const side = pinSideOverride.get(pid) ?? outSide;
      return {
        id: pid,
        width: PIN_SZ, height: PIN_SZ,
        layoutOptions: {
          "port.side":  side,
          "port.index": String(i),
        },
      };
    });
    return {
      id: n.id,
      width: n.w, height: n.h,
      ports: [...inPortList, ...outPortList],
      layoutOptions: {
        "portConstraints":            "FIXED_ORDER",
        "elk.portAlignment.default":  "DISTRIBUTED",
      },
    };
  });

  // ── Build ELK edges ────────────────────────────────────────────────────
  const edgeEntries = edges
    .map((e, i) => ({ e, i, src: nodeIndex.get(e.from), tgt: nodeIndex.get(e.to) }))
    .filter(({ src, tgt }) => src != null && tgt != null);

  const elkEdgeIdToOrig = new Map(edgeEntries.map(({ i }) => [`e${i}`, i] as const));

  const elkEdges: ElkEdgeIn[] = edgeEntries.map(({ e, i, src, tgt }) => {
    const sourceId =
      edgeSrcPort.get(i) ??
      objectSrcPort.get(i) ??
      (src!.kind === "action" && e.isObjectFlow && e.srcPin
        ? portIdOf(src!.id, "out", e.srcPin)
        : src!.id);
    const targetId =
      edgeTgtPort.get(i) ??
      (tgt!.kind === "action" && e.isObjectFlow && e.dstPin
        ? portIdOf(tgt!.id, "in", e.dstPin)
        : tgt!.id);

    return {
      id: `e${i}`, sources: [sourceId], targets: [targetId],
      ...(e.label && e.label.length > 0
        ? { labels: [{
            text: e.label,
            width:  Math.ceil(e.label.length * EDGE_LABEL_CHAR_W) + EDGE_LABEL_PAD,
            height: EDGE_LABEL_H,
          }] }
        : {}),
    };
  });

  // ── Layout options ─────────────────────────────────────────────────────
  const baseLayoutOptions: Record<string, string> = {
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
  const rootLayoutOptions: Record<string, string> = useLanes
    ? {
        ...baseLayoutOptions,
        "elk.layered.spacing.nodeNodeBetweenLayers": String(Math.max(34, Math.floor(EDGE_GAP * 0.6))),
        "elk.layered.nodePlacement.strategy":        "INTERACTIVE",
        "elk.layered.mergeEdges":                    "false",
        "elk.edgeLabels.inline":                     "true",
      }
    : baseLayoutOptions;

  // ── Anchor lane rows ──────────────────────────────────────────────────
  const anchoredChildren = useLanes
    ? children.map(c => {
        const r = ctx.laneRankOf.get(c.id);
        return r !== undefined ? { ...c, y: LANE_TOP + r * LANE_ROW } : c;
      })
    : children;

  return {
    graph: { id: "root", layoutOptions: rootLayoutOptions, children: anchoredChildren, edges: elkEdges },
    elkEdgeIdToOrig,
  };
}

// ── Post-layout: node positions ───────────────────────────────────────────

/** Return nodes with ELK-computed centre coordinates applied. */
export function applyElkPositions(
  elkResult: ElkResult,
  nodes: readonly GNode[],
  _ctx: LayoutContext,
): GNode[] {
  const childMap = new Map(
    (elkResult.children ?? []).map(c => [c.id, { x: c.x ?? 0, y: c.y ?? 0, w: c.width ?? 0, h: c.height ?? 0 }]),
  );
  return nodes.map(n => {
    const c = childMap.get(n.id);
    return c ? { ...n, x: c.x + n.w / 2, y: c.y + n.h / 2 } : n;
  });
}

// ── Post-layout: lane position adjustments ────────────────────────────────

/**
 * All lane-specific position adjustments: cross-lane column alignment,
 * lower-lane compaction, HOF re-alignment, terminal sink pull-back,
 * and vertical lane-member shifts.
 *
 * Each pass is a pure function that consumes the current node array and
 * returns a Map of id→{x?,y?} patches.  The final result threads the five
 * passes through `applyPatches` in order.
 *
 * Only called when `ctx.useLanes` is true.
 */

// ── Patch helpers (private, shared across passes) ─────────────────────────

type NodePatch = Partial<Pick<GNode, "x" | "y">>;
type PatchMap  = ReadonlyMap<string, NodePatch>;

const emptyPatchMap: PatchMap = new Map();

const indexNodes = (ns: readonly GNode[]): ReadonlyMap<string, GNode> =>
  new Map(ns.map(n => [n.id, n]));

const applyPatches = (ns: readonly GNode[], patches: PatchMap): GNode[] =>
  ns.map(n => {
    const p = patches.get(n.id);
    return p ? { ...n, ...p } : n;
  });

/** Run a sequence of pass functions, threading the node array through each. */
const runPasses = (
  initial: readonly GNode[],
  passes: readonly ((ns: readonly GNode[]) => PatchMap)[],
): GNode[] =>
  passes.reduce<GNode[]>(
    (acc, pass) => applyPatches(acc, pass(acc)),
    [...initial],
  );

// ── Individual passes ─────────────────────────────────────────────────────

/** Pass 1: column-align cross-lane object→action edges with a single target. */
function alignCrossLaneObjects(
  edges: readonly GEdge[],
  ctx: LayoutContext,
) {
  const { laneOf } = ctx;
  return (nodes: readonly GNode[]): PatchMap => {
    const nix = indexNodes(nodes);
    const objectTargets = edges
      .filter(e => e.isObjectFlow)
      .reduce<ReadonlyMap<string, readonly string[]>>((acc, e) => {
        const src = nix.get(e.from);
        const tgt = nix.get(e.to);
        if (!src || !tgt || src.kind !== "object" || tgt.kind !== "action") return acc;
        const sLane = laneOf.get(e.from);
        const tLane = laneOf.get(e.to);
        if (!sLane || !tLane || sLane === tLane) return acc;
        return new Map([...acc, [e.from, [...(acc.get(e.from) ?? []), e.to]]]);
      }, new Map());

    return new Map(
      [...objectTargets.entries()]
        .filter(([, targets]) => targets.length === 1)
        .flatMap(([objectId, targets]) => {
          const target = nix.get(targets[0]);
          return target ? [[objectId, { x: target.x }] as const] : [];
        }),
    );
  };
}

/** Pass 2: compact lower lanes horizontally so each member sits next to its predecessor. */
function compactLowerLanes(
  edges: readonly GEdge[],
  ctx: LayoutContext,
) {
  const { lanes, laneRankOf } = ctx;
  return (nodes: readonly GNode[]): PatchMap => {
    const nix = indexNodes(nodes);
    const incomingHofWidth = edges.reduce<ReadonlyMap<string, number>>((acc, e) => {
      if (!e.isObjectFlow || !e.isHof) return acc;
      const src = nix.get(e.from);
      const tgt = nix.get(e.to);
      if (!src || !tgt) return acc;
      const srcLane = laneRankOf.get(src.id);
      const tgtLane = laneRankOf.get(tgt.id);
      if (srcLane === undefined || tgtLane === undefined || srcLane === tgtLane) return acc;
      return new Map([...acc, [tgt.id, Math.max(acc.get(tgt.id) ?? 0, src.w)]]);
    }, new Map());

    // Compaction must apply patches as it goes (each member depends on the
    // previously-clamped predecessor), so we fold across patched node arrays.
    const compacted = lanes.slice(1).reduce<GNode[]>((accNodes, lane) => {
      const members = lane.members
        .map(id => indexNodes(accNodes).get(id))
        // eslint-disable-next-line functional/prefer-tacit -- type-guard annotation requires wrapper
        .filter((node): node is GNode => Boolean(node));
      return members.slice(1).reduce((innerNodes, cur, i) => {
        const inner = indexNodes(innerNodes);
        const prev  = inner.get(members[i].id)!;
        const edge  = edges.find(e => e.from === prev.id && e.to === cur.id);
        const labelSpan = edge?.label
          ? Math.ceil(edge.label.length * EDGE_LABEL_CHAR_W) + EDGE_LABEL_PAD + 24
          : 40;
        const nodeDistance = prev.w / 2 + cur.w / 2 + labelSpan;
        const hofDistance  = (incomingHofWidth.get(prev.id) ?? 0) / 2
          + (incomingHofWidth.get(cur.id) ?? 0) / 2
          + 24;
        const desiredX = prev.x + Math.max(nodeDistance, hofDistance);
        const currentX = inner.get(cur.id)!.x;
        return currentX > desiredX
          ? applyPatches(innerNodes, new Map([[cur.id, { x: desiredX }]]))
          : innerNodes;
      }, accNodes);
    }, [...nodes]);

    // Diff compacted vs original to produce the patch map for this pass.
    return new Map(
      compacted.flatMap(c => {
        const orig = nix.get(c.id);
        return orig && orig.x !== c.x ? [[c.id, { x: c.x }] as const] : [];
      }),
    );
  };
}

/** Pass 3: re-align HOF objects above their target after compaction. */
function realignHofs(
  edges: readonly GEdge[],
  ctx: LayoutContext,
) {
  const { laneRankOf } = ctx;
  return (nodes: readonly GNode[]): PatchMap => {
    const nix = indexNodes(nodes);
    return edges.reduce<ReadonlyMap<string, NodePatch>>((acc, e) => {
      if (!e.isObjectFlow || !e.isHof) return acc;
      const src = nix.get(e.from);
      const tgt = nix.get(e.to);
      if (!src || !tgt) return acc;
      const srcLane = laneRankOf.get(src.id);
      const tgtLane = laneRankOf.get(tgt.id);
      if (srcLane === undefined || tgtLane === undefined || srcLane === tgtLane) return acc;
      return new Map([...acc, [src.id, { x: tgt.x }]]);
    }, emptyPatchMap);
  };
}

/** Pass 4: pull terminal top-lane object sinks toward their producing action. */
function pullTerminalSinks(
  edges: readonly GEdge[],
  ctx: LayoutContext,
) {
  const { laneRankOf, hasOutgoing } = ctx;
  return (nodes: readonly GNode[]): PatchMap => {
    const nix = indexNodes(nodes);
    return edges.reduce<ReadonlyMap<string, NodePatch>>((acc, e) => {
      if (!e.isObjectFlow || e.isHof) return acc;
      const src = nix.get(e.from);
      const tgt = nix.get(e.to);
      if (!src || !tgt || src.kind !== "action" || tgt.kind !== "object") return acc;
      const srcLane = laneRankOf.get(src.id);
      const tgtLane = laneRankOf.get(tgt.id);
      if (srcLane === undefined || tgtLane === undefined || srcLane <= tgtLane) return acc;
      if (hasOutgoing.has(tgt.id)) return acc;
      const desiredX = src.x + src.w / 2 + tgt.w / 2 + 72;
      return tgt.x > desiredX ? new Map([...acc, [tgt.id, { x: desiredX }]]) : acc;
    }, emptyPatchMap);
  };
}

/** Pass 5: shift lane members vertically (top lane vs lower lanes). */
function shiftLaneMembersVertically(ctx: LayoutContext) {
  const { lanes } = ctx;
  return (nodes: readonly GNode[]): PatchMap => {
    const nix = indexNodes(nodes);
    const shiftMembers = (members: readonly string[], dy: number) =>
      members
        .filter(m => nix.has(m))
        .map(m => [m, { y: nix.get(m)!.y + dy }] as const);
    return new Map([
      ...shiftMembers(lanes[0]?.members ?? [], TOP_LANE_NODE_SHIFT),
      ...lanes.slice(1).flatMap(l => shiftMembers(l.members, LOWER_LANE_NODE_SHIFT)),
    ]);
  };
}

export function adjustLanePositions(
  nodes: readonly GNode[],
  edges: readonly GEdge[],
  ctx: LayoutContext,
): GNode[] {
  return runPasses(nodes, [
    alignCrossLaneObjects(edges, ctx),
    compactLowerLanes(edges, ctx),
    realignHofs(edges, ctx),
    pullTerminalSinks(edges, ctx),
    shiftLaneMembersVertically(ctx),
  ]);
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
  const { useLanes, lanes } = ctx;
  const nix = new Map(nodes.map(n => [n.id, n]));

  const totalW = useLanes
    ? Math.max(200, ...nodes.map(n => n.x + n.w / 2)) + 30
    : elkWidth;
  const totalH = useLanes
    ? Math.max(100, ...nodes.map(n => n.y + n.h / 2)) + 12
    : elkHeight;

  const laneBoxes = lanes.map(l => {
    const memberNodes = l.members.map(m => nix.get(m)).filter((n): n is GNode => n != null);
    const minY = memberNodes.length > 0 ? Math.min(...memberNodes.map(n => n.y - n.h / 2)) : 0;
    const maxY = memberNodes.length > 0 ? Math.max(...memberNodes.map(n => n.y + n.h / 2)) : 0;
    return { id: l.id, label: l.label, minY, maxY };
  });

  const laneOrder = sortBy(
    laneBoxes.map((b, i) => ({ b, i })),
    o => o.b.minY,
  );
  const rawExtents = laneOrder.map(({ b }) => ({ minY: b.minY, maxY: b.maxY }));

  const adjustedBoxes = laneOrder.map(({ b }, k) => {
    const curRaw  = rawExtents[k];
    const prevRaw = k > 0 ? rawExtents[k - 1] : null;
    const nextRaw = k + 1 < laneOrder.length ? rawExtents[k + 1] : null;
    const top = prevRaw
      ? (prevRaw.maxY + curRaw.minY) / 2
      : Math.max(0, curRaw.minY - LANE_PAD_Y - LANE_HEADER_H - TOP_LANE_CLEARANCE);
    const bot = nextRaw
      ? (curRaw.maxY + nextRaw.minY) / 2
      : Math.min(totalH, curRaw.maxY + LANE_PAD_Y);
    return { ...b, minY: top, maxY: bot };
  });

  // Re-order back to lane declaration order
  const adjustedByIdx = new Map(laneOrder.map(({ i }, k) => [i, adjustedBoxes[k]]));
  const laneGeoms: LaneGeom[] = laneBoxes.map((_, i) => {
    const b = adjustedByIdx.get(i) ?? laneBoxes[i];
    return {
      id:    b.id,
      label: b.label,
      x:     0,
      y:     b.minY,
      w:     totalW,
      h:     Math.max(0, b.maxY - b.minY),
    };
  });

  return { totalW, totalH, laneGeoms };
}

// ── Edge path extraction ──────────────────────────────────────────────────

/** Extract routed polylines from ELK's edge sections. */
export function extractEdgePaths(
  elkResult: ElkResult,
  elkEdgeIdToOrig: ReadonlyMap<string, number>,
  edgeCount: number,
): EdgePolyline[] {
  const edgeMap = new Map(
    (elkResult.edges ?? []).flatMap(re => {
      const origIdx = elkEdgeIdToOrig.get(re.id);
      if (origIdx === undefined) return [];
      const sec = re.sections?.[0];
      if (!sec) return [];
      const pts: [number, number][] = [
        [sec.startPoint.x, sec.startPoint.y],
        ...(sec.bendPoints ?? []).map(p => [p.x, p.y] as [number, number]),
        [sec.endPoint.x, sec.endPoint.y],
      ];
      return [[origIdx, pts] as const];
    }),
  );
  return times(edgeCount, i => (edgeMap.get(i) as EdgePolyline) ?? []);
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
  edgePaths: readonly EdgePolyline[],
  ctx: LayoutContext,
): EdgePolyline[] {
  const { laneOf, lanes, hasOutgoing } = ctx;
  const nix = new Map(ctx.nodeIndex);

  return edgePaths.map((path, i) => {
    const e = edges[i];
    const src = nix.get(e.from);
    const tgt = nix.get(e.to);
    if (!src || !tgt || path.length < 2) return path;
    const sLane = laneOf.get(e.from);
    const tLane = laneOf.get(e.to);

    // Same-lane horizontal: collapse to a straight line on shared y.
    if (sLane && sLane === tLane && src.kind === "action" && tgt.kind === "action") {
      if (Math.abs(src.y - tgt.y) <= 0.5) {
        const sx = src.x + src.w / 2 + (e.srcPin ? PIN_SZ / 2 : 0);
        const tx = tgt.x - tgt.w / 2 - (e.dstPin ? PIN_SZ / 2 : 0);
        return [[sx, src.y], [tx, tgt.y]] as EdgePolyline;
      }
      return path;
    }
    // Cross-lane object → action: route as a clean vertical drop.
    if (sLane && tLane && sLane !== tLane && e.isObjectFlow && src.kind === "object" && tgt.kind === "action") {
      const sx = src.x;
      const sy = src.y + src.h / 2;
      const fx = tgt.x;
      const ty = tgt.y - tgt.h / 2 - PIN_SZ / 2;
      return Math.abs(sx - fx) <= 0.5
        ? ([[sx, sy], [fx, ty]] as EdgePolyline)
        : ([[sx, sy], [sx, ty], [fx, ty]] as EdgePolyline);
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
      return [[sx, sy], [tx, sy], [tx, ty]] as EdgePolyline;
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
      return (Math.abs(sx - tx) <= 0.5 || Math.abs(sy - ty) <= 0.5)
        ? ([[sx, sy], [tx, ty]] as EdgePolyline)
        : ([[sx, sy], [sx, ty], [tx, ty]] as EdgePolyline);
    }
    return path;
  });
}

// ── Edge rewriting: decision → merge snapping ─────────────────────────────

/**
 * Snap decision→merge polylines onto a single shared rail.
 * Returns new edges (with `labelNearSource = true` set) and new edgePaths.
 */
export function snapDecisionMergeEdges(
  edges: readonly GEdge[],
  edgePaths: readonly EdgePolyline[],
  ctx: LayoutContext,
): { snappedEdges: GEdge[]; snappedPaths: EdgePolyline[] } {
  const { nodeIndex, rankdir } = ctx;

  const snappedEdges = edges.map((e, i) => {
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt || src.kind !== "decision" || tgt.kind !== "merge") return e;
    const path = edgePaths[i];
    if (path.length < 2) return e;
    return { ...e, labelNearSource: true };
  });

  const snappedPaths = edgePaths.map((path, i) => {
    const e = edges[i];
    const src = nodeIndex.get(e.from);
    const tgt = nodeIndex.get(e.to);
    if (!src || !tgt || src.kind !== "decision" || tgt.kind !== "merge") return path;
    if (path.length < 2) return path;
    const [sx, sy] = path[0];
    const [, ty] = path[path.length - 1];
    const tx = path[path.length - 1][0];
    if (rankdir === "LR") {
      return sx === tx
        ? ([[sx, sy], [tx, ty]] as EdgePolyline)
        : ([[sx, sy], [sx, ty], [tx, ty]] as EdgePolyline);
    }
    return sy === ty
      ? ([[sx, sy], [tx, ty]] as EdgePolyline)
      : ([[sx, sy], [tx, sy], [tx, ty]] as EdgePolyline);
  });

  return { snappedEdges, snappedPaths };
}

// ── Main pipeline ─────────────────────────────────────────────────────────

const elk = new ELK();

/**
 * Run ELK layered + orthogonal routing on the graph.
 *
 * Returns positioned nodes (centre coordinates), routed edge polylines,
 * and lane geometry.  The input arrays are not mutated.
 */
export async function layoutGraph(
  nodes: readonly GNode[],
  edges: readonly GEdge[],
  rankdir: "LR" | "TB" = "LR",
  lanes: readonly LaneSpec[] = [],
): Promise<LayoutResult> {
  if (nodes.length === 0) {
    return { width: 200, height: 100, nodes: [], edgePaths: edges.map(() => []), lanes: [] };
  }

  // Ensure widths/heights are up to date with current label content.
  const sizedNodes = nodes.map(n => {
    const [w, h] = nodeDims(n);
    return { ...n, w, h };
  });

  const ctx = buildContext(sizedNodes, edges, rankdir, lanes);
  const { graph, elkEdgeIdToOrig } = buildElkGraph(sizedNodes, edges, ctx);
  const elkResult = (await elk.layout(graph as never)) as ElkResult;

  const positioned = applyElkPositions(elkResult, sizedNodes, ctx);
  const adjusted = ctx.useLanes ? adjustLanePositions(positioned, edges, ctx) : positioned;

  // Rebuild context with adjusted node positions for edge rewriting
  const ctx2 = { ...ctx, nodeIndex: indexBy(adjusted, n => n.id) };

  const { totalW, totalH, laneGeoms } = computeCanvasAndLanes(
    adjusted, ctx2, elkResult.width ?? 200, elkResult.height ?? 100,
  );

  const rawPaths = extractEdgePaths(elkResult, elkEdgeIdToOrig, edges.length);
  const lanePaths = ctx.useLanes ? straightenLaneEdges(edges, rawPaths, ctx2) : rawPaths;
  const { snappedPaths } = snapDecisionMergeEdges(edges, lanePaths, ctx2);

  return { width: totalW, height: totalH, nodes: adjusted, edgePaths: snappedPaths, lanes: laneGeoms };
}
