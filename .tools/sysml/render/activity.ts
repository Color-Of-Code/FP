/**
 * Activity diagram builder.
 *
 * Converts an ActivityDef + DiagramMeta + ActionDef map into an SVG inner
 * fragment (without the outer SVG shell).  Layout and routing are delegated
 * to ELK (`layoutGraph`); pin attachment is encoded as `GEdge.srcPin`
 * / `GEdge.dstPin` so ELK routes directly to the correct port.
 */

import {
  type ActivityDef, type ActionDef, type DiagramMeta, type GNode, type GEdge,
  ACTION_W, ACTION_H, DECISION_SZ,
  FRAME_PAD, FRAME_TAB_H,
  nodeDims,
} from "../types.ts";
import { layoutGraph, type LaneSpec } from "../layout.ts";
import { appendGNode } from "./nodes.ts";
import { appendGEdge } from "./edges.ts";
import { appendDiagramFrame } from "./frame.ts";
import { appendLaneBand } from "./lane.ts";
import { assignActionPins } from "./pin.ts";
import { shiftCoordinates, buildNoteNode } from "./build-graph.ts";
import type { RenderPlan } from "./title.ts";

/**
 * Build the render plan for one activity diagram.
 */
export async function renderActivity(
  actDef: ActivityDef,
  diagram: DiagramMeta,
  actionDefs: Map<string, ActionDef>,
): Promise<RenderPlan> {
  const hideInPinLabels = (actDef.lanes?.length ?? 0) > 0;

  // ── Helper: register a node and derive its map entry ───────────────────
  const addToMap = (acc: Map<string, GNode>, n: GNode): Map<string, GNode> =>
    new Map([...acc, [n.id, n]]);

  // ── Action nodes ───────────────────────────────────────────────────────
  const actionNodes: GNode[] = actDef.actions.map(a => {
    const ad     = actionDefs.get(a.type);
    const inPins  = ad ? ad.pins.filter(p => p.direction === "in").map(p => p.id)  : [];
    const outPins = ad ? ad.pins.filter(p => p.direction === "out").map(p => p.id) : [];
    return {
      id: a.id, label: a.id, stereotype: a.type,
      kind: "action" as const, isHof: false,
      hideInPinLabels,
      tooltip: diagram.tooltips[a.id],
      x: 0, y: 0, w: ACTION_W, h: ACTION_H,
      inPins, outPins,
    };
  });

  // ── Object nodes ───────────────────────────────────────────────────────
  const objectNodes: GNode[] = actDef.objects.map(o => {
    const role  = diagram.shows[o.id] ?? "type";
    const base: GNode = {
      id: o.id, label: o.type ?? o.id,
      kind: "object", isHof: role === "hof",
      tooltip: diagram.tooltips[o.id],
      x: 0, y: 0, w: 0, h: 0,
      inPins: [], outPins: [],
    };
    const [w, h] = nodeDims(base);
    return { ...base, w, h };
  });

  // ── Decision / Merge nodes ─────────────────────────────────────────────
  const decisionNodes: GNode[] = actDef.decisions.map(d => ({
    id: d.id, label: d.label ?? "",
    kind: "decision" as const, isHof: false,
    tooltip: diagram.tooltips[d.id],
    x: 0, y: 0, w: DECISION_SZ, h: DECISION_SZ,
    inPins: [], outPins: [],
  }));
  const mergeNodes: GNode[] = actDef.merges.map(m => ({
    id: m.id, label: m.label ?? "",
    kind: "merge" as const, isHof: false,
    tooltip: diagram.tooltips[m.id],
    x: 0, y: 0, w: DECISION_SZ, h: DECISION_SZ,
    inPins: [], outPins: [],
  }));

  // ── Note nodes ─────────────────────────────────────────────────────────
  const noteNodes: GNode[] = actDef.notes.map(note => buildNoteNode(note, diagram.tooltips).node);

  // ── Combine ────────────────────────────────────────────────────────────
  const nodes: GNode[] = [...actionNodes, ...objectNodes, ...decisionNodes, ...mergeNodes, ...noteNodes];
  const nodeMap = nodes.reduce(addToMap, new Map<string, GNode>());

  // ── Edges ──────────────────────────────────────────────────────────────
  const flowEdges: GEdge[] = actDef.flows
    .filter(f => nodeMap.has(f.from) && nodeMap.has(f.to))
    .map(f => ({
      from: f.from, to: f.to, label: f.label,
      isHof: nodeMap.get(f.from)!.isHof, isObjectFlow: true,
    }));
  const succEdges: GEdge[] = actDef.successions
    .filter(s => nodeMap.has(s.from) && nodeMap.has(s.to))
    .map(s => ({
      from: s.from, to: s.to, label: undefined, isHof: false, isObjectFlow: false,
    }));
  const noteEdges: GEdge[] = actDef.notes
    .map(note => ({ note, edge: buildNoteNode(note, diagram.tooltips).edge }))
    .filter(({ note, edge }) => edge != null && nodeMap.has(note.id) && nodeMap.has(note.target))
    .map(({ edge }) => edge!);
  const edges: GEdge[] = [...flowEdges, ...succEdges, ...noteEdges];

  // Match each object-flow edge to a named pin on action endpoints.
  const pinnedEdges = assignActionPins(edges, nodeMap);

  // ── Lanes (swimlane decoration) ─────────────────────────────────────────
  const laneSpecs: LaneSpec[] = (actDef.lanes ?? []).map(l => ({
    id:      l.id,
    label:   l.label,
    members: l.members,
  }));

  // ── Layout + routing via ELK ───────────────────────────────────────────
  const { width: innerW, height: innerH, nodes: positioned, edgePaths, lanes: laneGeoms } = await layoutGraph(
    nodes, pinnedEdges, diagram.direction ?? "LR", laneSpecs,
  );

  const dx = FRAME_PAD;
  const dy = FRAME_PAD + FRAME_TAB_H;
  const { shiftedNodes, shiftedPaths, shiftedLanes } = shiftCoordinates(positioned, edgePaths, laneGeoms, dx, dy);

  const W = innerW + 2 * FRAME_PAD;
  const H = innerH + 2 * FRAME_PAD + FRAME_TAB_H;

  return {
    width: W,
    height: H,
    draw(parent) {
      appendDiagramFrame(parent, "activity", diagram.name ?? actDef.name, W, H);
      shiftedLanes.forEach(l => appendLaneBand(parent, l));
      pinnedEdges.forEach((e, i) => {
        appendGEdge(parent, e, shiftedPaths[i]);
      });
      shiftedNodes.forEach(n => appendGNode(parent, n));
    },
  };
}
