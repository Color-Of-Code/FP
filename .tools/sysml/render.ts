/**
 * SVG rendering for SysML v2 activity and IBD diagrams.
 *
 * Visual conventions (OMG SysML v2 / ISO 19514):
 *   Action node:  rounded rectangle, name centred
 *   Object node:  plain rectangle, «stereotype» above name
 *   Object flow:  solid line with filled arrowhead
 *   Control flow: dashed line with open arrowhead
 *   Initial node: filled black circle
 *   Final node:   bull's-eye (outer circle + inner filled circle)
 *   Activity frame: rounded rect with pentagon name tab
 *   Pins:         small squares on action boundary (in = left, out = right)
 */

import type {
  GNode, GEdge, PortUsage, PartDef, ActionDef, ActivityDef, DiagramMeta, Model,
  DecisionNode, MergeNode,
} from "./types.ts";
import {
  ACTION_W, ACTION_H, ACTION_RX, PIN_SZ,
  INIT_R, FINAL_R, FINAL_R_INNER, DECISION_SZ,
  FRAME_PAD, FRAME_TAB_W, FRAME_TAB_H, BRANCH_SEP_H, ARROW_DEPTH,
  COL, nodeDims, escXml,
} from "./types.ts";
import { layeredLayout } from "./layout.ts";

// ── Geometry helpers ───────────────────────────────────────────────────────

/** Clip point on a circular or rectangular boundary toward (tx, ty). */
function clipPoint(n: GNode, tx: number, ty: number): [number, number] {
  const dx = tx - n.x; const dy = ty - n.y;
  if (n.kind === "initial" || n.kind === "final") {
    const r = n.kind === "initial" ? INIT_R : FINAL_R;
    const d = Math.sqrt(dx * dx + dy * dy) || 1;
    return [n.x + (dx / d) * r, n.y + (dy / d) * r];
  }
  if (n.kind === "decision" || n.kind === "merge") {
    // Diamond boundary: |dx/hw| + |dy/hh| = 1
    const hw = n.w / 2; const hh = n.h / 2;
    if (dx === 0 && dy === 0) return [n.x + hw, n.y];
    const t = 1 / (Math.abs(dx) / hw + Math.abs(dy) / hh);
    return [n.x + dx * t, n.y + dy * t];
  }
  const hw = n.w / 2; const hh = n.h / 2;
  if (dx === 0 && dy === 0) return [n.x + hw, n.y];
  const sx = dx === 0 ? Infinity : hw / Math.abs(dx);
  const sy = dy === 0 ? Infinity : hh / Math.abs(dy);
  const sc = Math.min(sx, sy);
  return [n.x + dx * sc, n.y + dy * sc];
}

/**
 * Pin-aware endpoint y-position on an action node's left (in) or right (out) edge.
 * `index` is 0-based among the edges connecting to this side; `total` is the count.
 */
function pinSlotY(n: GNode, index: number, total: number): number {
  const count = Math.max(total, 1);
  return n.y - n.h / 2 + (n.h / (count + 1)) * (index + 1);
}

type Pt4 = [number, number, number, number];

/**
 * Assign each object-flow edge to a pin slot on action nodes using semantic
 * matching so the correct pin is targeted regardless of spatial position.
 *
 * Priority (incoming edge from src → action dst):
 *   1. src is action  → match src.outPin name to dst.inPin name
 *   2. src is object  → match src.id to dst.inPin name
 *   3. fallback       → assign leftover slots in y-sorted order
 *
 * Symmetric logic for outgoing (action src → dst):
 *   1. dst is action  → match src.outPin name to dst.inPin name (from src side)
 *   2. dst is object  → match src.outPin name to dst.id
 *   3. fallback       → y-sorted order
 */
