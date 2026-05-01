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
import { layoutGraph, type LaneSpec, type LaneGeom } from "../layout.ts";
import { appendGNode } from "./nodes.ts";
import { appendGEdge } from "./edges.ts";
import { appendActivityFrame } from "./frame.ts";
import { appendLaneBand } from "./lane.ts";
import { assignActionPins } from "./pin.ts";
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

  // ── Note nodes ─────────────────────────────────────────────────────────
  // A note is a free-floating annotation pinned to an existing node by a
  // dashed undirected edge.  We materialise it as a graph node so the layout
  // engine reserves space for it and routes the attachment cleanly.
  for (const note of actDef.notes) {
    const lines = note.text.split(/\\n|\n/);
    const n: GNode = {
      id: note.id, label: lines[0] ?? "",
      kind: "note", isHof: false,
      tooltip: diagram.tooltips[note.id],
      x: 0, y: 0, w: 0, h: 0,
      inPins: [], outPins: [],
      noteLines: lines,
    };
    [n.w, n.h] = nodeDims(n);
    nodes.push(n); nodeMap.set(note.id, n);
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
  // Note attachments — undirected dashed connectors from each note to its target.
  for (const note of actDef.notes) {
    if (!nodeMap.has(note.id) || !nodeMap.has(note.target)) continue;
    edges.push({
      from: note.id, to: note.target,
      label: undefined, isHof: false, isObjectFlow: false,
      isNoteAttachment: true,
    });
  }

  // Match each object-flow edge to a named pin on action endpoints.
  assignActionPins(edges, nodeMap);

  // ── Lanes (swimlane decoration) ─────────────────────────────────────────
  const laneSpecs: LaneSpec[] = (actDef.lanes ?? []).map(l => ({
    id:      l.id,
    label:   l.label,
    members: l.members,
  }));

  // ── Layout + routing via ELK ───────────────────────────────────────────
  const { width: innerW, height: innerH, edgePaths, lanes: laneGeoms } = await layoutGraph(
    nodes, edges, diagram.direction ?? "LR", laneSpecs,
  );

  // Shift everything inside the activity frame.
  const dx = FRAME_PAD;
  const dy = FRAME_PAD + FRAME_TAB_H;
  for (const n of nodes) {
    n.x += dx;
    n.y += dy;
  }
  const shiftedPaths = edgePaths.map(pts =>
    pts.map(([x, y]) => [x + dx, y + dy] as [number, number]),
  );
  const shiftedLanes: LaneGeom[] = laneGeoms.map(l => ({
    ...l,
    x: l.x + dx,
    y: l.y + dy,
  }));

  const W = innerW + 2 * FRAME_PAD;
  const H = innerH + 2 * FRAME_PAD + FRAME_TAB_H;

  return {
    width: W,
    height: H,
    draw(parent) {
      appendActivityFrame(parent, diagram.name ?? actDef.name, W, H);
      // Lane bands sit between the frame and the edges so they read as
      // background scenery without occluding flows or nodes.
      shiftedLanes.forEach(l => appendLaneBand(parent, l));
      edges.forEach((e, i) => {
        appendGEdge(parent, e, shiftedPaths[i]);
      });
      nodes.forEach(n => appendGNode(parent, n));
    },
  };
}
