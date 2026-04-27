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
import type { SvgParent } from "./title.ts";

function appendTooltip(group: SvgParent, tooltip?: string): void {
  if (tooltip) group.append("title").text(tooltip);
}

// ── Action node ────────────────────────────────────────────────────────────

function appendActionNode(parent: SvgParent, n: GNode): void {
  const rx   = n.x - n.w / 2;
  const ry   = n.y - n.h / 2;
  const LH   = 13;
  const nameLines = n.label.split("\n");
  const group = parent.append("g")
    .attr("class", "action-node");
  appendTooltip(group, n.tooltip);

  group.append("rect")
    .attr("x", rx)
    .attr("y", ry)
    .attr("width", n.w)
    .attr("height", n.h)
    .attr("rx", ACTION_RX)
    .attr("fill", COL.actionFill)
    .attr("stroke", COL.actionStroke)
    .attr("stroke-width", 1.5);

  for (const [i, line] of nameLines.entries()) {
    group.append("text")
      .attr("x", n.x)
      .attr("y", n.y + (i - (nameLines.length - 1) / 2) * LH)
      .attr("text-anchor", "middle")
      .attr("font-size", 11)
      .attr("font-family", "sans-serif")
      .attr("dominant-baseline", "middle")
      .attr("fill", COL.labelFill)
      .text(line);
  }

  for (const [i, pin] of n.inPins.entries()) {
    const py = n.y - n.h / 2 + (n.h / (n.inPins.length + 1)) * (i + 1);
    const px = n.x - n.w / 2 - PIN_SZ / 2;
    // Label inside the node so arriving arrows don't cross it
    group.append("rect")
      .attr("x", px)
      .attr("y", py - PIN_SZ / 2)
      .attr("width", PIN_SZ)
      .attr("height", PIN_SZ)
      .attr("fill", COL.pinFill)
      .attr("stroke", COL.pinStroke)
      .attr("stroke-width", 1);
    group.append("text")
      .attr("x", px + PIN_SZ + 2)
      .attr("y", py)
      .attr("text-anchor", "start")
      .attr("font-size", 8)
      .attr("font-family", "sans-serif")
      .attr("dominant-baseline", "middle")
      .attr("fill", "#555")
      .attr("stroke", "white")
      .attr("stroke-width", 2)
      .attr("paint-order", "stroke fill")
      .text(pin);
  }

  for (const [i, pin] of n.outPins.entries()) {
    const py = n.y - n.h / 2 + (n.h / (n.outPins.length + 1)) * (i + 1);
    const px = n.x + n.w / 2 - PIN_SZ / 2;
    // Label inside the node so departing arrows don't cross it
    group.append("rect")
      .attr("x", px)
      .attr("y", py - PIN_SZ / 2)
      .attr("width", PIN_SZ)
      .attr("height", PIN_SZ)
      .attr("fill", COL.pinFill)
      .attr("stroke", COL.pinStroke)
      .attr("stroke-width", 1);
    group.append("text")
      .attr("x", px - 2)
      .attr("y", py)
      .attr("text-anchor", "end")
      .attr("font-size", 8)
      .attr("font-family", "sans-serif")
      .attr("dominant-baseline", "middle")
      .attr("fill", "#555")
      .attr("stroke", "white")
      .attr("stroke-width", 2)
      .attr("paint-order", "stroke fill")
      .text(pin);
  }
}

// ── Object node ────────────────────────────────────────────────────────────

function appendObjectNode(parent: SvgParent, n: GNode): void {
  const rx     = n.x - n.w / 2;
  const ry     = n.y - n.h / 2;
  const fill   = n.isHof ? COL.hofFill   : COL.objFill;
  const stroke = n.isHof ? COL.hofStroke : COL.objStroke;
  const classes = n.isHof ? "object-node hof" : "object-node";
  const group = parent.append("g")
    .attr("class", classes);
  appendTooltip(group, n.tooltip);

  group.append("rect")
    .attr("x", rx)
    .attr("y", ry)
    .attr("width", n.w)
    .attr("height", n.h)
    .attr("fill", fill)
    .attr("stroke", stroke)
    .attr("stroke-width", 1.5);

  if (n.isHof) {
    group.append("text")
      .attr("x", n.x)
      .attr("y", n.y - 7)
      .attr("text-anchor", "middle")
      .attr("font-size", 9)
      .attr("font-style", "italic")
      .attr("font-family", "sans-serif")
      .attr("dominant-baseline", "middle")
      .attr("fill", COL.hofStroke)
      .text("«function»");
    group.append("text")
      .attr("x", n.x)
      .attr("y", n.y + 7)
      .attr("text-anchor", "middle")
      .attr("font-size", 11)
      .attr("font-family", "sans-serif")
      .attr("dominant-baseline", "middle")
      .attr("fill", COL.labelFill)
      .text(n.label);
    return;
  }

  group.append("text")
    .attr("x", n.x)
    .attr("y", n.y)
    .attr("text-anchor", "middle")
    .attr("font-size", 11)
    .attr("font-family", "sans-serif")
    .attr("dominant-baseline", "middle")
    .attr("fill", COL.labelFill)
    .text(n.label);
}

// ── Initial / Final nodes ──────────────────────────────────────────────────

function appendInitialNode(parent: SvgParent, n: GNode): void {
  parent.append("g")
    .attr("class", "initial-node")
    .append("circle")
    .attr("cx", n.x)
    .attr("cy", n.y)
    .attr("r", INIT_R)
    .attr("fill", COL.initFill);
}

function appendFinalNode(parent: SvgParent, n: GNode): void {
  const group = parent.append("g")
    .attr("class", "final-node");
  group.append("circle")
    .attr("cx", n.x)
    .attr("cy", n.y)
    .attr("r", FINAL_R)
    .attr("fill", "none")
    .attr("stroke", COL.finalStroke)
    .attr("stroke-width", 2);
  group.append("circle")
    .attr("cx", n.x)
    .attr("cy", n.y)
    .attr("r", FINAL_R_INNER)
    .attr("fill", COL.finalFill);
}

// ── Decision / Merge diamond ───────────────────────────────────────────────

function appendDiamondNode(parent: SvgParent, n: GNode): void {
  const hw  = n.w / 2;
  const hh  = n.h / 2;
  const pts = `${n.x},${n.y - hh} ${n.x + hw},${n.y} ${n.x},${n.y + hh} ${n.x - hw},${n.y}`;
  const group = parent.append("g")
    .attr("class", `${n.kind}-node`);
  appendTooltip(group, n.tooltip);
  group.append("polygon")
    .attr("points", pts)
    .attr("fill", "#fff9c4")
    .attr("stroke", "#f9a825")
    .attr("stroke-width", 1.5);
  if (n.label) {
    group.append("text")
      .attr("x", n.x)
      .attr("y", n.y)
      .attr("text-anchor", "middle")
      .attr("font-size", 9)
      .attr("font-family", "sans-serif")
      .attr("dominant-baseline", "middle")
      .attr("fill", "#5d4037")
      .text(n.label);
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
