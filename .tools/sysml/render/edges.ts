/**
 * Edge endpoint computation and SVG path rendering.
 *
 * Endpoints are clipped to node boundaries (circle, diamond, rectangle) and
 * adjusted for pin squares and the arrowhead depth so visual tips land exactly
 * on boundaries.  Bezier control points produce smooth horizontal-entry curves.
 */

import {
  type GNode, type GEdge,
  PIN_SZ, INIT_R, FINAL_R, ARROW_DEPTH,
  COL, escXml,
} from "../types.ts";
import { pinSlotY, semanticPinIndex } from "./pin.ts";

export type Pt4 = [number, number, number, number];

// ── Boundary clip ──────────────────────────────────────────────────────────

/** Clip a point on a node's boundary in the direction of (tx, ty). */
function clipPoint(n: GNode, tx: number, ty: number): [number, number] {
  const dx = tx - n.x;
  const dy = ty - n.y;

  if (n.kind === "initial" || n.kind === "final") {
    const r = n.kind === "initial" ? INIT_R : FINAL_R;
    const d = Math.sqrt(dx * dx + dy * dy) || 1;
    return [n.x + (dx / d) * r, n.y + (dy / d) * r];
  }

  if (n.kind === "decision" || n.kind === "merge") {
    // Diamond boundary: |dx/hw| + |dy/hh| = 1
    const hw = n.w / 2;
    const hh = n.h / 2;
    if (dx === 0 && dy === 0) return [n.x + hw, n.y];
    const t = 1 / (Math.abs(dx) / hw + Math.abs(dy) / hh);
    return [n.x + dx * t, n.y + dy * t];
  }

  // Rectangle
  const hw = n.w / 2;
  const hh = n.h / 2;
  if (dx === 0 && dy === 0) return [n.x + hw, n.y];
  const sx = dx === 0 ? Infinity : hw / Math.abs(dx);
  const sy = dy === 0 ? Infinity : hh / Math.abs(dy);
  const sc = Math.min(sx, sy);
  return [n.x + dx * sc, n.y + dy * sc];
}

// ── Endpoint computation ───────────────────────────────────────────────────

/**
 * Compute (x1,y1,x2,y2) for every edge.
 *
 * All path endpoints are placed ARROW_DEPTH before the visual boundary so
 * that — with refX="0" on the markers — the arrowhead tip lands exactly on
 * the boundary.
 */
