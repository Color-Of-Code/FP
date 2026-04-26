/**
 * AST types for SysML v2 subset parser, graph types for layout/rendering,
 * dimension constants, and colour palette.
 */

// ── Shared type aliases ────────────────────────────────────────────────────

export type Role = "hof" | "type" | "value" | "function" | "initial" | "final";
export type DiagramType = "ibd" | "activity";

// ── IBD AST ────────────────────────────────────────────────────────────────

export interface PortDef { kind: "portDef"; name: string; }

export interface PortUsage {
  kind: "port";
  id: string;
  type: string;
  direction?: "in" | "out" | "inout";
}

export interface PartUsage {
  kind: "part";
  id: string;
  type: string;
  ports: PortUsage[];
}

export interface ConnectionUsage {
  kind: "connection";
  id?: string;
  from: string;
  to: string;
  via?: string;
  label?: string;
}

export interface PartDef {
  kind: "partDef";
  name: string;
  parts: PartUsage[];
  ports: PortUsage[];
  connections: ConnectionUsage[];
}

// ── Activity AST ───────────────────────────────────────────────────────────

export interface ActionDef {
  kind: "actionDef";
  name: string;
  pins: PortUsage[];
}

export interface ActionUsage {
  kind: "action";
  id: string;
  type: string;
}

export interface ObjectNode {
  kind: "object";
  id: string;
  type: string;
}

export interface FlowUsage {
  kind: "flow";
  from: string;
  to: string;
  label?: string;
}

export interface SuccessionUsage {
  kind: "succession";
  from: string;
  to: string;
}

export interface ActivityDef {
  kind: "activityDef";
  name: string;
  actions: ActionUsage[];
  objects: ObjectNode[];
  flows: FlowUsage[];
  successions: SuccessionUsage[];
}

// ── Package / Model ────────────────────────────────────────────────────────

export interface PackageDecl {
  name: string;
  portDefs: PortDef[];
  partDefs: PartDef[];
  actionDefs: ActionDef[];
  activityDefs: ActivityDef[];
}

export interface DiagramMeta {
  diagType: DiagramType;
  title?: string;
  /** Short operation name used as the activity-frame tab label (e.g. "traverse") */
  name?: string;
  /** Layout direction: "LR" (default, left→right) or "TB" (top→bottom) */
  direction?: "LR" | "TB";
  shows: Record<string, Role>;
  tooltips: Record<string, string>;
  render?: string;
}

export interface Model {
  packages: PackageDecl[];
  diagram: DiagramMeta;
}

// ── Graph types for layout + rendering ─────────────────────────────────────

export interface GNode {
  id: string;
  label: string;
  stereotype?: string;
  kind: "action" | "object" | "initial" | "final";
  isHof: boolean;
  tooltip?: string;
  x: number; y: number;
  w: number; h: number;
  inPins: string[];
  outPins: string[];
}

export interface GEdge {
  from: string; to: string;
  label?: string;
  isObjectFlow: boolean;
  isHof: boolean;
}

// ── Dimension constants ────────────────────────────────────────────────────

export const ACTION_W = 120;
export const ACTION_H = 44;
export const ACTION_RX = 12;
export const OBJECT_W = 110;
export const OBJECT_H = 38;
export const PIN_SZ = 8;
export const INIT_R = 8;
export const FINAL_R = 10;
export const FINAL_R_INNER = 6;
export const FRAME_PAD = 16;
export const FRAME_TAB_W = 200;
export const FRAME_TAB_H = 22;
export const EDGE_GAP = 40;
export const NODE_VGAP = 14;

// ── Colour palette ─────────────────────────────────────────────────────────

export const COL = {
  actionFill: "#e8f5e9", actionStroke: "#388e3c",
  objFill:    "#f5f5f5", objStroke:    "#616161",
  hofFill:    "#e0f2f1", hofStroke:    "#00796b",
  pinFill:    "#e0e0e0", pinStroke:    "#424242",
  frameFill:  "#fafafa", frameStroke:  "#9e9e9e",
  initFill:   "#212121",
  finalStroke:"#212121", finalFill: "#212121",
  edgeStroke: "#424242",
  hofEdge:    "#00796b",
  labelFill:  "#333",
};

// ── Utilities ──────────────────────────────────────────────────────────────

export function nodeDims(n: GNode): [number, number] {
  if (n.kind === "initial") return [INIT_R * 2, INIT_R * 2];
  if (n.kind === "final")   return [FINAL_R * 2, FINAL_R * 2];
  if (n.kind === "action")  return [ACTION_W, ACTION_H];
  const charW = 7.2;
  const w = Math.max(OBJECT_W, n.label.length * charW + 20);
  return [w, OBJECT_H];
}

export function escXml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
