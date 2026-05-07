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
import { buildNodeMap, buildNotes, filterEdges, shiftCoordinates } from "./build-graph.ts";
import { pipe, A } from "../lib/fp.ts";
import type { RenderPlan } from "./title.ts";

// ── Node builders (one per AST kind) ──────────────────────────────────────

const buildActionNode = (
  actionDefs: Map<string, ActionDef>,
  diagram: DiagramMeta,
  hideInPinLabels: boolean,
) => (a: ActivityDef["actions"][number]): GNode => {
  const ad      = actionDefs.get(a.type);
  const pinIds  = (dir: "in" | "out") =>
    ad ? ad.pins.filter(p => p.direction === dir).map(p => p.id) : [];
  return {
    id: a.id, label: a.id, stereotype: a.type,
    kind: "action", isHof: false,
    hideInPinLabels,
    tooltip: diagram.tooltips[a.id],
    x: 0, y: 0, w: ACTION_W, h: ACTION_H,
    inPins: pinIds("in"), outPins: pinIds("out"),
  };
};

const buildObjectNode = (diagram: DiagramMeta) =>
  (o: ActivityDef["objects"][number]): GNode => {
    const role: GNode = {
      id: o.id, label: o.type ?? o.id,
      kind: "object", isHof: (diagram.shows[o.id] ?? "type") === "hof",
      tooltip: diagram.tooltips[o.id],
      x: 0, y: 0, w: 0, h: 0,
      inPins: [], outPins: [],
    };
    const [w, h] = nodeDims(role);
    return { ...role, w, h };
  };

const buildDiamondNode = (kind: "decision" | "merge", diagram: DiagramMeta) =>
  (d: { id: string; label?: string }): GNode => ({
    id: d.id, label: d.label ?? "",
    kind, isHof: false,
    tooltip: diagram.tooltips[d.id],
    x: 0, y: 0, w: DECISION_SZ, h: DECISION_SZ,
    inPins: [], outPins: [],
  });

// ── Edge builders ─────────────────────────────────────────────────────────

const buildFlowEdge = (nodeMap: ReadonlyMap<string, GNode>) =>
  (f: ActivityDef["flows"][number]): GEdge => ({
    from: f.from, to: f.to, label: f.label,
    isHof: nodeMap.get(f.from)!.isHof, isObjectFlow: true,
  });

const buildSuccEdge = (s: ActivityDef["successions"][number]): GEdge => ({
  from: s.from, to: s.to, label: undefined, isHof: false, isObjectFlow: false,
});

/**
 * Build the render plan for one activity diagram.
 */
export async function renderActivity(
  actDef: ActivityDef,
  diagram: DiagramMeta,
  actionDefs: Map<string, ActionDef>,
): Promise<RenderPlan> {
  const hideInPinLabels = (actDef.lanes?.length ?? 0) > 0;

  // ── Nodes ──────────────────────────────────────────────────────────────
  const actionNodes   = actDef.actions.map(buildActionNode(actionDefs, diagram, hideInPinLabels));
  const objectNodes   = actDef.objects.map(buildObjectNode(diagram));
  const decisionNodes = actDef.decisions.map(buildDiamondNode("decision", diagram));
  const mergeNodes    = actDef.merges.map(buildDiamondNode("merge", diagram));
  const { noteNodes, noteEdgesOf } = buildNotes(actDef.notes, diagram.tooltips);

  const nodes   = [...actionNodes, ...objectNodes, ...decisionNodes, ...mergeNodes, ...noteNodes];
  const nodeMap = buildNodeMap(nodes);

  // ── Edges ──────────────────────────────────────────────────────────────
  const flowEdges = pipe(actDef.flows,       filterEdges(nodeMap), A.map(buildFlowEdge(nodeMap)));
  const succEdges = pipe(actDef.successions, filterEdges(nodeMap), A.map(buildSuccEdge));
  const noteEdges = noteEdgesOf(nodeMap);
  const edges     = [...flowEdges, ...succEdges, ...noteEdges];

  // Match each object-flow edge to a named pin on action endpoints.
  const pinnedEdges = assignActionPins(edges, nodeMap);

  // ── Lanes (swimlane decoration) ─────────────────────────────────────────
  const laneSpecs: LaneSpec[] = (actDef.lanes ?? []).map(l => ({
    id: l.id, label: l.label, members: l.members,
  }));

  // ── Layout + routing via ELK ───────────────────────────────────────────
  const { width: innerW, height: innerH, nodes: positioned, edgePaths, lanes: laneGeoms } =
    await layoutGraph(nodes, pinnedEdges, diagram.direction ?? "LR", laneSpecs);

  const dx = FRAME_PAD;
  const dy = FRAME_PAD + FRAME_TAB_H;
  const { shiftedNodes, shiftedPaths, shiftedLanes } =
    shiftCoordinates(positioned, edgePaths, laneGeoms, dx, dy);

  const W = innerW + 2 * FRAME_PAD;
  const H = innerH + 2 * FRAME_PAD + FRAME_TAB_H;

  return {
    width: W,
    height: H,
    draw(parent) {
      appendDiagramFrame(parent, "activity", diagram.name ?? actDef.name, W, H);
      shiftedLanes.forEach(l => appendLaneBand(parent, l));
      pinnedEdges.forEach((e, i) => appendGEdge(parent, e, shiftedPaths[i]));
      shiftedNodes.forEach(n => appendGNode(parent, n));
    },
  };
}
