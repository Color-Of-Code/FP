/**
 * Internal Block Diagram (IBD) builder.
 *
 * Converts a PartDef + DiagramMeta into an SVG inner fragment showing parts
 * as nodes connected by flows, wrapped in a «block» boundary with port squares
 * on the left (in) and right (out) edges.  Connections may target typed part
 * ports (`part.port`) and block-boundary ports.
 */

import {
  type PartDef, type DiagramMeta, type GNode, type GEdge, type PortUsage,
  PIN_SZ, COL, nodeDims,
} from "../types.ts";
import { layoutGraph } from "../layout.ts";
import { appendDiagramFrame } from "./frame.ts";
import { assignActionPins } from "./pin.ts";
import { buildNodeMap, buildNotes, shiftCoordinates } from "./build-graph.ts";
import { appendDiagramElements } from "./diagram.ts";
import { appendElement, appendGroup, appendText, type SvgParent } from "../lib/svg.ts";
import type { RenderPlan } from "./title.ts";

// ── IBD port squares ───────────────────────────────────────────────────────

const PORT_LABEL_CHAR_W = 5.4; // 9pt sans-serif
const PORT_LABEL_GAP    = 3;

const portLabel = (p: PortUsage): string => `${p.id} : ${p.type}`;

/** Horizontal room needed outside the frame for one side's port labels. */
const labelRoom = (ports: readonly PortUsage[]): number =>
  ports.length === 0
    ? 0
    : Math.ceil(Math.max(...ports.map(p => portLabel(p).length)) * PORT_LABEL_CHAR_W)
      + PIN_SZ / 2 + PORT_LABEL_GAP + 4;

/** Append one boundary-port square straddling the block frame at (cx, cy). */
function appendPortSquare(
  parent: SvgParent,
  p: PortUsage,
  side: "left" | "right",
  cx: number,
  cy: number,
): void {
  const portGroup = appendGroup(parent, { class: `port port-${side}` }, p.tooltip);
  appendElement(portGroup, "rect", {
    x: cx - PIN_SZ / 2,
    y: cy - PIN_SZ / 2,
    width: PIN_SZ,
    height: PIN_SZ,
    fill: COL.pinFill,
    stroke: COL.pinStroke,
    "stroke-width": 1.5,
  });
  appendText(portGroup, portLabel(p), {
    x: side === "left" ? cx - PIN_SZ / 2 - PORT_LABEL_GAP : cx + PIN_SZ / 2 + PORT_LABEL_GAP,
    y: cy - PIN_SZ / 2 - 2,
    "font-size": 9,
    "font-family": "sans-serif",
    "text-anchor": side === "left" ? "end" : "start",
    fill: COL.portLabel,
  });
}

// ── Connection endpoints ──────────────────────────────────────────────────

interface Endpoint { node: string; pin?: string }

/**
 * Resolve a connection end: `part.port` targets a typed port of a part,
 * a bare boundary-port or part id targets the node itself.
 */
function resolveEndpoint(path: string, partDef: PartDef): Endpoint {
  const [head = path, pin] = path.split(".");
  if (pin === undefined) return { node: head };
  const part = partDef.parts.find(p => p.id === head);
  if (!part?.ports.some(q => q.id === pin)) {
    throw new Error(`IBD ${partDef.name}: unknown port '${path}'`);
  }
  return { node: head, pin };
}

const BOUNDARY_PREFIX = "port:";

// ── IBD renderer ──────────────────────────────────────────────────────────

/** Outer margin between the block frame and the ELK-laid graph.  The
 *  vertical margin leaves room for the frame tab; ELK internal padding
 *  handles the gap between nodes. */
const MARGIN_X = 40;
const MARGIN_Y = 18;

/**
 * Build the render plan for one IBD.
 *
 * Boundary ports (`port in|out x : T` directly in the part def) are real
 * connection endpoints: they are laid out as tiny nodes in the first / last
 * layer, then snapped onto the block frame.  Ports declared inside a part
 * usage become pins on that part, addressable as `part.port`.
 */
