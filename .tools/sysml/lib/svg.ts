/**
 * Generic SVG DOM helpers backed by jsdom + d3.
 *
 * These utilities keep renderer files focused on diagram semantics rather than
 * repetitive DOM append boilerplate.  Final pretty-printed serialization is
 * delegated to xmlbuilder2 so the formatting rules are well-tested rather
 * than hand-rolled.
 */

import { JSDOM } from "jsdom";
import { select, type BaseType, type Selection } from "d3";
import { create } from "xmlbuilder2";

export type SvgParent = Selection<any, unknown, any, any>;
export type SvgAttrValue = string | number | boolean | null | undefined;
export type SvgAttrs = Record<string, SvgAttrValue>;

export interface SvgRoot {
  svg: SvgParent;
  serialize(): string;
}

function serializeSvg(svg: SVGSVGElement): string {
  // Round-trip through xmlbuilder2 to get a stable, pretty-printed
  // serialization.  jsdom's XMLSerializer emits a minified single-line
  // string; xmlbuilder2 then re-formats it with consistent indentation.
  const raw = new (svg.ownerDocument!.defaultView as any).XMLSerializer()
    .serializeToString(svg);
  return create(raw).end({ prettyPrint: true, headless: true, indent: "  " });
}

/** Create a standalone SVG root document and serializer. */
export function createSvgRoot(width: number, height: number): SvgRoot {
  const dom = new JSDOM("<!DOCTYPE html><html><body></body></html>");
  const svg = select(dom.window.document.body)
    .append("svg")
    .attr("xmlns", "http://www.w3.org/2000/svg")
    .attr("viewBox", `0 0 ${width} ${height}`)
    .attr("width", width)
    .attr("height", height) as SvgParent;

  return {
    svg,
    serialize: () =>
      `<?xml version="1.0" encoding="UTF-8"?>\n${serializeSvg(svg.node() as SVGSVGElement)}\n`,
  };
}

/** Apply a stringifiable attribute map to a selection. */
export function setAttrs<T extends BaseType, D, P extends BaseType, PD>(
  selection: Selection<T, D, P, PD>,
  attrs: SvgAttrs,
): Selection<T, D, P, PD> {
  for (const [name, value] of Object.entries(attrs)) {
    if (value === undefined || value === null) continue;
    selection.attr(name, String(value));
  }
  return selection;
}

/** Append an SVG element and apply attributes to it. */
export function appendElement(
  parent: SvgParent,
  tagName: string,
  attrs: SvgAttrs = {},
): SvgParent {
  const child = parent.append(tagName) as SvgParent;
  return setAttrs(child, attrs);
}

/** Append a text-bearing SVG element. */
export function appendText(
  parent: SvgParent,
  text: string,
  attrs: SvgAttrs = {},
  tagName = "text",
): SvgParent {
  const child = appendElement(parent, tagName, attrs);
  child.text(text);
  return child;
}

/** Append a tooltip title when one is provided. */
export function appendTooltip(parent: SvgParent, tooltip?: string): void {
  if (tooltip) appendText(parent, tooltip, {}, "title");
}

/** Append a group and optional tooltip. */
export function appendGroup(
  parent: SvgParent,
  attrs: SvgAttrs = {},
  tooltip?: string,
): SvgParent {
  const group = appendElement(parent, "g", attrs);
  appendTooltip(group, tooltip);
  return group;
}

/**
 * Render repeated SVG children via a D3 data join.
 *
 * The current renderer always builds a fresh document, but clearing child
 * content here keeps the helper safe if a selection is ever reused.
 */
export function joinElements<T>(
  parent: SvgParent,
  selector: string,
  tagName: string,
  data: readonly T[],
  render: (child: SvgParent, datum: T, index: number) => void,
): void {
  const joined = parent.selectAll<BaseType, T>(selector)
    .data(data)
    .join(tagName);

  joined.each(function eachJoined(this: BaseType, datum: T, index: number) {
    const child = select(this as BaseType) as SvgParent;
    child.selectAll("*").remove();
    child.text(null);
    render(child, datum, index);
  });
}

/** Append repeated groups via a D3 data join. */
export function joinGroups<T>(
  parent: SvgParent,
  selector: string,
  data: readonly T[],
  render: (child: SvgParent, datum: T, index: number) => void,
): void {
  joinElements(parent, selector, "g", data, render);
}