function semanticPinIndex(
  nodeId: string,
  es: GEdge[],
  nodeMap: Map<string, GNode>,
  side: "in" | "out",
): Map<GEdge, [number, number]> {
  const result = new Map<GEdge, [number, number]>();
  const node = nodeMap.get(nodeId);
  const pins = side === "in" ? (node?.inPins ?? []) : (node?.outPins ?? []);

  if (node?.kind !== "action" || pins.length === 0) {
    // No pin matching — assign positionally in y-sorted order
    const sorted = [...es].sort((a, b) => {
      const opp = side === "in" ? a.from : a.to;
      const oppB = side === "in" ? b.from : b.to;
      return (nodeMap.get(opp)?.y ?? 0) - (nodeMap.get(oppB)?.y ?? 0);
    });
    sorted.forEach((e, i) => result.set(e, [i, es.length]));
    return result;
  }

  const assigned = new Map<GEdge, number>(); // edge → pin slot index
  const usedSlots = new Set<number>();
  const unmatched: GEdge[] = [];

  for (const e of es) {
    const otherId = side === "in" ? e.from : e.to;
    const other = nodeMap.get(otherId);
    let slotIdx = -1;

    if (other?.kind === "action") {
      // Match by pin names that appear in both the other node and this node
      const otherPins = side === "in" ? other.outPins : other.inPins;
      for (const p of otherPins) {
        const idx = pins.findIndex((q, i) => q === p && !usedSlots.has(i));
        if (idx !== -1) { slotIdx = idx; break; }
      }
    }
    if (slotIdx === -1 && other) {
      // Match by node id → pin name
      const idx = pins.findIndex((q, i) => q === other.id && !usedSlots.has(i));
      if (idx !== -1) slotIdx = idx;
    }

    if (slotIdx !== -1) {
      assigned.set(e, slotIdx);
      usedSlots.add(slotIdx);
    } else {
      unmatched.push(e);
    }
  }

  // Assign remaining unmatched edges to unused slots in y-sorted order
  const unusedSlots = pins.map((_, i) => i).filter(i => !usedSlots.has(i));
  const sortedUnmatched = [...unmatched].sort((a, b) => {
    const opp = side === "in" ? a.from : a.to;
    const oppB = side === "in" ? b.from : b.to;
    return (nodeMap.get(opp)?.y ?? 0) - (nodeMap.get(oppB)?.y ?? 0);
  });
  sortedUnmatched.forEach((e, i) =>
    assigned.set(e, unusedSlots[i] ?? pins.length - 1));

  es.forEach(e => result.set(e, [assigned.get(e) ?? 0, pins.length]));
  return result;
}

