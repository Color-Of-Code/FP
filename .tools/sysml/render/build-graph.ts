/**
 * Shared graph construction helpers for activity and IBD renderers.
 *
 * Pure functions that build `GNode[]` / `GEdge[]` from AST domain objects,
 * and post-layout coordinate shifting.
 */

import type { GNode, GEdge } from "../types.ts";
import { nodeDims } from "../types.ts";
import type { EdgePolyline, LaneGeom } from "../layout.ts";

// ── shiftCoordinates ──────────────────────────────────────────────────────

/** Shift all node positions, edge polylines, and lane geometries in-place. */
export function shiftCoordinates(
  nodes: GNode[],
  edgePaths: EdgePolyline[],
  lanes: LaneGeom[],
  dx: number,
  dy: number,
): { shiftedPaths: EdgePolyline[]; shiftedLanes: LaneGeom[] } {
  for (const n of nodes) {
    n.x += dx;
    n.y += dy;
  }
  const shiftedPaths = edgePaths.map(pts =>
    pts.map(([x, y]) => [x + dx, y + dy] as [number, number]),
  );
  const shiftedLanes = lanes.map(l => ({
    ...l,
    x: l.x + dx,
    y: l.y + dy,
  }));
  return { shiftedPaths, shiftedLanes };
}

// ── Note node helper ──────────────────────────────────────────────────────

/** Build a GNode + GEdge pair for a note annotation. */
export function buildNoteNode(
  note: { id: string; text: string; target: string },
  tooltips: Record<string, string>,
): { node: GNode; edge: GEdge | null } {
  const lines = note.text.split(/\\n|\n/);
  const n: GNode = {
    id: note.id,
    label: lines[0] ?? "",
    kind: "note",
    isHof: false,
    tooltip: tooltips[note.id],
    x: 0, y: 0, w: 0, h: 0,
    inPins: [], outPins: [],
    noteLines: lines,
  };
  [n.w, n.h] = nodeDims(n);
  const edge: GEdge | null = note.target
    ? {
        from: note.id,
        to: note.target,
        label: undefined,
        isHof: false,
        isObjectFlow: false,
        isNoteAttachment: true,
      }
    : null;
  return { node: n, edge };
}
