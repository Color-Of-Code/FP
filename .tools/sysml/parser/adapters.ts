/**
 * AST adapters — transform Langium-generated AST nodes into the
 * renderer-facing types defined in `../types/ast.ts`.
 *
 * Public surface:
 *   strOrIdent, optionalStrOrIdent  — string normalisation helpers
 *   adaptPackage, adaptDiagramMeta  — top-level adapters (called by parser.ts)
 */

import * as G from "../generated/ast.ts";
import { fromPairs } from "../lib/fp.ts";
import type {
  Role, DiagramType,
  PortDef, PortUsage, PartUsage, ConnectionUsage,
  PartDef, ActionDef, ActionUsage, ObjectNode,
  DecisionNode, MergeNode, FlowUsage, SuccessionUsage,
  NoteUsage, LaneBlock,
  ActivityDef, PackageDecl, DiagramMeta,
} from "../types.ts";

// ── String helpers ──────────────────────────────────────────────────────────

const stripQuotes = (s: string | undefined): string =>
  s?.startsWith('"') ? s.slice(1, -1).replace(/\\"/g, '"') : (s ?? "");

/** Normalise a `StrOrIdent` value (quoted string or bare identifier) to plain text. */
export const strOrIdent: (value: string | undefined) => string = stripQuotes;

/**
 * `strOrIdent` with an optional fallback when the input is `undefined`.
 * Replaces the repetitive `x !== undefined ? strOrIdent(x) : fallback` pattern.
 */
export function optionalStrOrIdent(value: string | undefined, fallback?: string): string | undefined {
  return value !== undefined ? strOrIdent(value) : fallback;
}

// ── Port-like adapter (shared by InlinePort & PinDecl) ──────────────────────

interface PortLikeNode { id?: string; type?: string; direction?: G.Direction }

function adaptPortLike(g: PortLikeNode): PortUsage {
  const id = g.id ?? "";
  return {
    kind: "port",
    id,
    type: optionalStrOrIdent(g.type, id) ?? id,
    direction: g.direction,
  };
}

// ── Individual adapters ─────────────────────────────────────────────────────

function adaptPortDef(g: G.PortDef): PortDef {
  return { kind: "portDef", name: g.name ?? "" };
}

function adaptPartUsage(g: G.PartUsage): PartUsage {
  const id = g.id ?? "";
  return {
    kind: "part",
    id,
    type: optionalStrOrIdent(g.type, id) ?? id,
    ports: g.ports.map(adaptPortLike),
  };
}

function adaptConnection(g: G.ConnectionUsage): ConnectionUsage {
  return {
    kind: "connection",
    id:    g.cid ?? undefined,
    from:  g.from ?? "",
    to:    g.to ?? "",
    via:   g.via ?? undefined,
    label: optionalStrOrIdent(g.label),
  };
}

function adaptNote(g: G.NoteUsage): NoteUsage {
  return {
    kind:   "note",
    id:     g.id ?? "",
    target: g.target ?? "",
    text:   strOrIdent(g.text),
  };
}

function adaptActionDef(g: G.ActionDef): ActionDef {
  return {
    kind: "actionDef",
    name: g.name ?? "",
    pins: g.pins.map(adaptPortLike),
  };
}

function adaptActionUsage(g: G.ActionUsage): ActionUsage {
  const id = g.id ?? "";
  return { kind: "action", id, type: optionalStrOrIdent(g.type, id) ?? id };
}

function adaptObjectNode(g: G.ObjectNode): ObjectNode {
  const id = g.id ?? "";
  return { kind: "object", id, type: optionalStrOrIdent(g.type) };
}

function adaptDecisionNode(g: G.DecisionNode): DecisionNode {
  return {
    kind:  "decision",
    id:    g.id ?? "",
    label: optionalStrOrIdent(g.label),
  };
}

function adaptMergeNode(g: G.MergeNode): MergeNode {
  return {
    kind:  "merge",
    id:    g.id ?? "",
    label: optionalStrOrIdent(g.label),
  };
}

function adaptFlowUsage(g: G.FlowUsage): FlowUsage {
  return {
    kind:  "flow",
    from:  g.from ?? "",
    to:    g.to ?? "",
    label: optionalStrOrIdent(g.label),
  };
}

function adaptSuccession(g: G.SuccessionUsage): SuccessionUsage {
  return { kind: "succession", from: g.from ?? "", to: g.to ?? "" };
}

function adaptLaneBlock(g: G.LaneBlock): LaneBlock {
  return {
    kind:    "lane",
    id:      g.id ?? "",
    label:   optionalStrOrIdent(g.label),
    members: (g.members ?? []).map(strOrIdent),
  };
}

// ── Partition helpers ───────────────────────────────────────────────────────

/**
 * A dispatch table entry: a type guard paired with its adapter function.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any -- type erasure needed for heterogeneous dispatch
type DispatchEntry<M, T> = readonly [(m: M) => m is M & object, (m: any) => T];

/**
 * Partition an array of union-typed members into categorised arrays using
 * a table of type-guard → adapter pairs.  Each member is matched against
 * the guards in order; the first match wins.  Unmatched members are silently
 * ignored (Langium unions can contain future node types).
 *
 * Returns a tuple of arrays in the same order as the dispatch entries.
 */
function partitionByKind<M, R extends readonly DispatchEntry<M, unknown>[]>(
  members: readonly M[],
  ...dispatch: R
): { [K in keyof R]: R[K] extends DispatchEntry<M, infer T> ? T[] : never } {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any -- mapped-tuple cast unavoidable
  const result = dispatch.map(() => [] as unknown[]) as any;
  members.forEach(m => {
    const idx = dispatch.findIndex(d => d[0](m));
    if (idx >= 0) result[idx].push(dispatch[idx][1](m));
  });
  return result;
}

// ── Composite adapters ──────────────────────────────────────────────────────

function adaptPartDef(g: G.PartDef): PartDef {
  const [parts, ports, connections, notes] = partitionByKind(
    g.members,
    [G.isPartUsage,      adaptPartUsage],
    [G.isInlinePort,     adaptPortLike],
    [G.isConnectionUsage, adaptConnection],
    [G.isNoteUsage,      adaptNote],
  );
  return { kind: "partDef", name: g.name ?? "", parts, ports, connections, notes };
}

function adaptActivityDef(g: G.ActivityDef): ActivityDef {
  const [actions, objects, decisions, merges, flows, successions, notes, lanes] =
    partitionByKind(
      g.members,
      [G.isActionUsage,     adaptActionUsage],
      [G.isObjectNode,      adaptObjectNode],
      [G.isDecisionNode,    adaptDecisionNode],
      [G.isMergeNode,       adaptMergeNode],
      [G.isFlowUsage,       adaptFlowUsage],
      [G.isSuccessionUsage, adaptSuccession],
      [G.isNoteUsage,       adaptNote],
      [G.isLaneBlock,       adaptLaneBlock],
    );
  return {
    kind: "activityDef",
    name: g.name ?? "",
    actions, objects, decisions, merges, flows, successions, notes, lanes,
  };
}

export function adaptPackage(g: G.Package): PackageDecl {
  const [portDefs, partDefs, actionDefs, activityDefs] = partitionByKind(
    g.members,
    [G.isPortDef,     adaptPortDef],
    [G.isPartDef,     adaptPartDef],
    [G.isActionDef,   adaptActionDef],
    [G.isActivityDef, adaptActivityDef],
  );
  return { name: g.name ?? "", portDefs, partDefs, actionDefs, activityDefs };
}

export function adaptDiagramMeta(g: G.DiagramMeta | undefined): DiagramMeta {
  if (!g) return { diagType: "activity", shows: {}, tooltips: {} };

  const kvFields = g.fields.filter(G.isKvField);
  const kvByKey = fromPairs(
    kvFields.map(f => [f.key, strOrIdent(f.value)]),
  );
  const shows = fromPairs(
    g.fields.filter(G.isShowField).map(f => [f.id ?? "", (f.role ?? "") as Role]),
  );
  const tooltips = fromPairs(
    g.fields.filter(G.isTooltipField).map(f => [f.id ?? "", strOrIdent(f.text)]),
  );

  return {
    diagType:  (kvByKey.type ?? "activity") as DiagramType,
    title:     kvByKey.title,
    name:      kvByKey.name,
    direction: kvByKey.direction as "LR" | "TB" | undefined,
    render:    kvByKey.render,
    shows,
    tooltips,
  };
}
