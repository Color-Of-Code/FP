/**
 * Shared graph construction helpers for activity and IBD renderers.
 *
 * Pure functions that build `GNode[]` / `GEdge[]` from AST domain objects,
 * and post-layout coordinate shifting.
 */

import type { GNode, GEdge } from "../types.ts";
import { nodeDims } from "../types.ts";
import type { EdgePolyline, LaneGeom } from "../layout.ts";
import { indexBy, bothInMap, pipe, A, O } from "../lib/fp.ts";

// ── Node-map builder (used by every renderer) ─────────────────────────────

/** Build an id→node lookup map from a flat node list. */
export const buildNodeMap = (nodes: readonly GNode[]): Map<string, GNode> =>
  indexBy(nodes, n => n.id);

// ── Edge filtering ────────────────────────────────────────────────────────

/**
 * Keep only edges whose `from` and `to` exist in the node map.
 * Curried for `pipe` use: `pipe(edges, filterEdges(nodeMap))`.
 */
export const filterEdges = <V, E extends { from: string; to: string }>(
  nodeMap: ReadonlyMap<string, V>,
) => (edges: readonly E[]): E[] => edges.filter(bothInMap(nodeMap));

// ── shiftCoordinates ──────────────────────────────────────────────────────

/** Shift all node positions, edge polylines, and lane geometries immutably. */
export function shiftCoordinates(
  nodes: readonly GNode[],
  edgePaths: readonly EdgePolyline[],
  lanes: readonly LaneGeom[],
  dx: number,
  dy: number,
): { shiftedNodes: GNode[]; shiftedPaths: EdgePolyline[]; shiftedLanes: LaneGeom[] } {
  const shiftedNodes = nodes.map(n => ({ ...n, x: n.x + dx, y: n.y + dy }));
  const shiftedPaths = edgePaths.map(pts =>
    pts.map(([x, y]) => [x + dx, y + dy] as [number, number]),
  );
  const shiftedLanes = lanes.map(l => ({
    ...l,
    x: l.x + dx,
    y: l.y + dy,
  }));
  return { shiftedNodes, shiftedPaths, shiftedLanes };
}

// ── Note node helper ──────────────────────────────────────────────────────

/** Build a GNode + GEdge pair for a note annotation. */
export function buildNoteNode(
  note: { id: string; text: string; target: string },
  tooltips: Record<string, string>,
): { node: GNode; edge: GEdge | null } {
  const lines = note.text.split(/\\n|\n/);
  const base: GNode = {
    id: note.id,
    label: lines[0] ?? "",
    kind: "note",
    isHof: false,
    tooltip: tooltips[note.id],
    x: 0, y: 0, w: 0, h: 0,
    inPins: [], outPins: [],
    noteLines: lines,
  };
  const [w, h] = nodeDims(base);
  const node: GNode = { ...base, w, h };
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
  return { node, edge };
}

/**
 * Build note nodes and the matching attachment edges, dropping any edges
 * whose endpoints are missing from the node map.  Used by both renderers.
 */
export const buildNotes = (
  notes: readonly { id: string; text: string; target: string }[],
  tooltips: Record<string, string>,
): { noteNodes: GNode[]; noteEdgesOf: (nodeMap: ReadonlyMap<string, GNode>) => GEdge[] } => {
  const built = notes.map(note => buildNoteNode(note, tooltips));
  const noteNodes = built.map(b => b.node);
  const noteEdgesOf = (nodeMap: ReadonlyMap<string, GNode>): GEdge[] =>
    pipe(
      built,
      A.filterMap(b => b.edge && nodeMap.has(b.edge.from) && nodeMap.has(b.edge.to)
        ? O.some(b.edge)
        : O.none),
    );
  return { noteNodes, noteEdgesOf };
};

