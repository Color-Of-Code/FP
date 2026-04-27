/**
 * Single source of truth for renderer dimensions and colours.
 *
 * The structured `theme` object groups related values so a future light/dark
 * variant or a print theme is a one-spot change.  Flat re-exports preserve
 * the existing `ACTION_W` / `COL.actionFill` style call sites in the
 * renderers — both views point at the same numbers.
 */

export const theme = {
  dims: {
    // Action / Object node geometry
    actionW:        120,
    actionH:        44,
    actionRx:       12,    // border-radius of action rect
    objectW:        110,
    objectH:        38,
    pinSz:          8,     // pin square side length

    // Control-flow node geometry
    initR:          8,     // initial-node circle radius
    finalR:         10,    // final-node outer circle radius
    finalRInner:    6,     // final-node inner (filled) circle radius
    decisionSz:     28,    // diamond bounding box (square rotated 45°)

    // Activity frame geometry
    framePad:       16,
    frameTabW:      200,
    frameTabH:      22,

    // Layout parameters
    edgeGap:        40,    // dagre ranksep
    nodeVgap:       14,    // dagre nodesep
    branchSepH:     60,    // separator height between decision branches

    /**
     * Rendered depth of the arrowhead in SVG user-space units.
     *
     * Markers use markerUnits="strokeWidth" (default), strokeWidth=1.5,
     * markerWidth=7, viewBox="0 0 10 10": scale = 7×1.5/10 = 1.05 u/unit.
     * Tip is at marker-x=10  → depth = 10 × 1.05 = 10.5.
     * Used with refX="0" so the tip lands exactly on the target boundary.
     */
    arrowDepth:     10.5,
  },
  colors: {
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
  },
} as const;

// ── Flat re-exports (backwards-compatible names) ────────────────────────────

export const COL = theme.colors;

export const ACTION_W      = theme.dims.actionW;
export const ACTION_H      = theme.dims.actionH;
export const ACTION_RX     = theme.dims.actionRx;
export const OBJECT_W      = theme.dims.objectW;
export const OBJECT_H      = theme.dims.objectH;
export const PIN_SZ        = theme.dims.pinSz;
export const INIT_R        = theme.dims.initR;
export const FINAL_R       = theme.dims.finalR;
export const FINAL_R_INNER = theme.dims.finalRInner;
export const DECISION_SZ   = theme.dims.decisionSz;
export const FRAME_PAD     = theme.dims.framePad;
export const FRAME_TAB_W   = theme.dims.frameTabW;
export const FRAME_TAB_H   = theme.dims.frameTabH;
export const EDGE_GAP      = theme.dims.edgeGap;
export const NODE_VGAP     = theme.dims.nodeVgap;
export const BRANCH_SEP_H  = theme.dims.branchSepH;
export const ARROW_DEPTH   = theme.dims.arrowDepth;
