/**
 * SysML diagram frame: outer rounded border + pentagon name tab.
 *
 * The tab is a rectangle with the bottom-right corner cut at 45° — the
 * standard SysML v2 frame label shape per ISO 19514.  Used identically
 * for activity frames, block (IBD) frames, and any future diagram kind;
 * the only thing that changes is the stereotype keyword inside the tab.
 */

import { FRAME_TAB_W, FRAME_TAB_H, COL } from "../types.ts";
import { appendElement, appendGroup, appendText, type SvgParent } from "../lib/svg.ts";

/**
 * Append a diagram frame border and stereotyped name tab for content of size
 * (W × H).  The tab text is `«stereotype» <name>` (e.g. `«activity» bind` or
 * `«block» Reader`).
 */
export function appendDiagramFrame(
  parent: SvgParent,
  stereotype: string,
  name: string,
  W: number,
  H: number,
): void {
  // Measure label width (font-size 10 sans-serif ≈ 6.2 px/char), cap at FRAME_TAB_W
  const label = `«${stereotype}» ${name}`;
  const tw    = Math.min(FRAME_TAB_W, label.length * 6.2 + 16);
  const th    = FRAME_TAB_H;
  // Rectangle with bottom-right corner cut: 5 points
  const tabPath = `M0,0 L${tw},0 L${tw},${th - 10} L${tw - 10},${th} L0,${th} Z`;

  appendElement(parent, "rect", {
    x: 0,
    y: 0,
    width: W,
    height: H,
    fill: COL.frameFill,
    stroke: COL.frameStroke,
    "stroke-width": 1.5,
  });

  const tab = appendGroup(parent, { class: `diagram-frame-tab tab-${stereotype}` });
  appendElement(tab, "path", {
    d: tabPath,
    fill: "#e0e0e0",
    stroke: COL.frameStroke,
    "stroke-width": 1,
  });
  appendText(tab, label, {
    x: tw / 2,
    y: th / 2 + 1,
    "text-anchor": "middle",
    "font-size": 10,
    "font-family": "sans-serif",
    "dominant-baseline": "middle",
    fill: COL.labelFill,
  });
}

/** Back-compat alias: activity is just a frame with the "activity" stereotype. */
export function appendActivityFrame(parent: SvgParent, name: string, W: number, H: number): void {
  appendDiagramFrame(parent, "activity", name, W, H);
}
