import { describe, it, expect } from "vitest";
import type { GNode, GEdge } from "./types.ts";
import {
  buildContext,
  computeCanvasAndLanes,
  extractEdgePaths,
  straightenLaneEdges,
  snapDecisionMergeEdges,
  adjustLanePositions,
  type LaneSpec,
} from "./layout.ts";

// ── Helpers ─────────────────────────────────────────────────────────────────

function makeNode(overrides: Partial<GNode> & { id: string }): GNode {
  return {
    label: overrides.id,
    kind: "action",
    isHof: false,
    x: 0, y: 0, w: 60, h: 30,
    inPins: [], outPins: [],
    ...overrides,
  };
}

function makeEdge(overrides: Partial<GEdge> & { from: string; to: string }): GEdge {
  return {
    isObjectFlow: false,
    isHof: false,
    ...overrides,
  };
}

// ── buildContext ────────────────────────────────────────────────────────────

describe("buildContext", () => {
  it("builds nodeIndex from nodes", () => {
    const a = makeNode({ id: "a" });
    const b = makeNode({ id: "b" });
    const ctx = buildContext([a, b], [], "LR", []);
    expect(ctx.nodeIndex.get("a")).toBe(a);
    expect(ctx.nodeIndex.get("b")).toBe(b);
  });

  it("computes mergeIds", () => {
    const m = makeNode({ id: "m1", kind: "merge" });
    const a = makeNode({ id: "a1" });
    const ctx = buildContext([m, a], [], "LR", []);
    expect(ctx.mergeIds.has("m1")).toBe(true);
    expect(ctx.mergeIds.has("a1")).toBe(false);
  });

  it("computes hasOutgoing and hasIncoming (ignoring note attachments)", () => {
    const edges: GEdge[] = [
      makeEdge({ from: "a", to: "b" }),
      makeEdge({ from: "c", to: "d", isNoteAttachment: true }),
    ];
    const ctx = buildContext([], edges, "LR", []);
    expect(ctx.hasOutgoing.has("a")).toBe(true);
    expect(ctx.hasIncoming.has("b")).toBe(true);
    expect(ctx.hasOutgoing.has("c")).toBe(false); // note attachment excluded
    expect(ctx.hasIncoming.has("d")).toBe(false);
  });

  it("sets direction/sides for LR layout", () => {
    const ctx = buildContext([], [], "LR", []);
    expect(ctx.direction).toBe("RIGHT");
    expect(ctx.inSide).toBe("WEST");
    expect(ctx.outSide).toBe("EAST");
    expect(ctx.altSide).toBe("SOUTH");
  });

  it("sets direction/sides for TB layout", () => {
    const ctx = buildContext([], [], "TB", []);
    expect(ctx.direction).toBe("DOWN");
    expect(ctx.inSide).toBe("NORTH");
    expect(ctx.outSide).toBe("SOUTH");
    expect(ctx.altSide).toBe("EAST");
  });

  it("builds lane lookups", () => {
    const lanes: LaneSpec[] = [
      { id: "top", members: ["a", "b"] },
      { id: "bot", members: ["c"] },
    ];
    const ctx = buildContext([], [], "LR", lanes);
    expect(ctx.useLanes).toBe(true);
    expect(ctx.laneOf.get("a")).toBe("top");
    expect(ctx.laneOf.get("c")).toBe("bot");
    expect(ctx.laneRankOf.get("b")).toBe(0);
    expect(ctx.laneRankOf.get("c")).toBe(1);
  });
});

// ── extractEdgePaths ────────────────────────────────────────────────────────

describe("extractEdgePaths", () => {
  it("extracts polylines from ELK edge sections", () => {
    const elkResult = {
      edges: [{
        id: "e1",
        sections: [{
          startPoint: { x: 0, y: 0 },
          endPoint: { x: 100, y: 50 },
          bendPoints: [{ x: 50, y: 0 }, { x: 50, y: 50 }],
        }],
      }],
    };
    const idMap = new Map([["e1", 1]]);
    const paths = extractEdgePaths(elkResult, idMap, 3);
    expect(paths).toHaveLength(3);
    expect(paths[0]).toEqual([]);
    expect(paths[1]).toEqual([[0, 0], [50, 0], [50, 50], [100, 50]]);
    expect(paths[2]).toEqual([]);
  });

  it("handles missing sections gracefully", () => {
    const elkResult = { edges: [{ id: "e0" }] };
    const idMap = new Map([["e0", 0]]);
    const paths = extractEdgePaths(elkResult, idMap, 1);
    expect(paths[0]).toEqual([]);
  });
});

