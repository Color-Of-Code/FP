import { describe, it, expect } from "vitest";
import {
  shortenEnd,
  extendStart,
  polylineToD,
  roundedPolylineToD,
  labelAnchor,
  firstSegmentMidpoint,
} from "./edges.ts";

// ── shortenEnd ─────────────────────────────────────────────────────────────

describe("shortenEnd", () => {
  it("shortens a horizontal segment", () => {
    const pts: [number, number][] = [[0, 0], [10, 0]];
    const result = shortenEnd(pts, 3);
    expect(result).toEqual([[0, 0], [7, 0]]);
  });

  it("shortens a vertical segment", () => {
    const pts: [number, number][] = [[0, 0], [0, 20]];
    const result = shortenEnd(pts, 5);
    expect(result).toEqual([[0, 0], [0, 15]]);
  });

  it("returns single-point input unchanged", () => {
    const result = shortenEnd([[5, 5]], 3);
    expect(result).toEqual([[5, 5]]);
  });

  it("clamps depth to segment length", () => {
    const result = shortenEnd([[0, 0], [3, 0]], 10);
    expect(result[1][0]).toBe(0); // clamped, not negative
  });
});

// ── extendStart ────────────────────────────────────────────────────────────

describe("extendStart", () => {
  it("extends start backward along horizontal segment", () => {
    const pts: [number, number][] = [[10, 0], [20, 0]];
    const result = extendStart(pts, 5);
    expect(result[0]).toEqual([5, 0]);
    expect(result[1]).toEqual([20, 0]);
  });

  it("does nothing with zero depth", () => {
    const pts: [number, number][] = [[10, 0], [20, 0]];
    expect(extendStart(pts, 0)).toEqual(pts);
  });
});

// ── polylineToD ────────────────────────────────────────────────────────────

describe("polylineToD", () => {
  it("returns empty string for empty input", () => {
    expect(polylineToD([])).toBe("");
  });

  it("produces M...L path for multiple points", () => {
    const d = polylineToD([[0, 0], [10, 0], [10, 20]]);
    expect(d).toMatch(/^M0\.0,0\.0 L10\.0,0\.0 L10\.0,20\.0$/);
  });
});

// ── roundedPolylineToD ─────────────────────────────────────────────────────

describe("roundedPolylineToD", () => {
  it("falls back to polylineToD for ≤2 points", () => {
    expect(roundedPolylineToD([[0, 0], [10, 0]], 5)).toBe(polylineToD([[0, 0], [10, 0]]));
  });

  it("produces Q curves at corners", () => {
    const d = roundedPolylineToD([[0, 0], [10, 0], [10, 10]], 3);
    expect(d).toContain("Q");
    expect(d).toMatch(/^M/);
  });

  it("handles collinear points without curves", () => {
    const d = roundedPolylineToD([[0, 0], [5, 0], [10, 0]], 3);
    expect(d).not.toContain("Q");
  });
});

// ── labelAnchor ────────────────────────────────────────────────────────────

describe("labelAnchor", () => {
  it("returns [0,0] for fewer than 2 points", () => {
    expect(labelAnchor([[5, 5]])).toEqual([0, 0]);
  });

  it("returns midpoint of the longest segment", () => {
    // segment 0→10 is length 10, segment 10→12 is length 2
    const anchor = labelAnchor([[0, 0], [10, 0], [12, 0]]);
    expect(anchor).toEqual([5, 0]); // midpoint of longer segment
  });
});

// ── firstSegmentMidpoint ───────────────────────────────────────────────────

describe("firstSegmentMidpoint", () => {
  it("returns [0,0] for fewer than 2 points", () => {
    expect(firstSegmentMidpoint([[5, 5]])).toEqual([0, 0]);
  });

  it("returns midpoint of first segment", () => {
    expect(firstSegmentMidpoint([[0, 0], [10, 0], [10, 20]])).toEqual([5, 0]);
  });
});
