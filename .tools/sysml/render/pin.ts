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
import { forEach, groupBy } from "../lib/fp.ts";

/**
 * Return a copy of `edges` where every object-flow edge carries `srcPin`
 * and/or `dstPin` whenever its source / target is an action node.
 * Other edges are returned unchanged.
 */
export function assignActionPins(
  edges: readonly GEdge[],
  nodeMap: ReadonlyMap<string, GNode>,
): GEdge[] {
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

  // Collect pin assignments as a Map<edge, { srcPin?, dstPin? }>
  const assignments = new Map<GEdge, { srcPin?: string; dstPin?: string }>();
  const assign = (e: GEdge, side: "in" | "out", pin: string): void => {
    const existing = assignments.get(e) ?? {};
    // eslint-disable-next-line functional/immutable-data -- local accumulator for pure return
    assignments.set(e, side === "in" ? { ...existing, dstPin: pin } : { ...existing, srcPin: pin });
  };

  forEach(inByAction,  (es, nodeId) => matchSide(nodeId, es, nodeMap, "in",  assign));
  forEach(outByAction, (es, nodeId) => matchSide(nodeId, es, nodeMap, "out", assign));

  return edges.map(e => {
    const patch = assignments.get(e);
    return patch ? { ...e, ...patch } : e;
  });
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
  es: readonly GEdge[],
  nodeMap: ReadonlyMap<string, GNode>,
  side: "in" | "out",
  assign: (e: GEdge, side: "in" | "out", pin: string) => void,
): void {
  const node = nodeMap.get(nodeId);
  if (node?.kind !== "action") return;
  const pins = side === "in" ? node.inPins : node.outPins;
  if (pins.length === 0) return;

  // First pass: match by shared pin or object-id, tracking used pins.
  const { used, unmatched } = es.reduce<{ used: ReadonlySet<string>; unmatched: readonly GEdge[] }>(
    (acc, e) => {
      const chosen = chooseSharedPin(e, side, pins, acc.used, nodeMap)
                  ?? chooseObjectIdPin(e, side, pins, acc.used, nodeMap);
      if (chosen) {
        assign(e, side, chosen);
        return { used: new Set([...acc.used, chosen]), unmatched: acc.unmatched };
      }
      return { used: acc.used, unmatched: [...acc.unmatched, e] };
    },
    { used: new Set<string>(), unmatched: [] as readonly GEdge[] },
  );

  // Second pass: distribute leftovers in declaration order.
  const free = pins.filter(p => !used.has(p));
  unmatched.forEach((e, i) => {
    const pin = free[i] ?? pins[pins.length - 1];
    assign(e, side, pin);
  });
}