function computeEndpoints(
  edges: GEdge[],
  nodeMap: Map<string, GNode>,
): Pt4[] {
  // Gather per-node incoming/outgoing object-flow edges
  const incoming = new Map<string, GEdge[]>();
  const outgoing = new Map<string, GEdge[]>();
  for (const e of edges) {
    if (!e.isObjectFlow) continue;
    if (!incoming.has(e.to)) incoming.set(e.to, []);
    incoming.get(e.to)!.push(e);
    if (!outgoing.has(e.from)) outgoing.set(e.from, []);
    outgoing.get(e.from)!.push(e);
  }

  // Build semantic pin → slot mappings
  const inIdx = new Map<GEdge, [number, number]>();
  const outIdx = new Map<GEdge, [number, number]>();
  for (const [nodeId, es] of incoming) {
    const m = semanticPinIndex(nodeId, es, nodeMap, "in");
    for (const [e, v] of m) inIdx.set(e, v);
  }
  for (const [nodeId, es] of outgoing) {
    const m = semanticPinIndex(nodeId, es, nodeMap, "out");
    for (const [e, v] of m) outIdx.set(e, v);
  }

  return edges.map(e => {
    const from = nodeMap.get(e.from)!;
    const to = nodeMap.get(e.to)!;
    let x1: number, y1: number, x2: number, y2: number;

    // ── Source endpoint ──────────────────────────────────────────────────
    if (from.kind === "action" && e.isObjectFlow) {
      const [idx, total] = outIdx.get(e) ?? [0, 1];
      // Depart from the outer (right) edge of the output-pin square
      x1 = from.x + from.w / 2 + PIN_SZ / 2;
      y1 = pinSlotY(from, idx, total);
    } else if (from.kind === "action") {
      // control flow: depart from right centre
      x1 = from.x + from.w / 2;
      y1 = from.y;
    } else {
      // Clip toward the target's exact path endpoint (boundary − arrow depth)
      // so the source departure direction is correct.
      let tgtX = to.x, tgtY = to.y;
      if (to.kind === "action" && e.isObjectFlow) {
        const [idx, total] = inIdx.get(e) ?? [0, 1];
        tgtX = to.x - to.w / 2 - PIN_SZ / 2 - ARROW_DEPTH;
        tgtY = pinSlotY(to, idx, total);
      } else if (to.kind === "action") {
        tgtX = to.x - to.w / 2 - ARROW_DEPTH;
        tgtY = to.y;
      }
      [x1, y1] = clipPoint(from, tgtX, tgtY);
    }

    // ── Target endpoint ──────────────────────────────────────────────────
    // All edges use refX="0" (back of arrowhead at path endpoint), so the
    // path must end ARROW_DEPTH before the visual boundary so the tip lands
    // exactly on it.
    if (to.kind === "action" && e.isObjectFlow) {
      const [idx, total] = inIdx.get(e) ?? [0, 1];
      x2 = to.x - to.w / 2 - PIN_SZ / 2 - ARROW_DEPTH;
      y2 = pinSlotY(to, idx, total);
    } else if (to.kind === "action") {
      // control flow: arrive at left centre
      x2 = to.x - to.w / 2 - ARROW_DEPTH;
      y2 = to.y;
    } else {
      // Clip to boundary, then pull back so the tip (not the path end) is
      // on the boundary.  The final Bezier tangent is always horizontal, so
      // subtracting ARROW_DEPTH from x is exact.
      [x2, y2] = clipPoint(to, x1, y1);
      x2 -= ARROW_DEPTH;
    }

    return [x1, y1, x2, y2] as Pt4;
  });
}

// ── Node renderers ─────────────────────────────────────────────────────────

function renderActionNode(n: GNode): string {
  const tip = n.tooltip ? `<title>${escXml(n.tooltip)}</title>` : "";
  const rx = (n.x - n.w / 2).toFixed(1);
  const ry = (n.y - n.h / 2).toFixed(1);
  const nameLines = n.label.split("\n");
  const LH = 13;
  const textEls = nameLines.map((l, i) =>
    `<text x="${n.x.toFixed(1)}" y="${(n.y + (i - (nameLines.length - 1) / 2) * LH).toFixed(1)}" text-anchor="middle" font-size="11" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(l)}</text>`
  ).join("\n    ");

  const inPinEls = n.inPins.map((p, i) => {
    const py = n.y - n.h / 2 + (n.h / (n.inPins.length + 1)) * (i + 1);
    const px = n.x - n.w / 2 - PIN_SZ / 2;
    // Label placed INSIDE the node (right of pin square) so arriving arrows never cross it
    return `<rect x="${px.toFixed(1)}" y="${(py - PIN_SZ / 2).toFixed(1)}" width="${PIN_SZ}" height="${PIN_SZ}" fill="${COL.pinFill}" stroke="${COL.pinStroke}" stroke-width="1"/>
    <text x="${(px + PIN_SZ + 2).toFixed(1)}" y="${py.toFixed(1)}" text-anchor="start" font-size="8" font-family="sans-serif" dominant-baseline="middle" fill="#555" stroke="white" stroke-width="2" paint-order="stroke fill">${escXml(p)}</text>`;
  }).join("\n    ");

  const outPinEls = n.outPins.map((p, i) => {
    const py = n.y - n.h / 2 + (n.h / (n.outPins.length + 1)) * (i + 1);
    const px = n.x + n.w / 2 - PIN_SZ / 2;
    // Label placed INSIDE the node (left of pin square) so departing arrows never cross it
    return `<rect x="${px.toFixed(1)}" y="${(py - PIN_SZ / 2).toFixed(1)}" width="${PIN_SZ}" height="${PIN_SZ}" fill="${COL.pinFill}" stroke="${COL.pinStroke}" stroke-width="1"/>
    <text x="${(px - 2).toFixed(1)}" y="${py.toFixed(1)}" text-anchor="end" font-size="8" font-family="sans-serif" dominant-baseline="middle" fill="#555" stroke="white" stroke-width="2" paint-order="stroke fill">${escXml(p)}</text>`;
  }).join("\n    ");

  return `  <g class="action-node">${tip}
    <rect x="${rx}" y="${ry}" width="${n.w}" height="${n.h}" rx="${ACTION_RX}" fill="${COL.actionFill}" stroke="${COL.actionStroke}" stroke-width="1.5"/>
    ${textEls}
    ${inPinEls}
    ${outPinEls}
  </g>`;
}

