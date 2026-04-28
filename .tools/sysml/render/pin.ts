/**
 * Pin assignment: pick a named pin on each action endpoint of every
 * object-flow edge.  The chosen pin name is stored on the edge as
 * `srcPin` / `dstPin` and consumed by the layout layer to build a real
 * ELK port and route the edge to it.
 *
 * Matching priority for an action endpoint (input side shown; outputs
 * mirror it):
 *   1. The opposite endpoint is also an action and shares a pin name.
 *   2. The opposite endpoint is an object whose `id` matches a pin name.
 *   3. Otherwise, take the next unused pin in declaration order.
 */

import type { GEdge, GNode } from "../types.ts";

/**
 * Mutate every object-flow edge in `edges` so it carries `srcPin` and/or
 * `dstPin` whenever its source / target is an action node.  Other edges
 * are left untouched.
 */
export function assignActionPins(
  edges: GEdge[],
  nodeMap: Map<string, GNode>,
): void {
  // Group edges by the action endpoint that needs a pin.
  const inGroups  = new Map<string, GEdge[]>();
  const outGroups = new Map<string, GEdge[]>();
  for (const e of edges) {
    if (!e.isObjectFlow) continue;
    const src = nodeMap.get(e.from);
    const tgt = nodeMap.get(e.to);
    if (src?.kind === "action") {
      if (!outGroups.has(src.id)) outGroups.set(src.id, []);
      outGroups.get(src.id)!.push(e);
    }
    if (tgt?.kind === "action") {
      if (!inGroups.has(tgt.id)) inGroups.set(tgt.id, []);
      inGroups.get(tgt.id)!.push(e);
    }
  }

  for (const [nodeId, es] of inGroups)  matchSide(nodeId, es, nodeMap, "in");
  for (const [nodeId, es] of outGroups) matchSide(nodeId, es, nodeMap, "out");
}

function matchSide(
  nodeId: string,
  es: GEdge[],
  nodeMap: Map<string, GNode>,
  side: "in" | "out",
): void {
  const node = nodeMap.get(nodeId);
  if (!node || node.kind !== "action") return;
  const pins = side === "in" ? node.inPins : node.outPins;
  if (pins.length === 0) return;

  const used = new Set<string>();
  const setPin = (e: GEdge, pin: string): void => {
    if (side === "in") e.dstPin = pin;
    else                e.srcPin = pin;
    used.add(pin);
  };

  const unmatched: GEdge[] = [];

  for (const e of es) {
    const otherId = side === "in" ? e.from : e.to;
    const other   = nodeMap.get(otherId);
    let chosen: string | undefined;

    if (other?.kind === "action") {
      const otherPins = side === "in" ? other.outPins : other.inPins;
      for (const p of otherPins) {
        if (pins.includes(p) && !used.has(p)) { chosen = p; break; }
      }
    }
    if (!chosen && other && pins.includes(other.id) && !used.has(other.id)) {
      chosen = other.id;
    }

    if (chosen) setPin(e, chosen);
    else unmatched.push(e);
  }

  // Distribute leftovers in declaration order to keep things deterministic.
  const free = pins.filter(p => !used.has(p));
  unmatched.forEach((e, i) => {
    const pin = free[i] ?? pins[pins.length - 1];
    setPin(e, pin);
  });
}
