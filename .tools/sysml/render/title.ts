/**
 * SVG document helpers backed by jsdom + d3.
 *
 * Renderers append into a real SVG DOM tree instead of concatenating XML
 * strings.  This keeps the layout code unchanged while moving drawing to a
 * higher-level, server-side DOM abstraction.
 */

import { select, type BaseType, type Selection } from "d3";
import { JSDOM } from "jsdom";
import { appendArrowDefs } from "./arrows.ts";

const TITLE_H = 28;
const XML_HEADER = '<?xml version="1.0" encoding="UTF-8"?>';

export type SvgParent = Selection<BaseType, unknown, null, undefined>;

export interface RenderPlan {
  width: number;
  height: number;
  draw(parent: SvgParent): void;
}

export interface SvgDocument {
  svg: Selection<SVGSVGElement, unknown, null, undefined>;
  content: Selection<SVGGElement, unknown, null, undefined>;
  serialize(): string;
}

/** Create a standalone SVG document shell and translated diagram content group. */
export function createSvgDocument(title: string, W: number, H: number): SvgDocument {
  const totalH = H + TITLE_H;
  const dom = new JSDOM("<!DOCTYPE html><html><body></body></html>");
  const svg = select(dom.window.document.body)
    .append("svg")
    .attr("xmlns", "http://www.w3.org/2000/svg")
    .attr("viewBox", `0 0 ${W} ${totalH}`)
    .attr("width", W)
    .attr("height", totalH);

  appendArrowDefs(svg as SvgParent);

  svg.append("rect")
    .attr("width", W)
    .attr("height", totalH)
    .attr("fill", "white");

  svg.append("text")
    .attr("x", W / 2)
    .attr("y", 20)
    .attr("text-anchor", "middle")
    .attr("font-size", 14)
    .attr("font-weight", "bold")
    .attr("font-family", "sans-serif")
    .attr("fill", "#222")
    .text(title);

  const content = svg.append("g")
    .attr("transform", `translate(0,${TITLE_H})`);

  return {
    svg,
    content,
    serialize: () => `${XML_HEADER}\n${svg.node()!.outerHTML}`,
  };
}

/** Append a simple status message inside the diagram content area. */
export function appendStatusMessage(parent: SvgParent, message: string): void {
  parent.append("text")
    .attr("x", 20)
    .attr("y", 40)
    .attr("fill", "red")
    .text(message);
}
