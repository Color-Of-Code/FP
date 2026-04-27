/**
 * SVG rendering for all graph node types.
 *
 *   action    — rounded rectangle with in/out pin squares
 *   object    — plain rectangle, optional «stereotype» line
 *   initial   — filled black circle
 *   final     — bull's-eye (outer circle + inner filled circle)
 *   decision  — yellow diamond (decision node)
 *   merge     — yellow diamond (merge node)
 *   separator — invisible layout-only spacer (renders nothing)
 */

import {
  type GNode,
  ACTION_RX, PIN_SZ,
  INIT_R, FINAL_R, FINAL_R_INNER,
  COL,
} from "../types.ts";
import {
  appendElement,
  appendGroup,
  appendText,
  joinElements,
  joinGroups,
  setAttrs,
  type SvgParent,
} from "../lib/svg.ts";

// ── Action node ────────────────────────────────────────────────────────────

function appendActionNode(parent: SvgParent, n: GNode): void {
  const rx   = n.x - n.w / 2;
  const ry   = n.y - n.h / 2;
  const LH   = 13;
  const nameLines = n.label.split("\n");
  const group = appendGroup(parent, { class: "action-node" }, n.tooltip);

  appendElement(group, "rect", {
    x: rx,
    y: ry,
    width: n.w,
    height: n.h,
    rx: ACTION_RX,
    fill: COL.actionFill,
    stroke: COL.actionStroke,
    "stroke-width": 1.5,
  });

  joinElements(group, "text.action-label", "text", nameLines, (textEl, line, i) => {
    setAttrs(textEl, {
      class: "action-label",
      x: n.x,
      y: n.y + (i - (nameLines.length - 1) / 2) * LH,
      "text-anchor": "middle",
      "font-size": 11,
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: COL.labelFill,
    });
    textEl.text(line);
  });

  joinGroups(group, "g.pin-in", n.inPins, (pinGroup, pin, i) => {
    const py = n.y - n.h / 2 + (n.h / (n.inPins.length + 1)) * (i + 1);
    const px = n.x - n.w / 2 - PIN_SZ / 2;
    // Label inside the node so arriving arrows don't cross it
    setAttrs(pinGroup, { class: "pin pin-in" });
    appendElement(pinGroup, "rect", {
      x: px,
      y: py - PIN_SZ / 2,
      width: PIN_SZ,
      height: PIN_SZ,
      fill: COL.pinFill,
      stroke: COL.pinStroke,
      "stroke-width": 1,
    });
    appendText(pinGroup, pin, {
      x: px + PIN_SZ + 2,
      y: py,
      "text-anchor": "start",
      "font-size": 8,
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: "#555",
      stroke: "white",
      "stroke-width": 2,
      "paint-order": "stroke fill",
    });
  });

  joinGroups(group, "g.pin-out", n.outPins, (pinGroup, pin, i) => {
    const py = n.y - n.h / 2 + (n.h / (n.outPins.length + 1)) * (i + 1);
    const px = n.x + n.w / 2 - PIN_SZ / 2;
    // Label inside the node so departing arrows don't cross it
    setAttrs(pinGroup, { class: "pin pin-out" });
    appendElement(pinGroup, "rect", {
      x: px,
      y: py - PIN_SZ / 2,
      width: PIN_SZ,
      height: PIN_SZ,
      fill: COL.pinFill,
      stroke: COL.pinStroke,
      "stroke-width": 1,
    });
    appendText(pinGroup, pin, {
      x: px - 2,
      y: py,
      "text-anchor": "end",
      "font-size": 8,
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: "#555",
      stroke: "white",
      "stroke-width": 2,
      "paint-order": "stroke fill",
    });
  });
}

// ── Object node ────────────────────────────────────────────────────────────

function appendObjectNode(parent: SvgParent, n: GNode): void {
  const rx     = n.x - n.w / 2;
  const ry     = n.y - n.h / 2;
  const fill   = n.isHof ? COL.hofFill   : COL.objFill;
  const stroke = n.isHof ? COL.hofStroke : COL.objStroke;
  const classes = n.isHof ? "object-node hof" : "object-node";
  const group = appendGroup(parent, { class: classes }, n.tooltip);

  appendElement(group, "rect", {
    x: rx,
    y: ry,
    width: n.w,
    height: n.h,
    fill,
    stroke,
    "stroke-width": 1.5,
  });

  if (n.isHof) {
    appendText(group, "«function»", {
      x: n.x,
      y: n.y - 7,
      "text-anchor": "middle",
      "font-size": 9,
      "font-style": "italic",
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: COL.hofStroke,
    });
    appendText(group, n.label, {
      x: n.x,
      y: n.y + 7,
      "text-anchor": "middle",
      "font-size": 11,
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: COL.labelFill,
    });
    return;
  }

  appendText(group, n.label, {
    x: n.x,
    y: n.y,
    "text-anchor": "middle",
    "font-size": 11,
    "font-family": "sans-serif",
    "dominant-baseline": "middle",
    fill: COL.labelFill,
  });
}

// ── Initial / Final nodes ──────────────────────────────────────────────────

function appendInitialNode(parent: SvgParent, n: GNode): void {
  const group = appendGroup(parent, { class: "initial-node" });
  appendElement(group, "circle", { cx: n.x, cy: n.y, r: INIT_R, fill: COL.initFill });
}

function appendFinalNode(parent: SvgParent, n: GNode): void {
  const group = appendGroup(parent, { class: "final-node" });
  appendElement(group, "circle", {
    cx: n.x,
    cy: n.y,
    r: FINAL_R,
    fill: "none",
    stroke: COL.finalStroke,
    "stroke-width": 2,
  });
  appendElement(group, "circle", {
    cx: n.x,
    cy: n.y,
    r: FINAL_R_INNER,
    fill: COL.finalFill,
  });
}

// ── Decision / Merge diamond ───────────────────────────────────────────────

function appendDiamondNode(parent: SvgParent, n: GNode): void {
  const hw  = n.w / 2;
  const hh  = n.h / 2;
  const pts = `${n.x},${n.y - hh} ${n.x + hw},${n.y} ${n.x},${n.y + hh} ${n.x - hw},${n.y}`;
  const group = appendGroup(parent, { class: `${n.kind}-node` }, n.tooltip);
  appendElement(group, "polygon", {
    points: pts,
    fill: "#fff9c4",
    stroke: "#f9a825",
    "stroke-width": 1.5,
  });
  if (n.label) {
    appendText(group, n.label, {
      x: n.x,
      y: n.y,
      "text-anchor": "middle",
      "font-size": 9,
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: "#5d4037",
    });
  }
}

// ── Dispatch ───────────────────────────────────────────────────────────────

/** Append any graph node as an SVG `<g>` element. */
export function appendGNode(parent: SvgParent, n: GNode): void {
  switch (n.kind) {
    case "action":    appendActionNode(parent, n); return;
    case "object":    appendObjectNode(parent, n); return;
    case "initial":   appendInitialNode(parent, n); return;
    case "final":     appendFinalNode(parent, n); return;
    case "decision":  appendDiamondNode(parent, n); return;
    case "merge":     appendDiamondNode(parent, n); return;
    case "separator": return; // invisible layout-only spacer
  }
}
