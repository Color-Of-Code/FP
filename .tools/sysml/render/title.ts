/**
 * SVG document helpers backed by jsdom + d3.
 *
 * Renderers append into a real SVG DOM tree instead of concatenating XML
 * strings.  This keeps the layout code unchanged while moving drawing to a
 * higher-level, server-side DOM abstraction.
 */

import { appendElement, appendText, createSvgRoot, type SvgParent } from "../lib/svg.ts";
import { appendArrowDefs } from "./arrows.ts";

const TITLE_H = 28;

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

/** Create a standalone SVG document shell and translated diagram content group. */
export function createSvgDocument(title: string, W: number, H: number): SvgDocument {
  const totalH = H + TITLE_H;
  const root = createSvgRoot(W, totalH);
  const svg = root.svg;

  appendArrowDefs(svg);

  appendElement(svg, "rect", { width: W, height: totalH, fill: "white" });

  appendText(svg, title, {
    x: W / 2,
    y: 20,
    "text-anchor": "middle",
    "font-size": 14,
    "font-weight": "bold",
    "font-family": "sans-serif",
    fill: "#222",
  });

  const content = appendElement(svg, "g", {
    transform: `translate(0,${TITLE_H})`,
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