function renderObjectNode(n: GNode): string {
  const tip = n.tooltip ? `<title>${escXml(n.tooltip)}</title>` : "";
  const rx = (n.x - n.w / 2).toFixed(1);
  const ry = (n.y - n.h / 2).toFixed(1);
  const fill = n.isHof ? COL.hofFill : COL.objFill;
  const stroke = n.isHof ? COL.hofStroke : COL.objStroke;
  const stereo = n.isHof ? "«function»" : "";

  if (stereo) {
    return `  <g class="object-node hof">${tip}
    <rect x="${rx}" y="${ry}" width="${n.w}" height="${n.h}" fill="${fill}" stroke="${stroke}" stroke-width="1.5"/>
    <text x="${n.x.toFixed(1)}" y="${(n.y - 7).toFixed(1)}" text-anchor="middle" font-size="9" font-style="italic" font-family="sans-serif" dominant-baseline="middle" fill="${COL.hofStroke}">${escXml(stereo)}</text>
    <text x="${n.x.toFixed(1)}" y="${(n.y + 7).toFixed(1)}" text-anchor="middle" font-size="11" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(n.label)}</text>
  </g>`;
  }
  return `  <g class="object-node">${tip}
    <rect x="${rx}" y="${ry}" width="${n.w}" height="${n.h}" fill="${fill}" stroke="${stroke}" stroke-width="1.5"/>
    <text x="${n.x.toFixed(1)}" y="${n.y.toFixed(1)}" text-anchor="middle" font-size="11" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(n.label)}</text>
  </g>`;
}

function renderInitialNode(n: GNode): string {
  return `  <g class="initial-node">
    <circle cx="${n.x.toFixed(1)}" cy="${n.y.toFixed(1)}" r="${INIT_R}" fill="${COL.initFill}"/>
  </g>`;
}

function renderFinalNode(n: GNode): string {
  return `  <g class="final-node">
    <circle cx="${n.x.toFixed(1)}" cy="${n.y.toFixed(1)}" r="${FINAL_R}" fill="none" stroke="${COL.finalStroke}" stroke-width="2"/>
    <circle cx="${n.x.toFixed(1)}" cy="${n.y.toFixed(1)}" r="${FINAL_R_INNER}" fill="${COL.finalFill}"/>
  </g>`;
}

function renderDiamondNode(n: GNode): string {
  const tip = n.tooltip ? `<title>${escXml(n.tooltip)}</title>` : "";
  const hw = n.w / 2; const hh = n.h / 2;
  const pts = `${n.x.toFixed(1)},${(n.y - hh).toFixed(1)} ${(n.x + hw).toFixed(1)},${n.y.toFixed(1)} ${n.x.toFixed(1)},${(n.y + hh).toFixed(1)} ${(n.x - hw).toFixed(1)},${n.y.toFixed(1)}`;
  return `  <g class="${n.kind}-node">${tip}
    <polygon points="${pts}" fill="#fff9c4" stroke="#f9a825" stroke-width="1.5"/>
  </g>`;
}

