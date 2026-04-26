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
  COL, escXml,
} from "../types.ts";

// ── Action node ────────────────────────────────────────────────────────────

function renderActionNode(n: GNode): string {
  const tip  = n.tooltip ? `<title>${escXml(n.tooltip)}</title>` : "";
  const rx   = (n.x - n.w / 2).toFixed(1);
  const ry   = (n.y - n.h / 2).toFixed(1);
  const LH   = 13;
  const nameLines = n.label.split("\n");
  const textEls   = nameLines.map((l, i) =>
    `<text x="${n.x.toFixed(1)}" y="${(n.y + (i - (nameLines.length - 1) / 2) * LH).toFixed(1)}" text-anchor="middle" font-size="11" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(l)}</text>`
  ).join("\n    ");

  const inPinEls = n.inPins.map((p, i) => {
    const py = n.y - n.h / 2 + (n.h / (n.inPins.length + 1)) * (i + 1);
    const px = n.x - n.w / 2 - PIN_SZ / 2;
    // Label inside the node so arriving arrows don't cross it
    return `<rect x="${px.toFixed(1)}" y="${(py - PIN_SZ / 2).toFixed(1)}" width="${PIN_SZ}" height="${PIN_SZ}" fill="${COL.pinFill}" stroke="${COL.pinStroke}" stroke-width="1"/>
    <text x="${(px + PIN_SZ + 2).toFixed(1)}" y="${py.toFixed(1)}" text-anchor="start" font-size="8" font-family="sans-serif" dominant-baseline="middle" fill="#555" stroke="white" stroke-width="2" paint-order="stroke fill">${escXml(p)}</text>`;
  }).join("\n    ");

  const outPinEls = n.outPins.map((p, i) => {
    const py = n.y - n.h / 2 + (n.h / (n.outPins.length + 1)) * (i + 1);
    const px = n.x + n.w / 2 - PIN_SZ / 2;
    // Label inside the node so departing arrows don't cross it
    return `<rect x="${px.toFixed(1)}" y="${(py - PIN_SZ / 2).toFixed(1)}" width="${PIN_SZ}" height="${PIN_SZ}" fill="${COL.pinFill}" stroke="${COL.pinStroke}" stroke-width="1"/>
    <text x="${(px - 2).toFixed(1)}" y="${py.toFixed(1)}" text-anchor="end" font-size="8" font-family="sans-serif" dominant-baseline="middle" fill="#555" stroke="white" stroke-width="2" paint-order="stroke fill">${escXml(p)}</text>`;
  }).join("\n    ");

  return `  <g class="action-node">${tip}
    <rect x="${rx}" y="${ry}" width="${n.w}" height="${n.h}" rx="${ACTION_RX}" fill="${COL.actionFill}" stroke="${COL.actionStroke}" stroke-width="1.5"/>
    ${textEls}
    ${inPinEls}
    ${outPinEls}
  </g>`;
}

// ── Object node ────────────────────────────────────────────────────────────

function renderObjectNode(n: GNode): string {
  const tip    = n.tooltip ? `<title>${escXml(n.tooltip)}</title>` : "";
  const rx     = (n.x - n.w / 2).toFixed(1);
  const ry     = (n.y - n.h / 2).toFixed(1);
  const fill   = n.isHof ? COL.hofFill   : COL.objFill;
  const stroke = n.isHof ? COL.hofStroke : COL.objStroke;

  if (n.isHof) {
    return `  <g class="object-node hof">${tip}
    <rect x="${rx}" y="${ry}" width="${n.w}" height="${n.h}" fill="${fill}" stroke="${stroke}" stroke-width="1.5"/>
    <text x="${n.x.toFixed(1)}" y="${(n.y - 7).toFixed(1)}" text-anchor="middle" font-size="9" font-style="italic" font-family="sans-serif" dominant-baseline="middle" fill="${COL.hofStroke}">«function»</text>
    <text x="${n.x.toFixed(1)}" y="${(n.y + 7).toFixed(1)}" text-anchor="middle" font-size="11" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(n.label)}</text>
  </g>`;
  }
  return `  <g class="object-node">${tip}
    <rect x="${rx}" y="${ry}" width="${n.w}" height="${n.h}" fill="${fill}" stroke="${stroke}" stroke-width="1.5"/>
    <text x="${n.x.toFixed(1)}" y="${n.y.toFixed(1)}" text-anchor="middle" font-size="11" font-family="sans-serif" dominant-baseline="middle" fill="${COL.labelFill}">${escXml(n.label)}</text>
  </g>`;
}

// ── Initial / Final nodes ──────────────────────────────────────────────────

function renderInitialNode(n: GNode): string {
  return `  <g class="initial-node">
    <circle cx="${n.x.toFixed(1)}" cy="${n.y.toFixed(1)}" r="${INIT_R}" fill="${COL.initFill}"/>
  </g>`;
}

function renderFinalNode(n: GNode): string {
  return `  <g class="final-node">
    <circle cx="${n.x.toFixed(1)}" cy="${n.y.toFixed(1)}" r="${FINAL_R}" fill="none" stroke="${COL.finalStroke}" stroke-width="2"/>
    <circle cx="${n.x.toFixed(1)}" cy="${n.y.toFixed(1)}" r="${FINAL_R_INNER}" fill="${COL.finalFill}"/>
  </g>`;
}

// ── Decision / Merge diamond ───────────────────────────────────────────────

function renderDiamondNode(n: GNode): string {
  const tip = n.tooltip ? `<title>${escXml(n.tooltip)}</title>` : "";
  const hw  = n.w / 2;
  const hh  = n.h / 2;
  const pts = `${n.x.toFixed(1)},${(n.y - hh).toFixed(1)} ${(n.x + hw).toFixed(1)},${n.y.toFixed(1)} ${n.x.toFixed(1)},${(n.y + hh).toFixed(1)} ${(n.x - hw).toFixed(1)},${n.y.toFixed(1)}`;
  return `  <g class="${n.kind}-node">${tip}
    <polygon points="${pts}" fill="#fff9c4" stroke="#f9a825" stroke-width="1.5"/>
  </g>`;
}

// ── Dispatch ───────────────────────────────────────────────────────────────

/** Render any graph node to an SVG `<g>` element. */
export function renderGNode(n: GNode): string {
  switch (n.kind) {
    case "action":    return renderActionNode(n);
    case "object":    return renderObjectNode(n);
    case "initial":   return renderInitialNode(n);
    case "final":     return renderFinalNode(n);
    case "decision":  return renderDiamondNode(n);
    case "merge":     return renderDiamondNode(n);
    case "separator": return ""; // invisible layout-only spacer
  }
}
