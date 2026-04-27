/**
 * SVG arrowhead marker definitions.
 *
 * All markers use refX="0" — the back-center of the triangle is placed at
 * the path endpoint.  Path endpoints are pre-pulled back by ARROW_DEPTH so
 * the visual tip lands exactly on the target boundary (see types/constants.ts).
 */

import { COL } from "../types.ts";
import { appendElement, joinElements, setAttrs, type SvgParent } from "../lib/svg.ts";

const MARKERS = [
  { id: "arrowFilled", path: "M0,0 L10,5 L0,10 z", fill: COL.edgeStroke, stroke: undefined, strokeWidth: undefined },
  { id: "arrowOpen",   path: "M0,0 L10,5 L0,10",   fill: "none",        stroke: COL.edgeStroke, strokeWidth: 1.5 },
  { id: "arrowHof",    path: "M0,0 L10,5 L0,10 z", fill: COL.hofEdge,    stroke: undefined, strokeWidth: undefined },
] as const;

/** Append the shared marker definitions to the root SVG document. */
export function appendArrowDefs(svg: SvgParent): void {
  const defs = appendElement(svg, "defs");

  joinElements(defs, "marker", "marker", MARKERS, (marker, def) => {
    setAttrs(marker, {
      id: def.id,
      viewBox: "0 0 10 10",
      refX: 0,
      refY: 5,
      markerWidth: 7,
      markerHeight: 7,
      orient: "auto-start-reverse",
    });
    appendElement(marker, "path", {
      d: def.path,
      fill: def.fill,
      stroke: def.stroke,
      "stroke-width": def.strokeWidth,
    });
  });
}
