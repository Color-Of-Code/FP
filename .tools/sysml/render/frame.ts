/**
 * Activity frame: outer rounded border + pentagon name tab (SysML v2 notation).
 *
 * The tab is a rectangle with the bottom-right corner cut at 45° — the
 * standard SysML activity-frame label shape per ISO 19514.
 */

import { FRAME_TAB_W, FRAME_TAB_H, COL, escXml } from "../types.ts";

/**
 * Render the activity frame border and name tab for an activity of size (W × H).
 * `name` is shown inside the pentagon tab as `«activity» <name>`.
 */
export function renderActivityFrame(name: string, W: number, H: number): string {
  // Measure label width (font-size 10 sans-serif ≈ 6.2 px/char), cap at FRAME_TAB_W
  const label = `«activity» ${name}`;
  const tw    = Math.min(FRAME_TAB_W, label.length * 6.2 + 16);
  const th    = FRAME_TAB_H;
  // Rectangle with bottom-right corner cut: 5 points
  const tabPath = `M0,0 L${tw},0 L${tw},${th - 10} L${tw - 10},${th} L0,${th} Z`;

  return `  <rect x="0" y="0" width="${W}" height="${H}" rx="8" fill="${COL.frameFill}" stroke="${COL.frameStroke}" stroke-width="1.5"/>
  <g class="activity-frame-tab">
    <path d="${tabPath}" fill="#e0e0e0" stroke="${COL.frameStroke}" stroke-width="1"/>
    <text x="${(tw / 2).toFixed(1)}" y="${(th / 2 + 1).toFixed(1)}" text-anchor="middle" font-size="10" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(label)}</text>
  </g>`;
}
