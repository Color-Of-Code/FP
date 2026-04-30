/**
 * SVG document helpers backed by jsdom + d3.
 *
 * Renderers append into a real SVG DOM tree instead of concatenating XML
 * strings.  This keeps the layout code unchanged while moving drawing to a
 * higher-level, server-side DOM abstraction.
 */

import { appendElement, appendText, createSvgRoot, type SvgParent } from "../lib/svg.ts";
import { appendArrowDefs } from "./arrows.ts";

// Title typography
const TITLE_PRIMARY_PT   = 14;
const TITLE_SECONDARY_PT = 11;
const TITLE_LINE_GAP     = 2;        // vertical gap between wrapped lines
const TITLE_PAD_TOP      = 4;        // px from canvas top to first baseline-relevant line top
const TITLE_PAD_BOTTOM   = 6;        // px between last title line and diagram content
const TITLE_SIDE_PAD     = 24;       // horizontal padding around title

// Approximate average character widths (jsdom does not measure SVG text).
// Tuned empirically for the bold/regular sans-serif sizes we use.
const CHAR_W_PRIMARY   = 7.4;
const CHAR_W_SECONDARY = 5.9;

export interface RenderPlan {
  width: number;
  height: number;
  draw(parent: SvgParent): void;
}

export interface SvgDocument {
  svg: SvgParent;
  content: SvgParent;
  serialize(): string;
}

interface TitleLine {
  text:     string;
  primary:  boolean;
}

/**
 * Split a title at " — " boundaries.  The first segment becomes the primary
 * line (bold); every following segment becomes a secondary line (lighter,
 * smaller).  Empty input yields a single empty primary line so the layout
 * stays stable.
 */
function splitTitle(title: string): TitleLine[] {
  if (!title) return [{ text: "", primary: true }];
  // Split on em-dash (with surrounding spaces) — the convention used in this
  // repo to separate signature/description from per-language alias suffixes.
  const parts = title.split(/\s+—\s+/);
  return parts.map((text, i) => ({ text, primary: i === 0 }));
}

function lineWidth(line: TitleLine): number {
  const charW = line.primary ? CHAR_W_PRIMARY : CHAR_W_SECONDARY;
  return Math.ceil(line.text.length * charW) + TITLE_SIDE_PAD * 2;
}

function lineHeight(line: TitleLine): number {
  // Approximate visual height of a single line of text including descenders.
  return Math.round((line.primary ? TITLE_PRIMARY_PT : TITLE_SECONDARY_PT) * 1.25);
}

function totalTitleHeight(lines: TitleLine[]): number {
  let h = TITLE_PAD_TOP;
  for (let i = 0; i < lines.length; i++) {
    h += lineHeight(lines[i]);
    if (i < lines.length - 1) h += TITLE_LINE_GAP;
  }
  return h + TITLE_PAD_BOTTOM;
}

/** Create a standalone SVG document shell and translated diagram content group. */
export function createSvgDocument(title: string, W: number, H: number): SvgDocument {
  const lines     = splitTitle(title);
  const titleH    = totalTitleHeight(lines);
  const titleNeed = Math.max(0, ...lines.map(lineWidth));
  const canvasW   = Math.max(W, titleNeed);
  const contentScale = W > 0 ? canvasW / W : 1;
  const totalH    = Math.ceil(H * contentScale) + titleH;

  const root = createSvgRoot(canvasW, totalH);
  const svg  = root.svg;

  appendArrowDefs(svg);

  appendElement(svg, "rect", { width: canvasW, height: totalH, fill: "white" });

  // Render each title line in its own <text> element, vertically stacked.
  let y = TITLE_PAD_TOP;
  for (const line of lines) {
    const lh = lineHeight(line);
    // Place the baseline near the bottom of the line box.
    const baselineY = y + Math.round(lh * 0.78);
    appendText(svg, line.text, {
      x: canvasW / 2,
      y: baselineY,
      "text-anchor": "middle",
      "font-size":   line.primary ? TITLE_PRIMARY_PT : TITLE_SECONDARY_PT,
      "font-weight": line.primary ? "bold" : "normal",
      "font-family": "sans-serif",
      fill:          line.primary ? "#222" : "#555",
    });
    y += lh + TITLE_LINE_GAP;
  }

  const content   = appendElement(svg, "g", {
    transform: `translate(0,${titleH}) scale(${contentScale})`,
  });

  return {
    svg,
    content,
    serialize: root.serialize,
  };
}

/** Append a simple status message inside the diagram content area. */
export function appendStatusMessage(parent: SvgParent, message: string): void {
  appendText(parent, message, { x: 20, y: 40, fill: "red" });
}
