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

  it("adds accessible labels and a transparent light/dark theme", () => {
    const svg = createSvgDocument("Diagram title", 100, 50).serialize();

    expect(svg).toContain('role="img"');
    expect(svg).toContain('aria-labelledby="diagram-title diagram-description"');
    expect(svg).toContain("<title id=\"diagram-title\">Diagram title</title>");
    expect(svg).toContain("<desc id=\"diagram-description\">Functional programming diagram: Diagram title</desc>");
    expect(svg).toContain("@media (prefers-color-scheme: dark)");
    expect(svg).not.toContain('fill="white"');
  });
});