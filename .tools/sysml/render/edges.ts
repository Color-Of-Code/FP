/**
 * Edge rendering: emit a polyline (M…L…L…L) from the ELK-routed geometry.
 *
 * Endpoints are trimmed inward by ARROW_DEPTH so that the arrowhead tip
 * (markers use `refX="0"`) lands exactly on the visual boundary of the
 * target node or pin square.
 */

import { type GEdge, ARROW_DEPTH, COL } from "../types.ts";
import type { EdgePolyline } from "../layout.ts";
import { appendElement, appendGroup, appendText, type SvgParent } from "../lib/svg.ts";

// ── Path utilities ─────────────────────────────────────────────────────────

/**
 * Shorten a polyline by `depth` units along its final segment, preserving the
 * direction of approach.  This makes room for the arrowhead.
 */
function shortenEnd(pts: readonly (readonly [number, number])[], depth: number): [number, number][] {
  if (pts.length < 2) return pts.map(p => [p[0], p[1]] as [number, number]);
  const out = pts.slice(0, -1).map(p => [p[0], p[1]] as [number, number]);
  const [px, py] = pts[pts.length - 2];
  const [ex, ey] = pts[pts.length - 1];
  const dx = ex - px, dy = ey - py;
  const len = Math.hypot(dx, dy) || 1;
  const k = Math.max(0, len - depth) / len;
  out.push([px + dx * k, py + dy * k]);
  return out;
}

/** Build the SVG path `d` attribute from a polyline. */
function polylineToD(pts: readonly (readonly [number, number])[]): string {
  if (pts.length === 0) return "";
  const [x0, y0] = pts[0];
  const tail = pts.slice(1).map(([x, y]) => `L${x.toFixed(1)},${y.toFixed(1)}`).join(" ");
  return `M${x0.toFixed(1)},${y0.toFixed(1)} ${tail}`.trimEnd();
}

/** Find the midpoint of the longest horizontal-or-vertical segment. */
function labelAnchor(pts: readonly (readonly [number, number])[]): [number, number] {
  if (pts.length < 2) return [0, 0];
  let bestLen = -1;
  let bestMid: [number, number] = [
    (pts[0][0] + pts[pts.length - 1][0]) / 2,
    (pts[0][1] + pts[pts.length - 1][1]) / 2,
  ];
  for (let i = 0; i < pts.length - 1; i++) {
    const [ax, ay] = pts[i];
    const [bx, by] = pts[i + 1];
    const len = Math.hypot(bx - ax, by - ay);
    if (len > bestLen) {
      bestLen = len;
      bestMid = [(ax + bx) / 2, (ay + by) / 2];
    }
  }
  return bestMid;
}

// ── Edge renderer ──────────────────────────────────────────────────────────

/**
 * Append one edge as an SVG `<g>` containing an orthogonal polyline
 * (and an optional label) that follows the ELK-routed geometry.
 */
export function appendGEdge(
  parent: SvgParent,
  e: GEdge,
  pts: EdgePolyline,
): void {
  if (pts.length < 2) return; // routing skipped (e.g. unknown endpoints)

  const trimmed   = shortenEnd(pts, ARROW_DEPTH);
  const edgeCol   = e.isHof ? COL.hofEdge : COL.edgeStroke;
  const markerRef = !e.isObjectFlow ? "url(#arrowOpen)"
    : e.isHof ? "url(#arrowHof)"
    : "url(#arrowFilled)";

  const group = appendGroup(parent, {
    class: e.isHof ? "edge hof-edge" : "edge",
  });

  const path = appendElement(group, "path", {
    d: polylineToD(trimmed),
    fill: "none",
    stroke: edgeCol,
    "stroke-width": 1.5,
    "stroke-linejoin": "round",
    "stroke-linecap": "round",
    "marker-end": markerRef,
  });
  if (!e.isObjectFlow) path.attr("stroke-dasharray", "6,4");

  if (e.label) {
    const [lx, ly] = labelAnchor(pts);
    appendText(group, e.label, {
      x: lx,
      y: ly - 6,
      "text-anchor": "middle",
      "dominant-baseline": "middle",
      "font-size": 9,
      "font-family": "sans-serif",
      fill: "#333",
      stroke: "white",
      "stroke-width": 3,
      "paint-order": "stroke fill",
    });
  }
}
