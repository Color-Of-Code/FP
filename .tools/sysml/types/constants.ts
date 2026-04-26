/**
 * Numeric dimension constants shared by the layout engine and all renderers.
 * No imports — this module is a pure value leaf.
 */

// ── Action / Object node geometry ─────────────────────────────────────────
export const ACTION_W        = 120;
export const ACTION_H        = 44;
export const ACTION_RX       = 12;   // border-radius of action rect
export const OBJECT_W        = 110;
export const OBJECT_H        = 38;
export const PIN_SZ          = 8;    // pin square side length

// ── Control-flow node geometry ─────────────────────────────────────────────
export const INIT_R          = 8;    // initial-node circle radius
export const FINAL_R         = 10;   // final-node outer circle radius
export const FINAL_R_INNER   = 6;    // final-node inner (filled) circle radius
export const DECISION_SZ     = 28;   // diamond bounding box (square rotated 45°)

// ── Activity frame geometry ────────────────────────────────────────────────
export const FRAME_PAD       = 16;
export const FRAME_TAB_W     = 200;
export const FRAME_TAB_H     = 22;

// ── Layout parameters ──────────────────────────────────────────────────────
export const EDGE_GAP        = 40;   // dagre ranksep
export const NODE_VGAP       = 14;   // dagre nodesep

/**
 * Height of the invisible separator node injected between decision branches.
 * Forces dagre to spread branches far enough apart that edges don't overlap.
 */
export const BRANCH_SEP_H    = 60;

/**
 * Rendered depth of the arrowhead in SVG user-space units.
 *
 * Markers use markerUnits="strokeWidth" (default), strokeWidth=1.5,
 * markerWidth=7, viewBox="0 0 10 10": scale = 7×1.5/10 = 1.05 u/unit.
 * Tip is at marker-x=10  → depth = 10 × 1.05 = 10.5.
 * Used with refX="0" so the visual tip lands exactly on the target boundary.
 */
export const ARROW_DEPTH     = 10.5;
