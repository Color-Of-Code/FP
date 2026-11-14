/** Shared geometry, palette, and SVG presentation defaults. */

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

    // Diagram frame geometry
    framePad:       6,
    frameTabW:      200,
    frameTabH:      22,

    // Layout parameters (ELK)
    edgeGap:        16,    // ELK spacing.nodeNodeBetweenLayers (minimum; layers with labels grow as needed)
    nodeVgap:       14,    // ELK spacing.nodeNode

    /**
     * Rendered depth of the arrowhead in SVG user-space units.
     *
     * Markers use markerUnits="strokeWidth" (default), strokeWidth=1.5,
     * markerWidth=8, viewBox="0 0 10 10": scale = 8×1.5/10 = 1.2 u/unit.
     * Tip is at marker-x=10  → depth = 10 × 1.2 = 12.
     * Used with refX="0" so the tip lands exactly on the target boundary.
     */
    arrowDepth:     12,
  },
  palette: {
    light: {
      canvas: "#ffffff",
      actionFill: "#dafbe1",
      actionStroke: "#1a7f37",
      objFill: "#f6f8fa",
      objStroke: "#57606a",
      hofFill: "#ddf4ff",
      hofStroke: "#0969da",
      pinFill: "#eaeef2",
      pinStroke: "#57606a",
      frameFill: "#ffffff",
      frameStroke: "#6e7781",
      frameTabFill: "#eaeef2",
      initFill: "#24292f",
      finalStroke: "#24292f",
      finalFill: "#24292f",
      edgeStroke: "#57606a",
      hofEdge: "#0969da",
      labelFill: "#24292f",
      secondaryText: "#57606a",
      pinLabel: "#57606a",
      portLabel: "#57606a",
      decisionFill: "#fff8c5",
      decisionStroke: "#9a6700",
      decisionLabel: "#633c01",
      noteFill: "#fff8c5",
      noteFoldFill: "#ffdf5d",
      noteStroke: "#9a6700",
      noteLabel: "#633c01",
      laneFill: "#f6f8fa",
      laneStroke: "#6e7781",
      laneHeader: "#eaeef2",
      errorText: "#cf222e",
    },
    dark: {
      canvas: "#0d1117",
      actionFill: "#0f2d1f",
      actionStroke: "#3fb950",
      objFill: "#161b22",
      objStroke: "#8b949e",
      hofFill: "#082f49",
      hofStroke: "#79c0ff",
      pinFill: "#30363d",
      pinStroke: "#8b949e",
      frameFill: "#0d1117",
      frameStroke: "#6e7681",
      frameTabFill: "#21262d",
      initFill: "#e6edf3",
      finalStroke: "#e6edf3",
      finalFill: "#e6edf3",
      edgeStroke: "#8b949e",
      hofEdge: "#79c0ff",
      labelFill: "#e6edf3",
      secondaryText: "#9198a1",
      pinLabel: "#c9d1d9",
      portLabel: "#c9d1d9",
      decisionFill: "#3d2c00",
      decisionStroke: "#d29922",
      decisionLabel: "#f0c674",
      noteFill: "#3d2c00",
      noteFoldFill: "#573a00",
      noteStroke: "#d29922",
      noteLabel: "#f0c674",
      laneFill: "#161b22",
      laneStroke: "#6e7681",
      laneHeader: "#21262d",
      errorText: "#ff7b72",
    },
  },
  dashes: {
    controlFlow: "6,4",
    noteAttachment: "3,3",
  },
  a11y: {
    role: "img",
    titleId: "diagram-title",
    descriptionId: "diagram-description",
    descriptionPrefix: "Functional programming diagram: ",
  },
} as const;

type Palette = typeof theme.palette.light;
type ColorName = keyof Palette;

const cssVariableName = (name: string): string =>
  `--fp-${name.replace(/[A-Z]/g, letter => `-${letter.toLowerCase()}`)}`;

const cssVariables = (palette: Palette): string =>
  Object.entries(palette)
    .map(([name, value]) => `  ${cssVariableName(name)}: ${value};`)
    .join("\n");

export const themeCss = `:root {
  color-scheme: light;
${cssVariables(theme.palette.light)}
}
@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
${cssVariables(theme.palette.dark)}
  }
}`;

const color = (name: ColorName): string => `var(${cssVariableName(name)})`;

export const COL = {
  actionFill: color("actionFill"),
  actionStroke: color("actionStroke"),
  objFill: color("objFill"),
  objStroke: color("objStroke"),
  hofFill: color("hofFill"),
  hofStroke: color("hofStroke"),
  pinFill: color("pinFill"),
  pinStroke: color("pinStroke"),
  frameFill: color("frameFill"),
  frameStroke: color("frameStroke"),
  frameTabFill: color("frameTabFill"),
  initFill: color("initFill"),
  finalStroke: color("finalStroke"),
  finalFill: color("finalFill"),
  edgeStroke: color("edgeStroke"),
  hofEdge: color("hofEdge"),
  labelFill: color("labelFill"),
  secondaryText: color("secondaryText"),
  pinLabel: color("pinLabel"),
  portLabel: color("portLabel"),
  decisionFill: color("decisionFill"),
  decisionStroke: color("decisionStroke"),
  decisionLabel: color("decisionLabel"),
  noteFill: color("noteFill"),
  noteFoldFill: color("noteFoldFill"),
  noteStroke: color("noteStroke"),
  noteLabel: color("noteLabel"),
  laneFill: color("laneFill"),
  laneStroke: color("laneStroke"),
  laneHeader: color("laneHeader"),
  errorText: color("errorText"),
} as const;

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
export const ARROW_DEPTH   = theme.dims.arrowDepth;