function renderGNode(n: GNode): string {
  switch (n.kind) {
    case "action":    return renderActionNode(n);
    case "object":    return renderObjectNode(n);
    case "initial":   return renderInitialNode(n);
    case "final":     return renderFinalNode(n);
    case "decision":  return renderDiamondNode(n);
    case "merge":     return renderDiamondNode(n);
    case "separator": return ""; // invisible layout-only spacer
  }
}

// ── Edge renderer ──────────────────────────────────────────────────────────

function renderGEdge(e: GEdge, pt: Pt4): string {
  const [x1, y1, x2, y2] = pt;

  const dx = x2 - x1; const dy = y2 - y1;
  const cpOff = Math.abs(dy) < 15 ? 0 : Math.abs(dx) * 0.35;
  const cp1x = x1 + cpOff; const cp1y = y1;
  const cp2x = x2 - cpOff; const cp2y = y2;

  const edgeCol = e.isHof ? COL.hofEdge : COL.edgeStroke;
  // Consistent 1.5 px matches node border weight
  const sw = 1.5;
  const dashAttr = e.isObjectFlow ? "" : ' stroke-dasharray="6,4"';
  // HOF object-flow gets the teal arrowhead; control flow gets open arrowhead
  const markerRef = !e.isObjectFlow ? "url(#arrowOpen)" : e.isHof ? "url(#arrowHof)" : "url(#arrowFilled)";

  let labelEl = "";
  if (e.label) {
    // Offset perpendicular-above the chord midpoint so the label never sits on the path.
    // "Above" = rotate the chord direction 90° toward negative-y (screen up).
    // For a left-to-right chord (dx > 0): perp = (dy/len, -dx/len) → always has a
    // negative y-component, so it points upward regardless of slope.
    const len = Math.sqrt(dx * dx + dy * dy) || 1;
    const LABEL_OFF = 13;
    const lx = ((x1 + x2) / 2 + (dy / len) * LABEL_OFF).toFixed(1);
    const ly = ((y1 + y2) / 2 - (dx / len) * LABEL_OFF).toFixed(1);
    // White halo via paint-order keeps text readable against edges and fills
    labelEl = `<text x="${lx}" y="${ly}" text-anchor="middle" dominant-baseline="middle" font-size="9" font-family="sans-serif" fill="#333" stroke="white" stroke-width="3" paint-order="stroke fill">${escXml(e.label)}</text>`;
  }

  return `  <g class="edge${e.isHof ? " hof-edge" : ""}">
    <path d="M${x1.toFixed(1)},${y1.toFixed(1)} C${cp1x.toFixed(1)},${cp1y.toFixed(1)} ${cp2x.toFixed(1)},${cp2y.toFixed(1)} ${x2.toFixed(1)},${y2.toFixed(1)}" fill="none" stroke="${edgeCol}" stroke-width="${sw}"${dashAttr} marker-end="${markerRef}"/>
    ${labelEl}
  </g>`;
}

// ── Activity frame ─────────────────────────────────────────────────────────

function renderActivityFrame(name: string, W: number, H: number): string {
  // Measure the full label string (font-size 10 sans-serif ≈ 6.2 px/char)
  const label = `«activity» ${name}`;
  const tw = Math.min(FRAME_TAB_W, label.length * 6.2 + 16);
  const th = FRAME_TAB_H;
  const tabPath = `M0,0 L${tw},0 L${tw},${th - 10} L${tw - 10},${th} L0,${th} Z`;

  return `  <rect x="0" y="0" width="${W}" height="${H}" rx="8" fill="${COL.frameFill}" stroke="${COL.frameStroke}" stroke-width="1.5"/>
  <g class="activity-frame-tab">
    <path d="${tabPath}" fill="#e0e0e0" stroke="${COL.frameStroke}" stroke-width="1"/>
    <text x="${(tw / 2).toFixed(1)}" y="${(th / 2 + 1).toFixed(1)}" text-anchor="middle" font-size="10" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(label)}</text>
  </g>`;
}

