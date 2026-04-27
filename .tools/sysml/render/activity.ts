/**
 * Activity diagram builder.
 *
 * Converts an ActivityDef + DiagramMeta + ActionDef map into an SVG inner
 * fragment (without the outer SVG shell).  Handles:
 *   - Action, object, decision, merge nodes
 *   - Object flows and control flows (successions)
 *   - Invisible branch-separator nodes that prevent decision branches from
 *     overlapping when dagre places them at the same rank
 */

import {
  type ActivityDef, type ActionDef, type DiagramMeta, type GNode, type GEdge,
  ACTION_W, ACTION_H, DECISION_SZ,
  FRAME_PAD, FRAME_TAB_H, BRANCH_SEP_H,
  nodeDims,
} from "../types.ts";
import { autoLayout } from "../layout.ts";
import { appendGNode } from "./nodes.ts";
import { computeEndpoints, appendGEdge } from "./edges.ts";
import { appendActivityFrame } from "./frame.ts";
import type { RenderPlan } from "./title.ts";

/**
 * Build the render plan for one activity diagram.
 */
export async function renderActivity(
  actDef: ActivityDef,
  diagram: DiagramMeta,
  actionDefs: Map<string, ActionDef>,
): Promise<RenderPlan> {
  const nodes: GNode[]           = [];
  const nodeMap = new Map<string, GNode>();

  // ── Action nodes ───────────────────────────────────────────────────────
  for (const a of actDef.actions) {
    const ad     = actionDefs.get(a.type);
    const inPins  = ad ? ad.pins.filter(p => p.direction === "in").map(p => p.id)  : [];
    const outPins = ad ? ad.pins.filter(p => p.direction === "out").map(p => p.id) : [];
    const n: GNode = {
      id: a.id, label: a.id, stereotype: a.type,
      kind: "action", isHof: false,
      tooltip: diagram.tooltips[a.id],
      x: 0, y: 0, w: ACTION_W, h: ACTION_H,
      inPins, outPins,
    };
    nodes.push(n); nodeMap.set(a.id, n);
  }

  // ── Object nodes ───────────────────────────────────────────────────────
  for (const o of actDef.objects) {
    const role  = diagram.shows[o.id] ?? "type";
    const n: GNode = {
      id: o.id, label: `${o.id} : ${o.type}`,
      kind: "object", isHof: role === "hof",
      tooltip: diagram.tooltips[o.id],
      x: 0, y: 0, w: 0, h: 0,
      inPins: [], outPins: [],
    };
    [n.w, n.h] = nodeDims(n);
    nodes.push(n); nodeMap.set(o.id, n);
  }

  // ── Decision / Merge nodes ─────────────────────────────────────────────
  for (const d of actDef.decisions) {
    const n: GNode = {
      id: d.id, label: d.label ?? "",
      kind: "decision", isHof: false,
      tooltip: diagram.tooltips[d.id],
      x: 0, y: 0, w: DECISION_SZ, h: DECISION_SZ,
      inPins: [], outPins: [],
    };
    nodes.push(n); nodeMap.set(d.id, n);
  }
  for (const m of actDef.merges) {
    const n: GNode = {
      id: m.id, label: m.label ?? "",
      kind: "merge", isHof: false,
      tooltip: diagram.tooltips[m.id],
      x: 0, y: 0, w: DECISION_SZ, h: DECISION_SZ,
      inPins: [], outPins: [],
    };
    nodes.push(n); nodeMap.set(m.id, n);
  }

  // ── Edges ──────────────────────────────────────────────────────────────
  const edges: GEdge[] = [];
  for (const f of actDef.flows) {
    if (!nodeMap.has(f.from) || !nodeMap.has(f.to)) continue;
    const src = nodeMap.get(f.from)!;
    edges.push({ from: f.from, to: f.to, label: f.label, isHof: src.isHof, isObjectFlow: true });
  }
  for (const s of actDef.successions) {
    if (!nodeMap.has(s.from) || !nodeMap.has(s.to)) continue;
    edges.push({ from: s.from, to: s.to, label: undefined, isHof: false, isObjectFlow: false });
  }

  // ── Branch separators ──────────────────────────────────────────────────
  // For each decision, inject an invisible node (width=1, height=BRANCH_SEP_H)
  // connected decision→sep (minlen=1) and sep→merge (minlen=2).
  // The tall height forces dagre to give the branches enough vertical room.
  const mergeIdSet = new Set(actDef.merges.map(m => m.id));

  function findMerge(decisionId: string): string | null {
    const queue   = [decisionId];
    const visited = new Set<string>();
    while (queue.length > 0) {
      const curr = queue.shift()!;
      if (visited.has(curr)) continue;
      visited.add(curr);
      if (curr !== decisionId && mergeIdSet.has(curr)) return curr;
      for (const e of edges) {
        if (e.from === curr && !visited.has(e.to)) queue.push(e.to);
      }
    }
    return null;
  }

  for (const d of actDef.decisions) {
    const mergeId = findMerge(d.id);
    if (!mergeId) continue;
    const sepId   = `_sep_${d.id}`;
    const sepNode: GNode = {
      id: sepId, label: "",
      kind: "separator", isHof: false, tooltip: undefined,
      x: 0, y: 0, w: 1, h: BRANCH_SEP_H,
      inPins: [], outPins: [],
    };
    nodes.push(sepNode);
    nodeMap.set(sepId, sepNode);
    edges.push({ from: d.id,  to: sepId,   label: undefined, isHof: false, isObjectFlow: false, isSeparator: true, minlen: 1 });
    edges.push({ from: sepId, to: mergeId, label: undefined, isHof: false, isObjectFlow: false, isSeparator: true, minlen: 2 });
  }

  // ── Layout ─────────────────────────────────────────────────────────────
  const [innerW, innerH] = await autoLayout(
    nodes, edges,
    diagram.layout    ?? "dagre",
    diagram.direction ?? "LR",
  );
  for (const n of nodes) {
    n.x += FRAME_PAD;
    n.y += FRAME_PAD + FRAME_TAB_H;
  }

  const W = innerW + 2 * FRAME_PAD;
  const H = innerH + 2 * FRAME_PAD + FRAME_TAB_H;

  const pts = computeEndpoints(edges, nodeMap);

  return {
    width: W,
    height: H,
    draw(parent) {
      appendActivityFrame(parent, diagram.name ?? actDef.name, W, H);
      edges.forEach((e, i) => {
        if (!e.isSeparator) appendGEdge(parent, e, pts[i]);
      });
      nodes.forEach(n => appendGNode(parent, n));
    },
  };
}
