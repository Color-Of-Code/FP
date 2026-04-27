/**
 * Activity frame: outer rounded border + pentagon name tab (SysML v2 notation).
 *
 * The tab is a rectangle with the bottom-right corner cut at 45° — the
 * standard SysML activity-frame label shape per ISO 19514.
 */

import { FRAME_TAB_W, FRAME_TAB_H, COL } from "../types.ts";
import type { SvgParent } from "./title.ts";

/**
 * Append the activity frame border and name tab for an activity of size (W × H).
 * `name` is shown inside the pentagon tab as `«activity» <name>`.
 */
export function appendActivityFrame(parent: SvgParent, name: string, W: number, H: number): void {
  // Measure label width (font-size 10 sans-serif ≈ 6.2 px/char), cap at FRAME_TAB_W
  const label = `«activity» ${name}`;
  const tw    = Math.min(FRAME_TAB_W, label.length * 6.2 + 16);
  const th    = FRAME_TAB_H;
  // Rectangle with bottom-right corner cut: 5 points
  const tabPath = `M0,0 L${tw},0 L${tw},${th - 10} L${tw - 10},${th} L0,${th} Z`;

  parent.append("rect")
    .attr("x", 0)
    .attr("y", 0)
    .attr("width", W)
    .attr("height", H)
    .attr("rx", 8)
    .attr("fill", COL.frameFill)
    .attr("stroke", COL.frameStroke)
    .attr("stroke-width", 1.5);

  const tab = parent.append("g")
    .attr("class", "activity-frame-tab");
  tab.append("path")
    .attr("d", tabPath)
    .attr("fill", "#e0e0e0")
    .attr("stroke", COL.frameStroke)
    .attr("stroke-width", 1);
  tab.append("text")
    .attr("x", tw / 2)
    .attr("y", th / 2 + 1)
    .attr("text-anchor", "middle")
    .attr("font-size", 10)
    .attr("font-family", "sans-serif")
    .attr("dominant-baseline", "middle")
    .attr("fill", COL.labelFill)
    .text(label);
}
