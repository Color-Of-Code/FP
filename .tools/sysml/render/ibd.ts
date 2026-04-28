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
import { layoutGraph } from "../layout.ts";
import { appendGNode } from "./nodes.ts";
import { appendGEdge } from "./edges.ts";
import { appendDiagramFrame } from "./frame.ts";
import { assignActionPins } from "./pin.ts";
import { appendElement, appendText, joinGroups, setAttrs, type SvgParent } from "../lib/svg.ts";
import type { RenderPlan } from "./title.ts";

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
  joinGroups(parent, `g.port-${side}`, ports, (portGroup, p, i) => {
    const py     = spacing * (i + 1);
    const px     = side === "left" ? -PIN_SZ / 2 : W - PIN_SZ / 2;
    const label  = `${p.id} : ${p.type}`;
    const labelX = side === "left" ? px - 3 : px + PIN_SZ + 3;
    const anchor = side === "left" ? "end" : "start";
    setAttrs(portGroup, { class: `port port-${side}` });
    appendElement(portGroup, "rect", {
      x: px,
      y: py - PIN_SZ / 2,
      width: PIN_SZ,
      height: PIN_SZ,
      fill: COL.pinFill,
      stroke: COL.pinStroke,
      "stroke-width": 1.5,
    });
    appendText(portGroup, label, {
      x: labelX,
      y: py,
      "font-size": 9,
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      "text-anchor": anchor,
      fill: "#444",
    });
  });
}

// ── IBD renderer ──────────────────────────────────────────────────────────

/** Outer SVG margin around the ELK-laid graph. The horizontal margin is
 *  generous so block-boundary port labels (drawn outside the frame edge)
 *  are not clipped; the vertical margin is just enough for the frame tab
 *  and a little breathing room. ELK internal padding handles the gap
 *  between nodes and the frame border. */
const MARGIN_X = 40;
const MARGIN_Y = 18;

/**
 * Build the render plan for one IBD.
 */
export async function renderIbd(
  partDef: PartDef,
  diagram: DiagramMeta,
): Promise<RenderPlan> {
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
  assignActionPins(edges, nodeMap);

  const { width: innerW, height: innerH, edgePaths } = await layoutGraph(nodes, edges, "LR");
  const dx = MARGIN_X;
  const dy = MARGIN_Y;
  for (const n of nodes) { n.x += dx; n.y += dy; }
  const shiftedPaths = edgePaths.map(pts =>
    pts.map(([x, y]) => [x + dx, y + dy] as [number, number]),
  );

  const W = innerW + 2 * MARGIN_X;
  const H = innerH + 2 * MARGIN_Y;

  const inPorts  = partDef.ports.filter(p => p.direction === "in"  || p.direction === "inout");
  const outPorts = partDef.ports.filter(p => p.direction === "out");

  return {
    width: W,
    height: H,
    draw(parent) {
      appendDiagramFrame(parent, "block", partDef.name, W, H);

      appendPortSquares(parent, inPorts, "left", W, H);
      appendPortSquares(parent, outPorts, "right", W, H);
      edges.forEach((e, i) => appendGEdge(parent, e, shiftedPaths[i]));
      nodes.forEach(n => appendGNode(parent, n));
    },
  };
}
