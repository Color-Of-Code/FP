/**
 * SVG arrowhead marker definitions.
 *
 * All markers use refX="0" — the back-center of the triangle is placed at
 * the path endpoint.  Path endpoints are pre-pulled back by ARROW_DEPTH so
 * the visual tip lands exactly on the target boundary (see types/constants.ts).
 */

import { COL } from "../types.ts";
import type { SvgParent } from "./title.ts";

/** Append the shared marker definitions to the root SVG document. */
export function appendArrowDefs(svg: SvgParent): void {
  const defs = svg.append("defs");

  const filled = defs.append("marker")
    .attr("id", "arrowFilled")
    .attr("viewBox", "0 0 10 10")
    .attr("refX", 0)
    .attr("refY", 5)
    .attr("markerWidth", 7)
    .attr("markerHeight", 7)
    .attr("orient", "auto-start-reverse");
  filled.append("path")
    .attr("d", "M0,0 L10,5 L0,10 z")
    .attr("fill", COL.edgeStroke);

  const open = defs.append("marker")
    .attr("id", "arrowOpen")
    .attr("viewBox", "0 0 10 10")
    .attr("refX", 0)
    .attr("refY", 5)
    .attr("markerWidth", 7)
    .attr("markerHeight", 7)
    .attr("orient", "auto-start-reverse");
  open.append("path")
    .attr("d", "M0,0 L10,5 L0,10")
    .attr("fill", "none")
    .attr("stroke", COL.edgeStroke)
    .attr("stroke-width", 1.5);

  const hof = defs.append("marker")
    .attr("id", "arrowHof")
    .attr("viewBox", "0 0 10 10")
    .attr("refX", 0)
    .attr("refY", 5)
    .attr("markerWidth", 7)
    .attr("markerHeight", 7)
    .attr("orient", "auto-start-reverse");
  hof.append("path")
    .attr("d", "M0,0 L10,5 L0,10 z")
    .attr("fill", COL.hofEdge);
}
