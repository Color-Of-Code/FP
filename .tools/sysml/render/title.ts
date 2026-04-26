/**
 * SVG document shell: white background, centred title bar, and translated
 * content group.  All diagram renderers produce an inner SVG fragment;
 * makeSvg wraps it in a complete, standalone SVG document.
 */

import { escXml } from "../types.ts";
import { SVG_DEFS } from "./arrows.ts";

const TITLE_H = 28;

/**
 * Wrap `inner` SVG markup in a complete SVG document with a centred bold
 * title and the shared arrowhead marker definitions.
 */
export function makeSvg(inner: string, title: string, W: number, H: number): string {
  const totalH  = H + TITLE_H;
  const titleEl = `<text x="${(W / 2).toFixed(1)}" y="20" text-anchor="middle" font-size="14" font-weight="bold" font-family="sans-serif" fill="#222">${escXml(title)}</text>`;
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${totalH}" width="${W}" height="${totalH}">
${SVG_DEFS}
<rect width="${W}" height="${totalH}" fill="white"/>
${titleEl}
<g transform="translate(0,${TITLE_H})">
${inner}
</g>
</svg>`;
}
