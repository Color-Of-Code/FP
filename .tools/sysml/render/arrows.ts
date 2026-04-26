/**
 * SVG arrowhead marker definitions.
 *
 * All markers use refX="0" — the back-center of the triangle is placed at
 * the path endpoint.  Path endpoints are pre-pulled back by ARROW_DEPTH so
 * the visual tip lands exactly on the target boundary (see types/constants.ts).
 */

import { COL } from "../types.ts";

export const SVG_DEFS = `<defs>
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
