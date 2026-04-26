/**
 * SVG colour palette and XML-escape utility.
 * No imports — this module is a pure value leaf.
 */

// ── Colour palette ─────────────────────────────────────────────────────────
export const COL = {
  actionFill:  "#e8f5e9", actionStroke:  "#388e3c",
  objFill:     "#f5f5f5", objStroke:     "#616161",
  hofFill:     "#e0f2f1", hofStroke:     "#00796b",
  pinFill:     "#e0e0e0", pinStroke:     "#424242",
  frameFill:   "#fafafa", frameStroke:   "#9e9e9e",
  initFill:    "#212121",
  finalStroke: "#212121", finalFill:     "#212121",
  edgeStroke:  "#424242",
  hofEdge:     "#00796b",
  labelFill:   "#333",
};

// ── Utilities ──────────────────────────────────────────────────────────────

/** Escape a string for safe embedding in SVG/XML text content or attributes. */
export function escXml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
