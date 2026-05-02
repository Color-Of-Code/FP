/**
 * SVG rendering for all graph node types.
 *
 *   action    — rounded rectangle with in/out pin squares
 *   object    — plain rectangle, optional «stereotype» line
 *   initial   — filled black circle
 *   final     — bull's-eye (outer circle + inner filled circle)
 *   decision  — yellow diamond (decision node)
 *   merge     — yellow diamond (merge node)
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

  // Group pins by their assigned side so each side distributes its own
  // pins independently (one pin alone on a side is centred; two on the
  // same side are spaced evenly).
  const groupBySide = (
    pins: string[],
    defaultSide: "N" | "S" | "E" | "W",
  ): Map<"N" | "S" | "E" | "W", { pin: string; idxInSide: number; total: number }[]> => {
    const out = new Map<"N" | "S" | "E" | "W", { pin: string; idxInSide: number; total: number }[]>();
    for (const p of pins) {
      const s = n.pinSides?.[p] ?? defaultSide;
      const list = out.get(s) ?? [];
      list.push({ pin: p, idxInSide: list.length, total: 0 });
      out.set(s, list);
    }
    for (const list of out.values()) {
      for (const e of list) e.total = list.length;
    }
    return out;
  };

  const inSideGroups  = groupBySide(n.inPins,  "W");
  const outSideGroups = groupBySide(n.outPins, "E");
  const lookupSide = <S extends "N" | "S" | "E" | "W">(
    groups: Map<S, { pin: string; idxInSide: number; total: number }[]>,
    pin: string,
  ): { i: number; total: number } => {
    for (const list of groups.values()) {
      const e = list.find(x => x.pin === pin);
      if (e) return { i: e.idxInSide, total: e.total };
    }
    return { i: 0, total: 1 };
  };

  joinGroups(group, "g.pin-in", n.inPins, (pinGroup, pin) => {
    const side = n.pinSides?.[pin] ?? "W";
    const { i, total } = lookupSide(inSideGroups as any, pin);
    let px: number, py: number;
    let labelAttrs: Record<string, string | number>;
    switch (side) {
      case "N": {
        const inset = (n.w / (total + 1)) * (i + 1);
        px = n.x - n.w / 2 + inset - PIN_SZ / 2;
        py = n.y - n.h / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px + PIN_SZ / 2,
          y: py - 2,
          "text-anchor": "middle",
          "dominant-baseline": "alphabetic",
        };
        break;
      }
      case "S": {
        const inset = (n.w / (total + 1)) * (i + 1);
        px = n.x - n.w / 2 + inset - PIN_SZ / 2;
        py = n.y + n.h / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px + PIN_SZ / 2,
          y: py + PIN_SZ + 2,
          "text-anchor": "middle",
          "dominant-baseline": "hanging",
        };
        break;
      }
      case "E": {
        py = n.y - n.h / 2 + (n.h / (total + 1)) * (i + 1) - PIN_SZ / 2;
        px = n.x + n.w / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px - 2,
          y: py + PIN_SZ / 2,
          "text-anchor": "end",
          "dominant-baseline": "middle",
        };
        break;
      }
      default: { // "W"
        py = n.y - n.h / 2 + (n.h / (total + 1)) * (i + 1) - PIN_SZ / 2;
        px = n.x - n.w / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px + PIN_SZ + 2,
          y: py + PIN_SZ / 2,
          "text-anchor": "start",
          "dominant-baseline": "middle",
        };
        break;
      }
    }
    setAttrs(pinGroup, { class: "pin pin-in" });
    appendElement(pinGroup, "rect", {
      x: px,
      y: py,
      width: PIN_SZ,
      height: PIN_SZ,
      fill: COL.pinFill,
      stroke: COL.pinStroke,
      "stroke-width": 1,
    });
    if (pin !== "_" && !n.hideInPinLabels) appendText(pinGroup, pin, {
      ...labelAttrs,
      "font-size": 8,
      "font-family": "sans-serif",
      fill: "#555",
    });
  });

  joinGroups(group, "g.pin-out", n.outPins, (pinGroup, pin) => {
    const side = n.pinSides?.[pin] ?? "E";
    const { i, total } = lookupSide(outSideGroups as any, pin);
    let px: number, py: number;
    let labelAttrs: Record<string, string | number>;
    switch (side) {
      case "N": {
        const inset = (n.w / (total + 1)) * (i + 1);
        px = n.x - n.w / 2 + inset - PIN_SZ / 2;
        py = n.y - n.h / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px + PIN_SZ / 2,
          y: py - 2,
          "text-anchor": "middle",
          "dominant-baseline": "alphabetic",
        };
        break;
      }
      case "S": {
        const inset = (n.w / (total + 1)) * (i + 1);
        px = n.x - n.w / 2 + inset - PIN_SZ / 2;
        py = n.y + n.h / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px + PIN_SZ / 2,
          y: py + PIN_SZ + 2,
          "text-anchor": "middle",
          "dominant-baseline": "hanging",
        };
        break;
      }
      case "W": {
        py = n.y - n.h / 2 + (n.h / (total + 1)) * (i + 1) - PIN_SZ / 2;
        px = n.x - n.w / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px + PIN_SZ + 2,
          y: py + PIN_SZ / 2,
          "text-anchor": "start",
          "dominant-baseline": "middle",
        };
        break;
      }
      default: { // "E"
        py = n.y - n.h / 2 + (n.h / (total + 1)) * (i + 1) - PIN_SZ / 2;
        px = n.x + n.w / 2 - PIN_SZ / 2;
        labelAttrs = {
          x: px - 2,
          y: py + PIN_SZ / 2,
          "text-anchor": "end",
          "dominant-baseline": "middle",
        };
        break;
      }
    }
    setAttrs(pinGroup, { class: "pin pin-out" });
    appendElement(pinGroup, "rect", {
      x: px,
      y: py,
      width: PIN_SZ,
      height: PIN_SZ,
      fill: COL.pinFill,
      stroke: COL.pinStroke,
      "stroke-width": 1,
    });
    if (pin !== "_") appendText(pinGroup, pin, {
      ...labelAttrs,
      "font-size": 8,
      "font-family": "sans-serif",
      fill: "#555",
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
    case "note":      appendNoteNode(parent, n); return;
  }
}

// ── Note node ─────────────────────────────────────────────────────────────
// UML-style: a rectangle with the top-right corner folded over.  The fold is
// a small square at the top-right; the body is a 5-point polygon following
// the outline minus that corner.

function appendNoteNode(parent: SvgParent, n: GNode): void {
  const FOLD = 10;
  const x0 = n.x - n.w / 2;
  const y0 = n.y - n.h / 2;
  const x1 = n.x + n.w / 2;
  const y1 = n.y + n.h / 2;

  const group = appendGroup(parent, { class: "note-node" }, n.tooltip);

  // Body polygon: top-left → just before fold → fold corner down → top-right of fold → bottom-right → bottom-left.
  const bodyPts =
    `${x0},${y0} ${x1 - FOLD},${y0} ${x1},${y0 + FOLD} ${x1},${y1} ${x0},${y1}`;
  appendElement(group, "polygon", {
    points: bodyPts,
    fill: "#fffde7",
    stroke: "#fbc02d",
    "stroke-width": 1.25,
  });

  // The folded corner triangle: top-right cut, slightly darker fill.
  const foldPts =
    `${x1 - FOLD},${y0} ${x1 - FOLD},${y0 + FOLD} ${x1},${y0 + FOLD}`;
  appendElement(group, "polygon", {
    points: foldPts,
    fill: "#fff59d",
    stroke: "#fbc02d",
    "stroke-width": 1.25,
  });

  const lines = n.noteLines ?? [n.label];
  const LH = 14;
  const totalH = lines.length * LH;
  const startY = n.y - totalH / 2 + LH * 0.7;
  lines.forEach((line, i) => {
    appendText(group, line, {
      x: n.x,
      y: startY + i * LH,
      "text-anchor": "middle",
      "font-size": 10,
      "font-family": "sans-serif",
      "dominant-baseline": "middle",
      fill: "#5d4037",
    });
  });
}