// ── IBD renderer ───────────────────────────────────────────────────────────

function renderIbd(
  partDef: PartDef,
  diagram: DiagramMeta,
): [string, number, number] {
  const MARGIN = 60;
  const nodes: GNode[] = [];
  const nodeMap = new Map<string, GNode>();

  for (const p of partDef.parts) {
    const role = diagram.shows[p.id] ?? "type";
    const isHof = role === "hof";
    const tooltip = diagram.tooltips[p.id];
    const n: GNode = {
      id: p.id, label: `${p.id} : ${p.type}`, stereotype: undefined,
      kind: role === "function" ? "action" : "object",
      isHof, tooltip, x: 0, y: 0, w: 0, h: 0,
      inPins: [], outPins: [],
    };
    [n.w, n.h] = nodeDims(n);
    nodes.push(n); nodeMap.set(p.id, n);
  }

  const edges: GEdge[] = [];
  for (const c of partDef.connections) {
    const srcRole = diagram.shows[c.from] ?? "type";
    const isHof = (c.via?.toLowerCase().includes("hof") ?? false) || srcRole === "hof";
    edges.push({ from: c.from, to: c.to, label: c.label, isHof, isObjectFlow: true });
  }

  const [innerW, innerH] = layeredLayout(nodes, edges, "LR");
  for (const n of nodes) { n.x += MARGIN; n.y += MARGIN; }

  const W = innerW + 2 * MARGIN;
  const H = innerH + 2 * MARGIN;

  const inPorts = partDef.ports.filter(p => p.direction === "in" || p.direction === "inout");
  const outPorts = partDef.ports.filter(p => p.direction === "out");

  function portSquares(ports: PortUsage[], side: "left" | "right"): string {
    if (ports.length === 0) return "";
    const spacing = H / (ports.length + 1);
    return ports.map((p, i) => {
      const py = spacing * (i + 1);
      const px = side === "left" ? -PIN_SZ / 2 : W - PIN_SZ / 2;
      const label = `${p.id} : ${p.type}`;
      const labelX = side === "left" ? px - 3 : px + PIN_SZ + 3;
      const anchor = side === "left" ? "end" : "start";
      return `<rect x="${px.toFixed(1)}" y="${(py - PIN_SZ / 2).toFixed(1)}" width="${PIN_SZ}" height="${PIN_SZ}" fill="${COL.pinFill}" stroke="${COL.pinStroke}" stroke-width="1.5"/>
  <text x="${labelX.toFixed(1)}" y="${py.toFixed(1)}" font-size="9" font-family="sans-serif" dominant-baseline="middle" text-anchor="${anchor}" fill="#444">${escXml(label)}</text>`;
    }).join("\n  ");
  }

  const blockLabel = `<text x="${(W / 2).toFixed(1)}" y="18" text-anchor="middle" font-size="12" font-weight="bold" font-family="sans-serif" fill="${COL.labelFill}">${escXml("«block» " + partDef.name)}</text>`;
  const boundary = `<rect x="0" y="0" width="${W}" height="${H}" rx="4" fill="#f8f8ff" stroke="#6666c0" stroke-width="2"/>`;

  const pts = computeEndpoints(edges, nodeMap);
  const edgeEls = edges.map((e, i) => renderGEdge(e, pts[i])).join("\n");
  const nodeEls = nodes.map(n => renderGNode(n)).join("\n");

  return [`${boundary}\n${blockLabel}\n${portSquares(inPorts, "left")}\n${portSquares(outPorts, "right")}\n${edgeEls}\n${nodeEls}`, W, H];
}

// ── Activity renderer ──────────────────────────────────────────────────────

