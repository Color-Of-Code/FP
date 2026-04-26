/**
 * Internal Block Diagram (IBD) builder.
 *
 * Converts a PartDef + DiagramMeta into an SVG inner fragment showing parts
 * as nodes connected by flows, wrapped in a «block» boundary with port squares
 * on the left (in) and right (out) edges.
 */

import {
  type PartDef, type DiagramMeta, type GNode, type GEdge, type PortUsage,
  PIN_SZ, COL, nodeDims, escXml,
} from "../types.ts";
import { layeredLayout } from "../layout.ts";
import { renderGNode } from "./nodes.ts";
import { computeEndpoints, renderGEdge } from "./edges.ts";

// ── IBD port squares ───────────────────────────────────────────────────────

/** Render the boundary-port squares for one side of the IBD block frame. */
function portSquares(
  ports: PortUsage[],
  side: "left" | "right",
  W: number,
  H: number,
): string {
  if (ports.length === 0) return "";
  const spacing = H / (ports.length + 1);
  return ports.map((p, i) => {
    const py     = spacing * (i + 1);
    const px     = side === "left" ? -PIN_SZ / 2 : W - PIN_SZ / 2;
    const label  = `${p.id} : ${p.type}`;
    const labelX = side === "left" ? px - 3 : px + PIN_SZ + 3;
    const anchor = side === "left" ? "end" : "start";
    return `<rect x="${px.toFixed(1)}" y="${(py - PIN_SZ / 2).toFixed(1)}" width="${PIN_SZ}" height="${PIN_SZ}" fill="${COL.pinFill}" stroke="${COL.pinStroke}" stroke-width="1.5"/>
  <text x="${labelX.toFixed(1)}" y="${py.toFixed(1)}" font-size="9" font-family="sans-serif" dominant-baseline="middle" text-anchor="${anchor}" fill="#444">${escXml(label)}</text>`;
  }).join("\n  ");
}

// ── IBD renderer ──────────────────────────────────────────────────────────

const MARGIN = 60;

/**
 * Build the SVG content for one IBD.
 * Returns [innerSvg, totalWidth, totalHeight].
 */
export function renderIbd(
  partDef: PartDef,
  diagram: DiagramMeta,
): [string, number, number] {
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

  const blockLabel = `<text x="${(W / 2).toFixed(1)}" y="18" text-anchor="middle" font-size="12" font-weight="bold" font-family="sans-serif" fill="${COL.labelFill}">${escXml("«block» " + partDef.name)}</text>`;
  const boundary   = `<rect x="0" y="0" width="${W}" height="${H}" rx="4" fill="#f8f8ff" stroke="#6666c0" stroke-width="2"/>`;

  const pts     = computeEndpoints(edges, nodeMap);
  const edgeEls = edges.map((e, i) => renderGEdge(e, pts[i])).join("\n");
  const nodeEls = nodes.map(n => renderGNode(n)).join("\n");

  return [
    `${boundary}\n${blockLabel}\n${portSquares(inPorts, "left", W, H)}\n${portSquares(outPorts, "right", W, H)}\n${edgeEls}\n${nodeEls}`,
    W, H,
  ];
}
