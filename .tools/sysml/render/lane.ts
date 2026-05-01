/**
 * Lane band: a labelled rectangle drawn behind a group of nodes to convey
 * a swimlane-style grouping (e.g. a "monad" lane containing the elevated
 * values and combinators, with raw values and user-supplied functions in
 * the surrounding lane).
 *
 * The band is purely decorative — layout has already placed nodes; this
 * draws the rectangle and its label without participating in flow.
 */

import { COL } from "../types.ts";
import { appendElement, appendGroup, appendText, type SvgParent } from "../lib/svg.ts";
import type { LaneGeom } from "../layout.ts";

const LANE_LABEL_H = 18;
const LANE_FILL    = "#f7f9fc";
const LANE_STROKE  = "#bbbbbb";
const LANE_HEADER  = "#e9eef5";

/** Draw a single lane band behind the nodes that belong to it. */
export function appendLaneBand(parent: SvgParent, lane: LaneGeom): void {
  if (lane.w <= 0 || lane.h <= 0) return;
  const g = appendGroup(parent, { class: `swimlane lane-${lane.id}` });
  // Background body
  appendElement(g, "rect", {
    x: lane.x,
    y: lane.y,
    width: lane.w,
    height: lane.h,
    fill: LANE_FILL,
    stroke: LANE_STROKE,
    "stroke-width": 1,
    rx: 4,
    ry: 4,
  });
  if (lane.label) {
    // Header strip flush with the top edge of the lane.
    appendElement(g, "rect", {
      x: lane.x,
      y: lane.y,
      width: lane.w,
      height: LANE_LABEL_H,
      fill: LANE_HEADER,
      stroke: LANE_STROKE,
      "stroke-width": 1,
      rx: 4,
      ry: 4,
    });
    appendText(g, lane.label, {
      x: lane.x + 10,
      y: lane.y + LANE_LABEL_H / 2 + 1,
      "text-anchor": "start",
      "font-size": 10,
      "font-weight": "bold",
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: COL.labelFill,
    });
  }
}