function renderActivity(
  actDef: ActivityDef,
  diagram: DiagramMeta,
  actionDefs: Map<string, ActionDef>,
): [string, number, number] {
  const nodes: GNode[] = [];
  const nodeMap = new Map<string, GNode>();

  for (const a of actDef.actions) {
    const tooltip = diagram.tooltips[a.id];
    const ad = actionDefs.get(a.type);
    const inPins = ad ? ad.pins.filter(p => p.direction === "in").map(p => p.id) : [];
    const outPins = ad ? ad.pins.filter(p => p.direction === "out").map(p => p.id) : [];
    const n: GNode = {
      id: a.id, label: a.id,
      stereotype: a.type,
      kind: "action", isHof: false, tooltip,
      x: 0, y: 0, w: ACTION_W, h: ACTION_H,
      inPins, outPins,
    };
    nodes.push(n); nodeMap.set(a.id, n);
  }
  for (const o of actDef.objects) {
    const role = diagram.shows[o.id] ?? "type";
    const isHof = role === "hof";
    const tooltip = diagram.tooltips[o.id];
    const n: GNode = {
      id: o.id, label: `${o.id} : ${o.type}`,
      kind: "object", isHof, tooltip,
      x: 0, y: 0, w: 0, h: 0,
      inPins: [], outPins: [],
    };
    [n.w, n.h] = nodeDims(n);
    nodes.push(n); nodeMap.set(o.id, n);
  }

  for (const d of actDef.decisions) {
    const tooltip = diagram.tooltips[d.id];
    const n: GNode = {
      id: d.id, label: "",
      kind: "decision", isHof: false, tooltip,
      x: 0, y: 0, w: DECISION_SZ, h: DECISION_SZ,
      inPins: [], outPins: [],
    };
    nodes.push(n); nodeMap.set(d.id, n);
  }

  for (const m of actDef.merges) {
    const tooltip = diagram.tooltips[m.id];
    const n: GNode = {
      id: m.id, label: "",
      kind: "merge", isHof: false, tooltip,
      x: 0, y: 0, w: DECISION_SZ, h: DECISION_SZ,
      inPins: [], outPins: [],
    };
    nodes.push(n); nodeMap.set(m.id, n);
  }

  const edges: GEdge[] = [];
  for (const f of actDef.flows) {
    if (!nodeMap.has(f.from) || !nodeMap.has(f.to)) continue;
    const srcNode = nodeMap.get(f.from)!;
    edges.push({ from: f.from, to: f.to, label: f.label, isHof: srcNode.isHof, isObjectFlow: true });
  }
  for (const s of actDef.successions) {
    if (!nodeMap.has(s.from) || !nodeMap.has(s.to)) continue;
    edges.push({ from: s.from, to: s.to, label: undefined, isHof: false, isObjectFlow: false });
  }

  // ── Branch separators ────────────────────────────────────────────────────
  // For each decision node, inject one invisible separator node (zero width,
  // BRANCH_SEP_H tall) with edges decision→sep (minlen=1) and sep→merge
  // (minlen=2).  The minlen=2 forces the separator to land at the same rank
  // as the direct branch targets, and its height pushes the branches apart
  // vertically so that neither branch edge overlaps the other branch's nodes.
  const mergeIdSet = new Set(actDef.merges.map(m => m.id));

  function findMerge(decisionId: string): string | null {
    const queue = [decisionId];
    const visited = new Set<string>();
    while (queue.length > 0) {
      const curr = queue.shift()!;
      if (visited.has(curr)) continue;
      visited.add(curr);
      if (curr !== decisionId && mergeIdSet.has(curr)) return curr;
      for (const e of edges) {
        if (e.from === curr && !visited.has(e.to)) queue.push(e.to);
      }
    }
    return null;
  }

  for (const d of actDef.decisions) {
    const mergeId = findMerge(d.id);
    if (!mergeId) continue;
    const sepId = `_sep_${d.id}`;
    const sepNode: GNode = {
      id: sepId, label: "",
      kind: "separator", isHof: false, tooltip: undefined,
      x: 0, y: 0, w: 1, h: BRANCH_SEP_H,
      inPins: [], outPins: [],
    };
    nodes.push(sepNode);
    nodeMap.set(sepId, sepNode);
    // minlen=1: separator lands at rank(decision)+1 (same rank as branch starts)
    // minlen=2: merge stays ≥ rank(separator)+2, keeping separator at branch rank
    edges.push({ from: d.id,  to: sepId,  label: undefined, isHof: false, isObjectFlow: false, isSeparator: true, minlen: 1 });
    edges.push({ from: sepId, to: mergeId, label: undefined, isHof: false, isObjectFlow: false, isSeparator: true, minlen: 2 });
  }

  const [innerW, innerH] = layeredLayout(nodes, edges, diagram.direction ?? "LR");
  for (const n of nodes) { n.x += FRAME_PAD; n.y += FRAME_PAD + FRAME_TAB_H; }

  const W = innerW + 2 * FRAME_PAD;
  const H = innerH + 2 * FRAME_PAD + FRAME_TAB_H;

  const frame = renderActivityFrame(diagram.name ?? actDef.name, W, H);
  const pts = computeEndpoints(edges, nodeMap);
  const edgeEls = edges.map((e, i) => e.isSeparator ? "" : renderGEdge(e, pts[i])).join("\n");
  const nodeEls = nodes.map(n => renderGNode(n)).join("\n");

  return [`${frame}\n${edgeEls}\n${nodeEls}`, W, H];
}

