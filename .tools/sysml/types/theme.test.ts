import { describe, expect, it } from "vitest";
import { theme, themeCss } from "./theme.ts";

type ColorName = keyof typeof theme.palette.light;

const textPairs: readonly [ColorName, ColorName][] = [
  ["labelFill", "canvas"],
  ["labelFill", "actionFill"],
  ["labelFill", "objFill"],
  ["hofStroke", "hofFill"],
  ["pinLabel", "pinFill"],
  ["portLabel", "canvas"],
  ["decisionLabel", "decisionFill"],
  ["noteLabel", "noteFill"],
  ["noteLabel", "noteFoldFill"],
  ["labelFill", "laneHeader"],
  ["labelFill", "frameTabFill"],
  ["secondaryText", "canvas"],
];

const graphicPairs: readonly [ColorName, ColorName][] = [
  ["actionStroke", "actionFill"],
  ["objStroke", "objFill"],
  ["hofStroke", "hofFill"],
  ["pinStroke", "pinFill"],
  ["frameStroke", "frameFill"],
  ["edgeStroke", "canvas"],
  ["hofEdge", "canvas"],
  ["decisionStroke", "decisionFill"],
  ["noteStroke", "noteFill"],
  ["laneStroke", "laneFill"],
  ["laneStroke", "laneHeader"],
];

function luminance(hex: string): number {
  const channels = [1, 3, 5].map(offset => Number.parseInt(hex.slice(offset, offset + 2), 16) / 255);
  const linear = channels.map(channel =>
    channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4,
  );
  const [red, green, blue] = linear;
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}

function contrast(foreground: string, background: string): number {
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  const [lighter, darker] = values;
  return (lighter + 0.05) / (darker + 0.05);
}

describe("diagram theme", () => {
  it.each([
    ["light", theme.palette.light],
    ["dark", theme.palette.dark],
  ] as const)("meets text and graphics contrast targets in %s mode", (mode, palette) => {
    for (const [foreground, background] of textPairs) {
      expect(
        contrast(palette[foreground], palette[background]),
        `${mode}: ${foreground} on ${background}`,
      ).toBeGreaterThanOrEqual(4.5);
    }

    for (const [foreground, background] of graphicPairs) {
      expect(
        contrast(palette[foreground], palette[background]),
        `${mode}: ${foreground} against ${background}`,
      ).toBeGreaterThanOrEqual(3);
    }
  });

  it("provides light and prefers-color-scheme dark SVG tokens", () => {
    expect(themeCss).toContain("@media (prefers-color-scheme: dark)");
    expect(themeCss).toContain("--fp-action-fill:");
    expect(themeCss).toContain("--fp-action-stroke:");
    expect(themeCss).toContain("--fp-lane-header:");
  });
});
