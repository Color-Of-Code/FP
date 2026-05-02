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
  lanes: LaneSpec[] = [],
): Promise<LayoutResult> {
  if (nodes.length === 0) {
    return { width: 200, height: 100, edgePaths: edges.map(() => []), lanes: [] };
  }

  // Make sure widths/heights are up to date with current label content.
  for (const n of nodes) { [n.w, n.h] = nodeDims(n); }

  const useLanes = lanes.length > 0;

  // Lanes are a purely decorative post-layout grouping: they do not change
  // the layout direction, layering, or positioning of any node.  After ELK
  // has run, we measure each lane's member-node bounding box and draw a
  // labelled band behind that group.  Authors who want a top/bottom split
  // should arrange flow so HOFs end up above the binds naturally (e.g. by
  // making the HOFs sources with edges to bind actions).
  const direction = rankdir === "TB" ? "DOWN" : "RIGHT";
  const leafRankdir: "LR" | "TB" = rankdir;
  const inSide  = leafRankdir === "TB" ? "NORTH" : "WEST";
  const outSide = leafRankdir === "TB" ? "SOUTH" : "EAST";
  const altSide = leafRankdir === "TB" ? "EAST"  : "SOUTH";
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
    !n.isHof &&
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

  // ── Cross-lane object → action pin override ──────────────────────────────
  // When an object in one lane feeds into an action in another lane, we want
  // the destination pin on the perpendicular side (the side that faces the
  // source's lane), so the connecting edge becomes a clean vertical drop
  // (LR layout) or sideways shift (TB).  Without this, ELK still attaches
  // the pin on the WEST/NORTH side and routes a detour back into the node.
  // We also add a single port on the source object on the matching side so
  // the edge originates from the bottom (LR) / right (TB) of the object
  // instead of its west/east edge.  This applies both to HOF objects feeding
  // binds and to plain input objects feeding `pure`.
  //
  // Sides per leaf direction:
  //   LR layout: source above  → action pin NORTH, HOF port SOUTH.
  //              source below  → action pin SOUTH, HOF port NORTH.
  //   TB layout: source left   → action pin WEST,  HOF port EAST.
  //              source right  → action pin EAST,  HOF port WEST.
  const pinSideOverride = new Map<string, string>();
  /** edge index → ELK source-port id on a HOF object node. */
  const objectSrcPort = new Map<number, string>();
  /** object-node id → ports the HOF wants to expose. */
  const objectPorts = new Map<string, { side: string; portId: string }[]>();
  const objectPortIdOf = (nodeId: string, side: string): string =>
    `${nodeId}__obj__${side}`;
  if (useLanes) {
    const laneRankFor = new Map<string, number>();
    lanes.forEach((l, i) => l.members.forEach(m => laneRankFor.set(m, i)));
    edges.forEach((e, idx) => {
      if (!e.isObjectFlow || !e.dstPin) return;
      const src = nodeIndex.get(e.from);
      const tgt = nodeIndex.get(e.to);
      if (!src || !tgt || src.kind !== "object" || tgt.kind !== "action") return;
      const sr = laneRankFor.get(src.id);
      const tr = laneRankFor.get(tgt.id);
      if (sr === undefined || tr === undefined || sr === tr) return;
      // sr < tr  →  source is above target (LR), or to the left (TB).
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

      // Reserve a single port on the source object node on the matching side.
      const portId = objectPortIdOf(src.id, objSide);
      const list = objectPorts.get(src.id) ?? [];
      if (!list.find(p => p.portId === portId)) list.push({ side: objSide, portId });
      objectPorts.set(src.id, list);
      objectSrcPort.set(idx, portId);
    });
  }

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
      // Cross-lane HOF: expose a fixed-side port so the edge originates
      // from the bottom (or top, depending on lane order) of the HOF
      // object node, rather than its west/east boundary.
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

  // ── Run ELK ──────────────────────────────────────────────────────────────
  // Lanes are decoration only — the natural layered layout already places
  // plain-lane sources (HOFs feeding into binds) above the monad-lane chain
  // because the HOFs have edges going down into bind action pins.  When
  // lanes are declared, we additionally lift any *non-HOF* lane-zero member
  // (e.g. the chain entry point and the final result) up onto the same row
  // as the HOFs by pre-setting their y-coordinate and asking ELK to use
  // INTERACTIVE node placement, which honours those anchors while still
  // running its own crossing minimization and routing.

  if (useLanes) {
    const laneRankFor = new Map<string, number>();
    lanes.forEach((l, i) => l.members.forEach(m => laneRankFor.set(m, i)));
    const LANE_TOP = 14;
    const LANE_ROW = 74;
    for (const c of children) {
      const r = laneRankFor.get(c.id);
      if (r === undefined) continue;
      c.y = LANE_TOP + r * LANE_ROW;
    }
  }

  const rootLayoutOptions: Record<string, string> = {
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
  };
  if (useLanes) {
    rootLayoutOptions["elk.layered.spacing.nodeNodeBetweenLayers"] = String(Math.max(34, Math.floor(EDGE_GAP * 0.6)));
    rootLayoutOptions["elk.layered.nodePlacement.strategy"] = "INTERACTIVE";
    rootLayoutOptions["elk.layered.mergeEdges"]              = "false";
    rootLayoutOptions["elk.edgeLabels.inline"]               = "true";
  }

  const graph = {
    id: "root",
    layoutOptions: rootLayoutOptions,
    children,
    edges: elkEdges,
  };

  const result = (await elk.layout(graph as never)) as ElkResult;

  // ── Scatter node positions back ──────────────────────────────────────────
  const childMap = new Map<string, { x: number; y: number; w: number; h: number }>();
  for (const c of result.children ?? []) {
    childMap.set(c.id, { x: c.x ?? 0, y: c.y ?? 0, w: c.width ?? 0, h: c.height ?? 0 });
  }
  for (const n of nodes) {
    const c = childMap.get(n.id);
    if (c) {
      n.x = c.x + n.w / 2;
      n.y = c.y + n.h / 2;
    }
  }

  // ── Column-align cross-lane objects above their target action ────────────
  // For each cross-lane object→action edge, snap the object's x-centre to
  // the action's x-centre so the connecting arrow becomes a clean vertical
  // drop.  This handles both HOF objects feeding binds and plain entry
  // objects feeding `pure`.
  if (useLanes) {
    const objectTargets = new Map<string, string[]>();
    const laneOf = new Map<string, string>();
    lanes.forEach(l => l.members.forEach(m => laneOf.set(m, l.id)));
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
  }

  // ── Compact lower lanes horizontally ────────────────────────────────────
  // ELK still tends to keep layer gaps much wider than necessary once the
  // plain-lane HOFs are involved.  For lane diagrams we compact each lower
  // lane member sequence after layout, using only what must remain legible:
  // the node boxes themselves, the same-lane edge label between neighbours,
  // and enough room that aligned HOF boxes above adjacent binds do not
  // overlap.  This keeps the bind chain visibly tighter without sacrificing
  // the top-lane alignment.
  if (useLanes) {
    const laneIndexOf = new Map<string, number>();
    const incomingHofWidth = new Map<string, number>();
    lanes.forEach((lane, laneIdx) => lane.members.forEach(member => laneIndexOf.set(member, laneIdx)));
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

    // Pull terminal top-lane sinks back toward the action that produces them.
    // Without this, ELK leaves the final object at the original wide canvas
    // extent even after the bind chain has been compacted.
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

    const TOP_LANE_NODE_SHIFT = 8;
    for (const member of lanes[0]?.members ?? []) {
      const node = nodeIndex.get(member);
      if (!node) continue;
      node.y += TOP_LANE_NODE_SHIFT;
    }

    const LOWER_LANE_NODE_SHIFT = 14;
    for (let laneIdx = 1; laneIdx < lanes.length; laneIdx++) {
      for (const member of lanes[laneIdx].members) {
        const node = nodeIndex.get(member);
        if (!node) continue;
        node.y += LOWER_LANE_NODE_SHIFT;
      }
    }
  }

  // ── Collect lane geometry ────────────────────────────────────────────────
  // Lanes are decoration: their bounding box is the union of member-node
  // bounding boxes, padded out to span the full diagram width and aligned
  // with neighbouring lanes so the bands stack flush.
  const totalW = useLanes
    ? Math.max(200, ...nodes.map(n => n.x + n.w / 2)) + 30
    : (result.width ?? 200);
  const totalH = useLanes
    ? Math.max(100, ...nodes.map(n => n.y + n.h / 2)) + 12
    : (result.height ?? 100);
  const LANE_PAD_Y = 12;
  const LANE_HEADER_H = 18;
  const TOP_LANE_CLEARANCE = 10;
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
  // Sort by vertical position so adjacent lanes can be flushed together.
  const laneOrder = laneBoxes
    .map((b, i) => ({ b, i }))
    .sort((a, b) => a.b.minY - b.b.minY);
  // Snapshot the raw member-derived extents before alignment, so the
  // mid-point between two lanes is computed from the actual node bounds —
  // not from a partially-mutated neighbour.
  const rawExtents = laneOrder.map(({ b }) => ({ minY: b.minY, maxY: b.maxY }));
  // Align lane top/bottom edges so adjacent bands meet at the midline
  // between the closest member nodes from the two lanes.
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

  // ── Straighten same-lane horizontal chain edges ──────────────────────────
  // ELK's orthogonal router likes to push horizontal edge segments into a
  // dedicated channel between layers (often the gap between the plain row
  // and the monad row), causing pure horizontal chain edges to detour up
  // and back down again.  When two endpoints share a lane and a y-row, we
  // overrule that with a straight horizontal segment using the actual port
  // y-coordinate at each end.  The decision-merge rewrite below leaves
  // these edges alone because it only touches decision/merge endpoints.
  if (useLanes) {
    const laneOf = new Map<string, string>();
    lanes.forEach(l => l.members.forEach(m => laneOf.set(m, l.id)));
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
      // Cross-lane object → action: route as a clean vertical drop from the
      // source object's bottom (or top) edge straight to the action's top
      // pin.  This covers both HOF-to-bind edges and plain input-to-pure.
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
      // Final action → top-lane object: leave the action via its east pin,
      // then rise into the object's underside.  This keeps the last leg
      // simple and avoids the long high horizontal rail.
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
      // Other cross-lane object/action edges (entry and final result) are
      // rebuilt from the current node positions so post-layout compaction
      // cannot leave them attached to stale x-coordinates.
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
    lanes:  laneGeoms,
  };
}
