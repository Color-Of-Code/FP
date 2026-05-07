/**
 * High-level diagram rendering utilities.
 *
 * Encapsulates common SVG append patterns used by activity and IBD renderers,
 * reducing boilerplate in the `draw` callbacks.
 */

import { appendGNode } from "./nodes.ts";
import { appendGEdge } from "./edges.ts";
import { appendLaneBand } from "./lane.ts";
import type { GNode, GEdge, LaneGeom } from "../types.ts";
import type { EdgePolyline } from "../layout.ts";
import type { SvgParent } from "../lib/svg.ts";

/**
 * Append the core diagram elements: lanes, edges, nodes.
 * Assumes coordinates are already shifted.
 */
export function appendDiagramElements(
  parent: SvgParent,
  shiftedNodes: readonly GNode[],
  shiftedEdges: readonly GEdge[],
  shiftedPaths: readonly EdgePolyline[],
  shiftedLanes: readonly LaneGeom[],
): void {
  shiftedLanes.forEach(l => appendLaneBand(parent, l));
  shiftedEdges.forEach((e, i) => appendGEdge(parent, e, shiftedPaths[i]));
  shiftedNodes.forEach(n => appendGNode(parent, n));
}