import { describe, it, expect } from "vitest";
import { shiftCoordinates, buildNoteNode } from "./build-graph.ts";
import { pinPosition } from "./nodes.ts";
import type { GNode } from "../types.ts";
import type { LaneGeom } from "../layout.ts";

// ── shiftCoordinates ──────────────────────────────────────────────────────

describe("shiftCoordinates", () => {
  it("returns shifted node positions", () => {
    const nodes: GNode[] = [
      { id: "a", label: "", kind: "action", isHof: false, x: 10, y: 20, w: 50, h: 30, inPins: [], outPins: [] },
    ];
    const { shiftedNodes } = shiftCoordinates(nodes, [], [], 5, 7);
    expect(shiftedNodes[0].x).toBe(15);
    expect(shiftedNodes[0].y).toBe(27);
    // Original is unchanged
    expect(nodes[0].x).toBe(10);
    expect(nodes[0].y).toBe(20);
  });

  it("returns shifted edge polylines", () => {
    const paths: [number, number][][] = [
      [[0, 0], [10, 20]],
    ];
    const { shiftedPaths } = shiftCoordinates([], paths, [], 3, 4);
    expect(shiftedPaths).toEqual([[[3, 4], [13, 24]]]);
  });

  it("returns shifted lane geometries", () => {
    const lanes: LaneGeom[] = [
      { id: "l1", label: "Lane", x: 0, y: 0, w: 100, h: 50 },
    ];
    const { shiftedLanes } = shiftCoordinates([], [], lanes, 10, 20);
    expect(shiftedLanes[0]).toEqual({ id: "l1", label: "Lane", x: 10, y: 20, w: 100, h: 50 });
  });

  it("handles empty inputs", () => {
    const { shiftedPaths, shiftedLanes } = shiftCoordinates([], [], [], 5, 5);
    expect(shiftedPaths).toEqual([]);
    expect(shiftedLanes).toEqual([]);
  });
});

// ── buildNoteNode ─────────────────────────────────────────────────────────

describe("buildNoteNode", () => {
  it("creates a note GNode with correct dimensions", () => {
    const { node } = buildNoteNode(
      { id: "n1", text: "Hello", target: "a1" },
      {},
    );
    expect(node.id).toBe("n1");
    expect(node.kind).toBe("note");
    expect(node.label).toBe("Hello");
    expect(node.noteLines).toEqual(["Hello"]);
    expect(node.w).toBeGreaterThan(0);
    expect(node.h).toBeGreaterThan(0);
  });

  it("splits text on escaped newlines", () => {
    const { node } = buildNoteNode(
      { id: "n2", text: "Line1\\nLine2", target: "t" },
      {},
    );
    expect(node.noteLines).toEqual(["Line1", "Line2"]);
  });

  it("produces a note-attachment edge when target is set", () => {
    const { edge } = buildNoteNode(
      { id: "n3", text: "x", target: "t1" },
      {},
    );
    expect(edge).not.toBeNull();
    expect(edge!.from).toBe("n3");
    expect(edge!.to).toBe("t1");
    expect(edge!.isNoteAttachment).toBe(true);
    expect(edge!.isObjectFlow).toBe(false);
  });

  it("attaches tooltip from tooltips map", () => {
    const { node } = buildNoteNode(
      { id: "n4", text: "tip", target: "t" },
      { n4: "My tooltip" },
    );
    expect(node.tooltip).toBe("My tooltip");
  });
});

// ── pinPosition ───────────────────────────────────────────────────────────

describe("pinPosition", () => {
  const box = { x: 100, y: 100, w: 80, h: 60 };

  it("places a W pin on the left edge", () => {
    const { px, py } = pinPosition("W", 0, 1, box);
    expect(px).toBe(100 - 80 / 2 - 4); // x - w/2 - PIN_SZ/2
    expect(py).toBe(100 - 60 / 2 + (60 / 2) * 1 - 4); // centred vertically
  });

  it("places an E pin on the right edge", () => {
    const { px } = pinPosition("E", 0, 1, box);
    expect(px).toBe(100 + 80 / 2 - 4); // x + w/2 - PIN_SZ/2
  });

  it("places a N pin on the top edge", () => {
    const { py } = pinPosition("N", 0, 1, box);
    expect(py).toBe(100 - 60 / 2 - 4); // y - h/2 - PIN_SZ/2
  });

  it("places a S pin on the bottom edge", () => {
    const { py } = pinPosition("S", 0, 1, box);
    expect(py).toBe(100 + 60 / 2 - 4); // y + h/2 - PIN_SZ/2
  });

  it("distributes two W pins evenly", () => {
    const p0 = pinPosition("W", 0, 2, box);
    const p1 = pinPosition("W", 1, 2, box);
    expect(p0.py).toBeLessThan(p1.py);
    expect(p0.px).toBe(p1.px); // same x
  });

  it("returns label attrs with correct text-anchor for each side", () => {
    expect(pinPosition("W", 0, 1, box).labelAttrs["text-anchor"]).toBe("start");
    expect(pinPosition("E", 0, 1, box).labelAttrs["text-anchor"]).toBe("end");
    expect(pinPosition("N", 0, 1, box).labelAttrs["text-anchor"]).toBe("middle");
    expect(pinPosition("S", 0, 1, box).labelAttrs["text-anchor"]).toBe("middle");
  });
});
