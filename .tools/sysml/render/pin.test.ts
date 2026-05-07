import { describe, it, expect } from "vitest";
import { assignActionPins, chooseSharedPin, chooseObjectIdPin } from "./pin.ts";
import type { GEdge, GNode } from "../types.ts";

function makeAction(id: string, inPins: string[], outPins: string[]): GNode {
  return { id, label: id, kind: "action", isHof: false, x: 0, y: 0, w: 80, h: 40, inPins, outPins };
}

function makeObject(id: string): GNode {
  return { id, label: id, kind: "object", isHof: false, x: 0, y: 0, w: 60, h: 30, inPins: [], outPins: [] };
}

function makeEdge(from: string, to: string): GEdge {
  return { from, to, label: undefined, isHof: false, isObjectFlow: true };
}

// ── chooseSharedPin ────────────────────────────────────────────────────────

describe("chooseSharedPin", () => {
  it("picks a pin shared between two actions", () => {
    const nodeMap = new Map<string, GNode>([
      ["a1", makeAction("a1", ["x"], ["shared"])],
      ["a2", makeAction("a2", ["shared"], ["y"])],
    ]);
    const e = makeEdge("a1", "a2");
    const pin = chooseSharedPin(e, "in", ["shared"], new Set(), nodeMap);
    expect(pin).toBe("shared");
  });

  it("returns undefined if no shared pin", () => {
    const nodeMap = new Map<string, GNode>([
      ["a1", makeAction("a1", [], ["out1"])],
      ["a2", makeAction("a2", ["in1"], [])],
    ]);
    const e = makeEdge("a1", "a2");
    const pin = chooseSharedPin(e, "in", ["in1"], new Set(), nodeMap);
    expect(pin).toBeUndefined();
  });

  it("skips already-used pins", () => {
    const nodeMap = new Map<string, GNode>([
      ["a1", makeAction("a1", [], ["shared"])],
      ["a2", makeAction("a2", ["shared", "other"], [])],
    ]);
    const e = makeEdge("a1", "a2");
    const pin = chooseSharedPin(e, "in", ["shared", "other"], new Set(["shared"]), nodeMap);
    expect(pin).toBeUndefined();
  });
});

// ── chooseObjectIdPin ──────────────────────────────────────────────────────

describe("chooseObjectIdPin", () => {
  it("matches object id to pin name", () => {
    const nodeMap = new Map<string, GNode>([
      ["obj1", makeObject("obj1")],
      ["a1", makeAction("a1", ["obj1"], [])],
    ]);
    const e = makeEdge("obj1", "a1");
    const pin = chooseObjectIdPin(e, "in", ["obj1"], new Set(), nodeMap);
    expect(pin).toBe("obj1");
  });

  it("returns undefined when id not in pins", () => {
    const nodeMap = new Map<string, GNode>([
      ["obj1", makeObject("obj1")],
      ["a1", makeAction("a1", ["other"], [])],
    ]);
    const e = makeEdge("obj1", "a1");
    const pin = chooseObjectIdPin(e, "in", ["other"], new Set(), nodeMap);
    expect(pin).toBeUndefined();
  });
});

// ── assignActionPins (integration) ─────────────────────────────────────────

describe("assignActionPins", () => {
  it("assigns srcPin and dstPin for action→action edge", () => {
    const a1 = makeAction("a1", ["x"], ["shared"]);
    const a2 = makeAction("a2", ["shared"], ["y"]);
    const nodeMap = new Map<string, GNode>([["a1", a1], ["a2", a2]]);
    const edges = [makeEdge("a1", "a2")];
    assignActionPins(edges, nodeMap);
    expect(edges[0].srcPin).toBe("shared");
    expect(edges[0].dstPin).toBe("shared");
  });

  it("assigns pin by object id match", () => {
    const obj = makeObject("input");
    const act = makeAction("act", ["input", "other"], []);
    const nodeMap = new Map<string, GNode>([["input", obj], ["act", act]]);
    const edges = [makeEdge("input", "act")];
    assignActionPins(edges, nodeMap);
    expect(edges[0].dstPin).toBe("input");
  });

  it("distributes leftover edges to remaining pins", () => {
    const obj1 = makeObject("x");
    const obj2 = makeObject("y");
    const act = makeAction("act", ["p1", "p2"], []);
    const nodeMap = new Map<string, GNode>([["x", obj1], ["y", obj2], ["act", act]]);
    const edges = [makeEdge("x", "act"), makeEdge("y", "act")];
    assignActionPins(edges, nodeMap);
    expect(edges[0].dstPin).toBe("p1");
    expect(edges[1].dstPin).toBe("p2");
  });

  it("skips non-object-flow edges", () => {
    const a1 = makeAction("a1", ["x"], []);
    const a2 = makeAction("a2", [], ["y"]);
    const nodeMap = new Map<string, GNode>([["a1", a1], ["a2", a2]]);
    const edges: GEdge[] = [{ from: "a1", to: "a2", label: undefined, isHof: false, isObjectFlow: false }];
    assignActionPins(edges, nodeMap);
    expect(edges[0].srcPin).toBeUndefined();
    expect(edges[0].dstPin).toBeUndefined();
  });
});
