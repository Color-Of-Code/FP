/**
 * Graph node and edge types used by the layout engine and all renderers.
 * Also provides nodeDims() — the canonical size of each node kind.
 */

import {
  ACTION_W, ACTION_H,
  OBJECT_W, OBJECT_H,
  INIT_R, FINAL_R,
  DECISION_SZ,
} from "./constants.ts";

// ── Graph node ─────────────────────────────────────────────────────────────

export interface GNode {
  id:         string;
  label:      string;
  stereotype?: string;
  kind: "action" | "object" | "initial" | "final" | "decision" | "merge";
  isHof:      boolean;
  tooltip?:   string;
  x: number; y: number;
  w: number; h: number;
  inPins:     string[];
  outPins:    string[];
}

// ── Graph edge ─────────────────────────────────────────────────────────────

export interface GEdge {
  from:         string;
  to:           string;
  label?:       string;
  isObjectFlow: boolean;
  isHof:        boolean;
  /** Output-pin id on `from` (only meaningful when `from` is an action node). */
  srcPin?:      string;
  /** Input-pin id on `to` (only meaningful when `to` is an action node). */
  dstPin?:      string;
}

// ── Node dimensions ────────────────────────────────────────────────────────

/** Return the (width, height) of a node based on its kind and label. */
export function nodeDims(n: GNode): [number, number] {
  if (n.kind === "initial")   return [INIT_R * 2,    INIT_R * 2];
  if (n.kind === "final")     return [FINAL_R * 2,   FINAL_R * 2];
  if (n.kind === "decision" || n.kind === "merge") {
    const w = n.label ? Math.max(DECISION_SZ, n.label.length * 6 + 16) : DECISION_SZ;
    return [w, DECISION_SZ];
  }
  if (n.kind === "action")    return [ACTION_W,       ACTION_H];
  // object node: width scales with label length
  const charW = 7.2;
  const w = Math.max(OBJECT_W, n.label.length * charW + 20);
  return [w, OBJECT_H];
}
