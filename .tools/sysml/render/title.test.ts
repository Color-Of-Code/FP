import { describe, expect, it } from "vitest";
import { createSvgDocument } from "./title.ts";

describe("createSvgDocument", () => {
  it("scales diagram content when the title widens the canvas", () => {
    const doc = createSvgDocument("12345678901234567890", 100, 50);

    const svg = doc.serialize();

    expect(svg).toContain('viewBox="0 0 196 126"');
    expect(svg).toContain('width="196"');
    expect(svg).toContain('height="126"');
    expect(svg).toContain('transform="translate(0,28) scale(1.96)"');
  });
});