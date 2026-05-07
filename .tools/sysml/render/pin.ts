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
import { groupBy } from "../lib/fp.ts";

/**
 * Mutate every object-flow edge in `edges` so it carries `srcPin` and/or
 * `dstPin` whenever its source / target is an action node.  Other edges
 * are left untouched.
 */
export function assignActionPins(
  edges: GEdge[],
  nodeMap: Map<string, GNode>,
): void {
  const objectFlows = edges.filter(e => e.isObjectFlow);

  // Group edges by the action endpoint that needs a pin.
  const outByAction = groupBy(
    objectFlows.filter(e => nodeMap.get(e.from)?.kind === "action"),
    e => e.from,
  );
  const inByAction = groupBy(
    objectFlows.filter(e => nodeMap.get(e.to)?.kind === "action"),
    e => e.to,
  );

  for (const [nodeId, es] of Object.entries(inByAction))  matchSide(nodeId, es, nodeMap, "in");
  for (const [nodeId, es] of Object.entries(outByAction)) matchSide(nodeId, es, nodeMap, "out");
}

/**
 * Try to match a pin by shared name with the opposite action endpoint.
 * Returns the chosen pin name or undefined.
 */
export function chooseSharedPin(
  e: GEdge, side: "in" | "out",
  pins: readonly string[], used: ReadonlySet<string>,
  nodeMap: Map<string, GNode>,
): string | undefined {
  const otherId = side === "in" ? e.from : e.to;
  const other   = nodeMap.get(otherId);
  if (other?.kind === "action") {
    const otherPins = side === "in" ? other.outPins : other.inPins;
    return otherPins.find(p => pins.includes(p) && !used.has(p));
  }
  return undefined;
}

/**
 * Try to match a pin whose name equals the opposite object node's id.
 * Returns the chosen pin name or undefined.
 */
export function chooseObjectIdPin(
  e: GEdge, side: "in" | "out",
  pins: readonly string[], used: ReadonlySet<string>,
  nodeMap: Map<string, GNode>,
): string | undefined {
  const otherId = side === "in" ? e.from : e.to;
  const other   = nodeMap.get(otherId);
  if (other && pins.includes(other.id) && !used.has(other.id)) {
    return other.id;
  }
  return undefined;
}

function matchSide(
  nodeId: string,
  es: GEdge[],
  nodeMap: Map<string, GNode>,
  side: "in" | "out",
): void {
  const node = nodeMap.get(nodeId);
  if (node?.kind !== "action") return;
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
    const chosen = chooseSharedPin(e, side, pins, used, nodeMap)
                ?? chooseObjectIdPin(e, side, pins, used, nodeMap);
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