export function computeEndpoints(
  edges: GEdge[],
  nodeMap: Map<string, GNode>,
): Pt4[] {
  // Gather per-node incoming/outgoing object-flow edge lists
  const incoming = new Map<string, GEdge[]>();
  const outgoing = new Map<string, GEdge[]>();
  for (const e of edges) {
    if (!e.isObjectFlow) continue;
    if (!incoming.has(e.to))   incoming.set(e.to, []);
    if (!outgoing.has(e.from)) outgoing.set(e.from, []);
    incoming.get(e.to)!.push(e);
    outgoing.get(e.from)!.push(e);
  }

  // Build semantic pin-slot index maps
  const inIdx  = new Map<GEdge, [number, number]>();
  const outIdx = new Map<GEdge, [number, number]>();
  for (const [id, es] of incoming) {
    for (const [e, v] of semanticPinIndex(id, es, nodeMap, "in"))  inIdx.set(e, v);
  }
  for (const [id, es] of outgoing) {
    for (const [e, v] of semanticPinIndex(id, es, nodeMap, "out")) outIdx.set(e, v);
  }

  return edges.map(e => {
    const from = nodeMap.get(e.from)!;
    const to   = nodeMap.get(e.to)!;
    let x1: number, y1: number, x2: number, y2: number;

    // ── Source endpoint ────────────────────────────────────────────────
    if (from.kind === "action" && e.isObjectFlow) {
      const [idx, total] = outIdx.get(e) ?? [0, 1];
      x1 = from.x + from.w / 2 + PIN_SZ / 2;   // outer edge of output-pin square
      y1 = pinSlotY(from, idx, total);
    } else if (from.kind === "action") {
      x1 = from.x + from.w / 2;
      y1 = from.y;
    } else {
      if (from.kind === "decision" && to.kind === "merge") {
        // Null branch exits from the bottom (SOUTH) vertex of the decision diamond.
        e.isSouthExit = true;
        x1 = from.x;
        y1 = from.y + from.h / 2;
      } else {
        // Clip toward the target's exact path endpoint so direction is correct
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
    }

    // ── Target endpoint ────────────────────────────────────────────────
    // Path ends ARROW_DEPTH before the boundary; arrowhead tip lands on it.
    if (to.kind === "action" && e.isObjectFlow) {
      const [idx, total] = inIdx.get(e) ?? [0, 1];
      x2 = to.x - to.w / 2 - PIN_SZ / 2 - ARROW_DEPTH;  // outer edge of input-pin square
      y2 = pinSlotY(to, idx, total);
    } else if (to.kind === "action") {
      x2 = to.x - to.w / 2 - ARROW_DEPTH;
      y2 = to.y;
    } else {
      [x2, y2] = clipPoint(to, x1, y1);
      x2 -= ARROW_DEPTH;
    }

    return [x1, y1, x2, y2] as Pt4;
  });
}

// ── Edge renderer ──────────────────────────────────────────────────────────

/** Render one edge as an SVG `<g>` with a cubic Bezier path and optional label. */
export function renderGEdge(e: GEdge, pt: Pt4): string {
  const [x1, y1, x2, y2] = pt;
  const dx = x2 - x1;
  const dy = y2 - y1;

  // South-exit edges (null branch from decision diamond) drop straight down
  // before curving toward the merge target.
  const SOUTH_DROP = 32;
  const cpOff = Math.abs(dy) < 15 ? 0 : Math.abs(dx) * 0.35;
  const cp1x = e.isSouthExit ? x1                              : x1 + cpOff;
  const cp1y = e.isSouthExit ? y1 + SOUTH_DROP                : y1;
  const cp2x = e.isSouthExit ? x2 - Math.max(cpOff, SOUTH_DROP) : x2 - cpOff;
  const cp2y = y2;

  const edgeCol   = e.isHof ? COL.hofEdge : COL.edgeStroke;
  const dashAttr  = e.isObjectFlow ? "" : ' stroke-dasharray="6,4"';
  const markerRef = !e.isObjectFlow ? "url(#arrowOpen)"
    : e.isHof ? "url(#arrowHof)"
    : "url(#arrowFilled)";

  let labelEl = "";
  if (e.label) {
    // Offset perpendicular-above the chord midpoint (always screen-upward for LR layouts)
    const len = Math.sqrt(dx * dx + dy * dy) || 1;
    const LABEL_OFF = 13;
    const lx = ((x1 + x2) / 2 + (dy / len) * LABEL_OFF).toFixed(1);
    const ly = ((y1 + y2) / 2 - (dx / len) * LABEL_OFF).toFixed(1);
    labelEl = `<text x="${lx}" y="${ly}" text-anchor="middle" dominant-baseline="middle" font-size="9" font-family="sans-serif" fill="#333" stroke="white" stroke-width="3" paint-order="stroke fill">${escXml(e.label)}</text>`;
  }

  return `  <g class="edge${e.isHof ? " hof-edge" : ""}">
    <path d="M${x1.toFixed(1)},${y1.toFixed(1)} C${cp1x.toFixed(1)},${cp1y.toFixed(1)} ${cp2x.toFixed(1)},${cp2y.toFixed(1)} ${x2.toFixed(1)},${y2.toFixed(1)}" fill="none" stroke="${edgeCol}" stroke-width="1.5"${dashAttr} marker-end="${markerRef}"/>
    ${labelEl}
  </g>`;
}