// ── SVG shell ──────────────────────────────────────────────────────────────

const SVG_DEFS = `<defs>
  <marker id="arrowFilled" viewBox="0 0 10 10" refX="0" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="${COL.edgeStroke}"/>
  </marker>
  <marker id="arrowOpen" viewBox="0 0 10 10" refX="0" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10" fill="none" stroke="${COL.edgeStroke}" stroke-width="1.5"/>
  </marker>
  <marker id="arrowHof" viewBox="0 0 10 10" refX="0" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="${COL.hofEdge}"/>
  </marker>
</defs>`;

function makeSvg(inner: string, title: string, W: number, H: number): string {
  const TITLE_H = 28;
  const totalH = H + TITLE_H;
  const titleEl = `<text x="${(W / 2).toFixed(1)}" y="20" text-anchor="middle" font-size="14" font-weight="bold" font-family="sans-serif" fill="#222">${escXml(title)}</text>`;
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${totalH}" width="${W}" height="${totalH}">
${SVG_DEFS}
<rect width="${W}" height="${totalH}" fill="white"/>
${titleEl}
<g transform="translate(0,${TITLE_H})">
${inner}
</g>
</svg>`;
}

// ── Orchestrator ───────────────────────────────────────────────────────────

export function modelToSvg(model: Model, baseName: string): string {
  const diag = model.diagram;
  const title = diag.title ?? baseName;

  if (diag.diagType === "ibd") {
    const allPartDefs = model.packages.flatMap(p => p.partDefs);
    const pd = diag.render
      ? allPartDefs.find(d => d.name === diag.render) ?? allPartDefs[0]
      : allPartDefs[0];
    if (!pd) return makeSvg(`<text x="20" y="40" fill="red">No part def found</text>`, title, 400, 100);
    const [inner, W, H] = renderIbd(pd, diag);
    return makeSvg(inner, title, W, H);
  } else {
    const allActivityDefs = model.packages.flatMap(p => p.activityDefs);
    const allActionDefs = new Map(model.packages.flatMap(p => p.actionDefs).map(a => [a.name, a]));
    const act = diag.render
      ? allActivityDefs.find(d => d.name === diag.render) ?? allActivityDefs[0]
      : allActivityDefs[0];
    if (!act) return makeSvg(`<text x="20" y="40" fill="red">No activity def found</text>`, title, 400, 100);
    const [inner, W, H] = renderActivity(act, diag, allActionDefs);
    return makeSvg(inner, title, W, H);
  }
}