export async function renderIbd(
  partDef: PartDef,
  diagram: DiagramMeta,
): Promise<RenderPlan> {
  const inPorts  = partDef.ports.filter(p => p.direction === "in" || p.direction === "inout");
  const outPorts = partDef.ports.filter(p => p.direction === "out");
  const boundaryIds = new Set(partDef.ports.map(p => p.id));

  // ── Nodes ──────────────────────────────────────────────────────────────
  const partNodes: GNode[] = partDef.parts.map(p => {
    const role = diagram.shows[p.id] ?? "type";
    const hasPorts = p.ports.length > 0;
    const base: GNode = {
      id: p.id, label: `${p.id} : ${p.type}`, stereotype: undefined,
      kind: role === "function" || hasPorts ? "action" : "object",
      isHof: role === "hof",
      tooltip: diagram.tooltips[p.id],
      x: 0, y: 0, w: 0, h: 0,
      inPins:  p.ports.filter(q => q.direction !== "out").map(q => q.id),
      outPins: p.ports.filter(q => q.direction === "out").map(q => q.id),
    };
    const [w, h] = nodeDims(base);
    return { ...base, w, h };
  });
  const portNodes: GNode[] = partDef.ports.map(p => ({
    id: BOUNDARY_PREFIX + p.id, label: "", kind: "object", isHof: false,
    boundaryPort: p.direction === "out" ? "out" : "in",
    x: 0, y: 0, w: PIN_SZ, h: PIN_SZ,
    inPins: [], outPins: [],
  }));
  const { noteNodes, noteEdgesOf } = buildNotes(partDef.notes, diagram.tooltips);

  const nodes   = [...partNodes, ...portNodes, ...noteNodes];
  const nodeMap = buildNodeMap(nodes);

  // ── Edges ──────────────────────────────────────────────────────────────
  const nodeIdOf = (ep: Endpoint): string =>
    ep.pin === undefined && boundaryIds.has(ep.node) && !nodeMap.has(ep.node)
      ? BOUNDARY_PREFIX + ep.node
      : ep.node;
  const connEdges: GEdge[] = partDef.connections.map(c => {
    const src = resolveEndpoint(c.from, partDef);
    const dst = resolveEndpoint(c.to, partDef);
    const srcRole = diagram.shows[src.node] ?? "type";
    const isHof   = (c.via?.toLowerCase().includes("hof") ?? false) || srcRole === "hof";
    return {
      from: nodeIdOf(src), to: nodeIdOf(dst), label: c.label, isHof, isObjectFlow: true,
      ...(src.pin === undefined ? {} : { srcPin: src.pin }),
      ...(dst.pin === undefined ? {} : { dstPin: dst.pin }),
    };
  });
  const edges       = [...connEdges, ...noteEdgesOf(nodeMap)];
  const pinnedEdges = assignActionPins(edges, nodeMap);

  // ── Layout ─────────────────────────────────────────────────────────────
  const { width: innerW, height: innerH, nodes: positioned, edgePaths } =
    await layoutGraph(nodes, pinnedEdges, "LR");
  const { shiftedNodes, shiftedPaths } =
    shiftCoordinates(positioned, edgePaths, [], MARGIN_X, MARGIN_Y);

  const frameW = innerW + 2 * MARGIN_X;
  const frameH = innerH + 2 * MARGIN_Y;
  const leftRoom  = labelRoom(inPorts);
  const rightRoom = labelRoom(outPorts);

  // Snap boundary-port nodes onto the frame and stretch their edges to it.
  const portY = new Map(shiftedNodes.filter(n => n.boundaryPort).map(n => [n.id, n.y]));
  const snappedPaths = pinnedEdges.map((e, i) => {
    const pts = shiftedPaths[i] ?? [];
    const first = pts[0];
    const last  = pts.at(-1);
    if (portY.has(e.from) && first) {
      return [[PIN_SZ / 2, first[1]] as const, ...pts.slice(1)];
    }
    if (portY.has(e.to) && last) {
      return [...pts.slice(0, -1), [frameW - PIN_SZ / 2, last[1]] as const];
    }
    return pts;
  });
  const edgeYOf = (id: string, end: "first" | "last"): number | undefined => {
    const i = pinnedEdges.findIndex(e => (end === "first" ? e.from : e.to) === id);
    const pts = snappedPaths[i];
    return (end === "first" ? pts?.[0] : pts?.at(-1))?.[1];
  };
  const portCenter = (p: PortUsage, idx: number, all: readonly PortUsage[]): number => {
    const id = BOUNDARY_PREFIX + p.id;
    return edgeYOf(id, p.direction === "out" ? "last" : "first")
      ?? portY.get(id)
      ?? frameH * (idx + 1) / (all.length + 1);
  };

  return {
    width: leftRoom + frameW + rightRoom,
    height: frameH,
    draw(parent) {
      const block = leftRoom > 0
        ? appendGroup(parent, { transform: `translate(${leftRoom},0)` })
        : parent;
      appendDiagramFrame(block, "block", partDef.name, frameW, frameH);
      appendDiagramElements(
        block,
        shiftedNodes.filter(n => !n.boundaryPort),
        pinnedEdges,
        snappedPaths,
        [],
      );
      inPorts.forEach((p, i) => {
        appendPortSquare(block, p, "left", 0, portCenter(p, i, inPorts));
      });
      outPorts.forEach((p, i) => {
        appendPortSquare(block, p, "right", frameW, portCenter(p, i, outPorts));
      });
    },
  };
}
