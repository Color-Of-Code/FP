/**
 * Internal Block Diagram (IBD) builder.
 *
 * Converts a PartDef + DiagramMeta into an SVG inner fragment showing parts
 * as nodes connected by flows, wrapped in a «block» boundary with port squares
 * on the left (in) and right (out) edges.
 */

import {
  type PartDef, type DiagramMeta, type GNode, type GEdge, type PortUsage,
  PIN_SZ, COL, nodeDims,
} from "../types.ts";
import { layeredLayout } from "../layout.ts";
import { appendGNode } from "./nodes.ts";
import { computeEndpoints, appendGEdge } from "./edges.ts";
import type { RenderPlan, SvgParent } from "./title.ts";

// ── IBD port squares ───────────────────────────────────────────────────────

/** Append the boundary-port squares for one side of the IBD block frame. */
function appendPortSquares(
  parent: SvgParent,
  ports: PortUsage[],
  side: "left" | "right",
  W: number,
  H: number,
): void {
  if (ports.length === 0) return;
  const spacing = H / (ports.length + 1);
  for (const [i, p] of ports.entries()) {
    const py     = spacing * (i + 1);
    const px     = side === "left" ? -PIN_SZ / 2 : W - PIN_SZ / 2;
    const label  = `${p.id} : ${p.type}`;
    const labelX = side === "left" ? px - 3 : px + PIN_SZ + 3;
    const anchor = side === "left" ? "end" : "start";
    parent.append("rect")
      .attr("x", px)
      .attr("y", py - PIN_SZ / 2)
      .attr("width", PIN_SZ)
      .attr("height", PIN_SZ)
      .attr("fill", COL.pinFill)
      .attr("stroke", COL.pinStroke)
      .attr("stroke-width", 1.5);
    parent.append("text")
      .attr("x", labelX)
      .attr("y", py)
      .attr("font-size", 9)
      .attr("font-family", "sans-serif")
      .attr("dominant-baseline", "middle")
      .attr("text-anchor", anchor)
      .attr("fill", "#444")
      .text(label);
  }
}

// ── IBD renderer ──────────────────────────────────────────────────────────

const MARGIN = 60;

/**
 * Build the render plan for one IBD.
 */
export function renderIbd(
  partDef: PartDef,
  diagram: DiagramMeta,
): RenderPlan {
  const nodes: GNode[]           = [];
  const nodeMap = new Map<string, GNode>();

  for (const p of partDef.parts) {
    const role  = diagram.shows[p.id] ?? "type";
    const n: GNode = {
      id: p.id, label: `${p.id} : ${p.type}`, stereotype: undefined,
      kind: role === "function" ? "action" : "object",
      isHof: role === "hof",
      tooltip: diagram.tooltips[p.id],
      x: 0, y: 0, w: 0, h: 0,
      inPins: [], outPins: [],
    };
    [n.w, n.h] = nodeDims(n);
    nodes.push(n); nodeMap.set(p.id, n);
  }

  const edges: GEdge[] = [];
  for (const c of partDef.connections) {
    const srcRole = diagram.shows[c.from] ?? "type";
    const isHof   = (c.via?.toLowerCase().includes("hof") ?? false) || srcRole === "hof";
    edges.push({ from: c.from, to: c.to, label: c.label, isHof, isObjectFlow: true });
  }

  const [innerW, innerH] = layeredLayout(nodes, edges, "LR");
  for (const n of nodes) { n.x += MARGIN; n.y += MARGIN; }

  const W = innerW + 2 * MARGIN;
  const H = innerH + 2 * MARGIN;

  const inPorts  = partDef.ports.filter(p => p.direction === "in"  || p.direction === "inout");
  const outPorts = partDef.ports.filter(p => p.direction === "out");

  const pts = computeEndpoints(edges, nodeMap);

  return {
    width: W,
    height: H,
    draw(parent) {
      parent.append("rect")
        .attr("x", 0)
        .attr("y", 0)
        .attr("width", W)
        .attr("height", H)
        .attr("rx", 4)
        .attr("fill", "#f8f8ff")
        .attr("stroke", "#6666c0")
        .attr("stroke-width", 2);

      parent.append("text")
        .attr("x", W / 2)
        .attr("y", 18)
        .attr("text-anchor", "middle")
        .attr("font-size", 12)
        .attr("font-weight", "bold")
        .attr("font-family", "sans-serif")
        .attr("fill", COL.labelFill)
        .text(`«block» ${partDef.name}`);

      appendPortSquares(parent, inPorts, "left", W, H);
      appendPortSquares(parent, outPorts, "right", W, H);
      edges.forEach((e, i) => appendGEdge(parent, e, pts[i]));
      nodes.forEach(n => appendGNode(parent, n));
    },
  };
}
