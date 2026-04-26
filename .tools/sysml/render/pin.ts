/**
 * Pin geometry: vertical slot positions and semantic edge-to-pin assignment.
 *
 * Pins are small squares straddling the left (input) or right (output) boundary
 * of an action node.  Slot positions are evenly distributed over the node height.
 * Semantic matching assigns each arriving/departing edge to the named pin that
 * matches by type-flow rather than spatial proximity.
 */

import { type GNode, type GEdge } from "../types.ts";

/**
 * Vertical centre of pin slot `index` (0-based) out of `total` slots on
 * the left or right edge of action node `n`.
 */
export function pinSlotY(n: GNode, index: number, total: number): number {
  const count = Math.max(total, 1);
  return n.y - n.h / 2 + (n.h / (count + 1)) * (index + 1);
}

/**
 * Assign each object-flow edge to a named pin slot on an action node using
 * semantic matching so the correct pin is targeted regardless of spatial position.
 *
 * Priority for an incoming edge (src → action dst):
 *   1. src is action  → match src.outPin name to dst.inPin name
 *   2. src is object  → match src.id to dst.inPin name
 *   3. fallback       → assign leftover slots in y-sorted order
 *
 * Symmetric for outgoing (action src → dst):
 *   1. dst is action  → match src.outPin name to dst.inPin name
 *   2. dst is object  → match src.outPin name to dst.id
 *   3. fallback       → y-sorted order
 */
export function semanticPinIndex(
  nodeId: string,
  es: GEdge[],
  nodeMap: Map<string, GNode>,
  side: "in" | "out",
): Map<GEdge, [number, number]> {
  const result = new Map<GEdge, [number, number]>();
  const node = nodeMap.get(nodeId);
  const pins = side === "in" ? (node?.inPins ?? []) : (node?.outPins ?? []);

  if (node?.kind !== "action" || pins.length === 0) {
    // No pin matching — assign positionally in y-sorted order
    const sorted = [...es].sort((a, b) => {
      const opp  = side === "in" ? a.from : a.to;
      const oppB = side === "in" ? b.from : b.to;
      return (nodeMap.get(opp)?.y ?? 0) - (nodeMap.get(oppB)?.y ?? 0);
    });
    sorted.forEach((e, i) => result.set(e, [i, es.length]));
    return result;
  }

  const assigned  = new Map<GEdge, number>();
  const usedSlots = new Set<number>();
  const unmatched: GEdge[] = [];

  for (const e of es) {
    const otherId = side === "in" ? e.from : e.to;
    const other   = nodeMap.get(otherId);
    let slotIdx   = -1;

    if (other?.kind === "action") {
      // Match by shared pin name between the two action nodes
      const otherPins = side === "in" ? other.outPins : other.inPins;
      for (const p of otherPins) {
        const idx = pins.findIndex((q, i) => q === p && !usedSlots.has(i));
        if (idx !== -1) { slotIdx = idx; break; }
      }
    }
    if (slotIdx === -1 && other) {
      // Match by object node id → pin name
      const idx = pins.findIndex((q, i) => q === other.id && !usedSlots.has(i));
      if (idx !== -1) slotIdx = idx;
    }

    if (slotIdx !== -1) {
      assigned.set(e, slotIdx);
      usedSlots.add(slotIdx);
    } else {
      unmatched.push(e);
    }
  }

  // Assign remaining unmatched edges to unused slots in y-sorted order
  const unusedSlots    = pins.map((_, i) => i).filter(i => !usedSlots.has(i));
  const sortedUnmatched = [...unmatched].sort((a, b) => {
    const opp  = side === "in" ? a.from : a.to;
    const oppB = side === "in" ? b.from : b.to;
    return (nodeMap.get(opp)?.y ?? 0) - (nodeMap.get(oppB)?.y ?? 0);
  });
  sortedUnmatched.forEach((e, i) =>
    assigned.set(e, unusedSlots[i] ?? pins.length - 1));

  es.forEach(e => result.set(e, [assigned.get(e) ?? 0, pins.length]));
  return result;
}