// ── snapDecisionMergeEdges ──────────────────────────────────────────────────

describe("snapDecisionMergeEdges", () => {
  it("rewrites decision→merge edge to L-shape in LR mode", () => {
    const decision = makeNode({ id: "d", kind: "decision", x: 100, y: 50 });
    const merge = makeNode({ id: "m", kind: "merge", x: 200, y: 100 });
    const edges: GEdge[] = [makeEdge({ from: "d", to: "m" })];
    const ctx = buildContext([decision, merge], edges, "LR", []);

    const edgePaths: (readonly (readonly [number, number])[])[] = [
      [[100, 50], [120, 60], [180, 90], [200, 100]],
    ];
    snapDecisionMergeEdges(edges, edgePaths, ctx);

    // Should be rewritten to: drop to ty, then run to tx
    expect(edgePaths[0]).toEqual([[100, 50], [100, 100], [200, 100]]);
    expect(edges[0].labelNearSource).toBe(true);
  });

  it("rewrites to straight line when x matches in LR mode", () => {
    const decision = makeNode({ id: "d", kind: "decision", x: 100, y: 50 });
    const merge = makeNode({ id: "m", kind: "merge", x: 100, y: 100 });
    const edges: GEdge[] = [makeEdge({ from: "d", to: "m" })];
    const ctx = buildContext([decision, merge], edges, "LR", []);

    const edgePaths: (readonly (readonly [number, number])[])[] = [
      [[100, 50], [100, 100]],
    ];
    snapDecisionMergeEdges(edges, edgePaths, ctx);
    expect(edgePaths[0]).toEqual([[100, 50], [100, 100]]);
  });

  it("does not touch non-decision→merge edges", () => {
    const a = makeNode({ id: "a" });
    const b = makeNode({ id: "b" });
    const edges: GEdge[] = [makeEdge({ from: "a", to: "b" })];
    const ctx = buildContext([a, b], edges, "LR", []);

    const original: [number, number][] = [[0, 0], [50, 25], [100, 50]];
    const edgePaths: (readonly (readonly [number, number])[])[] = [original];
    snapDecisionMergeEdges(edges, edgePaths, ctx);
    expect(edgePaths[0]).toBe(original);
  });
});

// ── computeCanvasAndLanes ───────────────────────────────────────────────────

describe("computeCanvasAndLanes", () => {
  it("uses ELK dimensions when no lanes", () => {
    const ctx = buildContext([], [], "LR", []);
    const { totalW, totalH, laneGeoms } = computeCanvasAndLanes([], ctx, 300, 150);
    expect(totalW).toBe(300);
    expect(totalH).toBe(150);
    expect(laneGeoms).toEqual([]);
  });

  it("computes content-based dimensions for lane diagrams", () => {
    const nodes = [
      makeNode({ id: "a", x: 100, y: 50, w: 60, h: 30 }),
      makeNode({ id: "b", x: 200, y: 100, w: 60, h: 30 }),
    ];
    const lanes: LaneSpec[] = [
      { id: "top", members: ["a"] },
      { id: "bot", members: ["b"] },
    ];
    const ctx = buildContext(nodes, [], "LR", lanes);
    const { totalW, totalH } = computeCanvasAndLanes(nodes, ctx, 500, 500);
    // totalW = max(200, 200+30, 100+30) + 30 = 230 + 30 = 260
    expect(totalW).toBe(260);
    // totalH = max(100, 100+15, 50+15) + 12 = 115 + 12 = 127
    expect(totalH).toBe(127);
  });

  it("produces lane geoms that stack flush", () => {
    const nodes = [
      makeNode({ id: "a", x: 100, y: 30, w: 60, h: 30 }),
      makeNode({ id: "b", x: 100, y: 80, w: 60, h: 30 }),
    ];
    const lanes: LaneSpec[] = [
      { id: "top", label: "Plain", members: ["a"] },
      { id: "bot", label: "Monad", members: ["b"] },
    ];
    const ctx = buildContext(nodes, [], "LR", lanes);
    const { laneGeoms } = computeCanvasAndLanes(nodes, ctx, 500, 200);
    expect(laneGeoms).toHaveLength(2);
    // Lane bands should stack: top lane's bottom ≈ bottom lane's top
    const topBottom = laneGeoms[0].y + laneGeoms[0].h;
    const botTop = laneGeoms[1].y;
    expect(Math.abs(topBottom - botTop)).toBeLessThan(1);
    expect(laneGeoms[0].label).toBe("Plain");
    expect(laneGeoms[1].label).toBe("Monad");
  });
});

// ── straightenLaneEdges ─────────────────────────────────────────────────────

describe("straightenLaneEdges", () => {
  it("straightens same-lane action→action edges on shared y", () => {
    const a = makeNode({ id: "a", kind: "action", x: 50, y: 50, w: 40, h: 20 });
    const b = makeNode({ id: "b", kind: "action", x: 150, y: 50, w: 40, h: 20 });
    const edges: GEdge[] = [makeEdge({ from: "a", to: "b" })];
    const lanes: LaneSpec[] = [{ id: "L", members: ["a", "b"] }];
    const ctx = buildContext([a, b], edges, "LR", lanes);

    const edgePaths: (readonly (readonly [number, number])[])[] = [
      [[70, 50], [70, 30], [130, 30], [130, 50]],
    ];
    straightenLaneEdges(edges, edgePaths, ctx);
    // Should be simplified to a straight horizontal line
    expect(edgePaths[0]).toEqual([[70, 50], [130, 50]]);
  });

  it("does not straighten when nodes are at different y", () => {
    const a = makeNode({ id: "a", kind: "action", x: 50, y: 50, w: 40, h: 20 });
    const b = makeNode({ id: "b", kind: "action", x: 150, y: 80, w: 40, h: 20 });
    const edges: GEdge[] = [makeEdge({ from: "a", to: "b" })];
    const lanes: LaneSpec[] = [{ id: "L", members: ["a", "b"] }];
    const ctx = buildContext([a, b], edges, "LR", lanes);

    const original: [number, number][] = [[70, 50], [130, 80]];
    const edgePaths: (readonly (readonly [number, number])[])[] = [original];
    straightenLaneEdges(edges, edgePaths, ctx);
    expect(edgePaths[0]).toBe(original); // unchanged
  });

  it("rewrites cross-lane object→action as vertical drop", () => {
    const obj = makeNode({ id: "obj", kind: "object", x: 100, y: 30, w: 40, h: 20 });
    const act = makeNode({ id: "act", kind: "action", x: 100, y: 80, w: 60, h: 30 });
    const edges: GEdge[] = [makeEdge({ from: "obj", to: "act", isObjectFlow: true })];
    const lanes: LaneSpec[] = [
      { id: "top", members: ["obj"] },
      { id: "bot", members: ["act"] },
    ];
    const ctx = buildContext([obj, act], edges, "LR", lanes);

    const edgePaths: (readonly (readonly [number, number])[])[] = [
      [[100, 40], [80, 50], [80, 60], [100, 65]],
    ];
    straightenLaneEdges(edges, edgePaths, ctx);
    // Should be a clean vertical drop: [obj bottom] → [act top - PIN_SZ/2]
    // ty = act.y - act.h/2 - PIN_SZ/2 = 80 - 15 - 4 = 61
    expect(edgePaths[0]).toEqual([[100, 40], [100, 61]]);
  });
});

// ── adjustLanePositions ─────────────────────────────────────────────────────

describe("adjustLanePositions", () => {
  it("shifts top-lane members down by 8", () => {
    const a = makeNode({ id: "a", x: 50, y: 30, w: 40, h: 20 });
    const lanes: LaneSpec[] = [
      { id: "top", members: ["a"] },
      { id: "bot", members: [] },
    ];
    const ctx = buildContext([a], [], "LR", lanes);
    adjustLanePositions([a], [], ctx);
    expect(a.y).toBe(38); // 30 + 8
  });

  it("shifts lower-lane members down by 14", () => {
    const b = makeNode({ id: "b", x: 100, y: 80, w: 60, h: 30 });
    const lanes: LaneSpec[] = [
      { id: "top", members: [] },
      { id: "bot", members: ["b"] },
    ];
    const ctx = buildContext([b], [], "LR", lanes);
    adjustLanePositions([b], [], ctx);
    expect(b.y).toBe(94); // 80 + 14
  });

  it("aligns cross-lane object to single target action x", () => {
    const obj = makeNode({ id: "obj", kind: "object", x: 50, y: 30, w: 40, h: 20 });
    const act = makeNode({ id: "act", kind: "action", x: 150, y: 80, w: 60, h: 30 });
    const edges: GEdge[] = [makeEdge({ from: "obj", to: "act", isObjectFlow: true })];
    const lanes: LaneSpec[] = [
      { id: "top", members: ["obj"] },
      { id: "bot", members: ["act"] },
    ];
    const ctx = buildContext([obj, act], edges, "LR", lanes);
    adjustLanePositions([obj, act], edges, ctx);
    expect(obj.x).toBe(150); // aligned to action's x
  });
});
