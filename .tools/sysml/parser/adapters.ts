/**
 * AST adapters — transform Langium-generated AST nodes into the
 * renderer-facing types defined in `../types/ast.ts`.
 */

import * as G from "../generated/ast.ts";
import { fromPairs, groupBy, sortBy } from "../lib/fp.ts";
import type {
  ActivityDef, ActionDef, ActionUsage, ConnectionUsage, DiagramMeta, DiagramType,
  DecisionNode, FlowUsage, LaneBlock, MergeNode, NoteUsage, ObjectNode, PackageDecl,
  PartDef, PartUsage, PortDef, PortUsage, Role, ViewUsage,
} from "../types.ts";

const stripQuotes = (value: string | undefined): string =>
  value?.startsWith('"') ? value.slice(1, -1).replace(/\\"/g, '"') : (value ?? "");

export const strOrIdent = (value: string | undefined): string => stripQuotes(value);

export function optionalStrOrIdent(
  value: string | undefined,
  fallback?: string,
): string | undefined {
  return value !== undefined ? strOrIdent(value) : fallback;
}

interface PortLikeNode {
  id?: string;
  type?: string;
  direction?: G.Direction;
  metadata?: G.NodeMetadata[];
}

interface NodePresentation {
  role?: Role;
  tooltip?: string;
  laneId?: string;
  laneLabel?: string;
  laneOrder?: number;
  laneMemberOrder?: number;
}

const ROLE_NAMES: readonly Role[] = [
  "hof", "type", "value", "function", "initial", "final", "decision", "merge", "note",
];

function metadataField(metadata: readonly G.NodeMetadata[], key: string): string | undefined {
  const field = metadata
    .filter(item => item.name === "FpNodePresentation")
    .flatMap(item => item.fields)
    .find(item => item.key === key);
  return optionalStrOrIdent(field?.value);
}

function nodePresentation(metadata: readonly G.NodeMetadata[] = []): NodePresentation {
  const role = metadataField(metadata, "role");
  const laneOrder = metadataField(metadata, "laneOrder");
  const laneMemberOrder = metadataField(metadata, "laneMemberOrder");
  return {
    role: ROLE_NAMES.find(candidate => candidate === role),
    tooltip: metadataField(metadata, "tooltip"),
    laneId: metadataField(metadata, "laneId"),
    laneLabel: metadataField(metadata, "laneLabel"),
    laneOrder: laneOrder ? Number(laneOrder) : undefined,
    laneMemberOrder: laneMemberOrder ? Number(laneMemberOrder) : undefined,
  };
}

function adaptPortLike(g: PortLikeNode): PortUsage {
  const id = g.id ?? "";
  const presentation = nodePresentation(g.metadata);
  return {
    kind: "port",
    id,
    type: optionalStrOrIdent(g.type, id) ?? id,
    direction: g.direction,
    ...presentation,
  };
}

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
    ...nodePresentation(g.metadata),
  };
}

function adaptConnection(g: G.ConnectionUsage): ConnectionUsage {
  return {
    kind: "connection",
    id: g.cid ?? undefined,
    from: g.from ?? "",
    to: g.to ?? "",
    via: g.via ?? undefined,
    label: optionalStrOrIdent(g.label),
  };
}

function adaptNote(g: G.NoteUsage): NoteUsage {
  return {
    kind: "note",
    id: g.id ?? "",
    target: g.target ?? "",
    text: strOrIdent(g.text),
    ...nodePresentation(g.metadata),
  };
}

function adaptActionUsage(g: G.ActionUsage): ActionUsage {
  const id = g.id ?? "";
  return {
    kind: "action",
    id,
    type: optionalStrOrIdent(g.type, id) ?? id,
    ...nodePresentation(g.metadata),
  };
}

function adaptObjectNode(g: G.ItemUsage): ObjectNode {
  return {
    kind: "object",
    id: g.id ?? "",
    type: optionalStrOrIdent(g.type),
    ...nodePresentation(g.metadata),
  };
}

function adaptDecisionNode(g: G.DecisionNode): DecisionNode {
  return {
    kind: "decision",
    id: g.id ?? "",
    label: optionalStrOrIdent(g.label),
    ...nodePresentation(g.metadata),
  };
}

function adaptMergeNode(g: G.MergeNode): MergeNode {
  return {
    kind: "merge",
    id: g.id ?? "",
    label: optionalStrOrIdent(g.label),
    ...nodePresentation(g.metadata),
  };
}

function adaptFlowUsage(g: G.FlowUsage): FlowUsage {
  return {
    kind: "flow",
    from: g.from ?? "",
    to: g.to ?? "",
    label: optionalStrOrIdent(g.label),
  };
}

function adaptSuccession(g: G.SuccessionUsage) {
  return { kind: "succession" as const, from: g.from ?? "", to: g.to ?? "" };
}

function pairsFor<T extends { id: string; role?: Role; tooltip?: string }>(
  nodes: readonly T[],
  field: "role" | "tooltip",
): [string, Role | string][] {
  return nodes.flatMap(node => {
    const value = node[field];
    return value !== undefined ? [[node.id, value]] : [];
  });
}

function presentationMaps(nodes: readonly { id: string; role?: Role; tooltip?: string }[]): {
  shows: Record<string, Role>;
  tooltips: Record<string, string>;
} {
  return {
    shows: fromPairs(
      pairsFor(nodes, "role").filter((pair): pair is [string, Role] => typeof pair[1] === "string"),
    ),
    tooltips: fromPairs(
      pairsFor(nodes, "tooltip").filter((pair): pair is [string, string] => typeof pair[1] === "string"),
    ),
  };
}

function adaptPartDef(g: G.PartDef): PartDef {
  const [parts, ports, connections, notes] = partitionByKind(
    g.members,
    [G.isPartUsage, adaptPartUsage],
    [G.isInlinePort, adaptPortLike],
    [G.isConnectionUsage, adaptConnection],
    [G.isNoteUsage, adaptNote],
  );
  const maps = presentationMaps([...parts, ...notes]);
  return { kind: "partDef", name: g.name ?? "", parts, ports, connections, notes, ...maps };
}

function adaptActivityDef(g: G.ActionDef): ActivityDef {
  const [actions, objects, decisions, merges, flows, successions, notes] = partitionByKind(
    g.members,
    [G.isActionUsage, adaptActionUsage],
    [G.isItemUsage, adaptObjectNode],
    [G.isDecisionNode, adaptDecisionNode],
    [G.isMergeNode, adaptMergeNode],
    [G.isFlowUsage, adaptFlowUsage],
    [G.isSuccessionUsage, adaptSuccession],
    [G.isNoteUsage, adaptNote],
    [G.isPinDeclaration, adaptPortLike],
  );
  const nodes = [...actions, ...objects, ...decisions, ...merges, ...notes];
  const laneEntries = nodes.flatMap(node =>
    node.laneId && node.laneLabel
      ? [{
          id: node.laneId,
          label: node.laneLabel,
          member: node.id,
          order: node.laneOrder ?? 0,
          memberOrder: node.laneMemberOrder ?? 0,
        }]
      : [],
  );
  const lanes = sortBy(
    Object.entries(groupBy(laneEntries, entry => entry.id)).map(([id, entries]) => ({
      kind: "lane" as const,
      id,
      label: entries[0]?.label,
      order: entries[0]?.order ?? 0,
      members: sortBy(entries, entry => entry.memberOrder).map(entry => entry.member),
    })),
    lane => lane.order,
  ).map(({ order: _order, ...lane }) => lane);
  return {
    kind: "activityDef",
    name: g.name ?? "",
    actions,
    objects,
    decisions,
    merges,
    flows,
    successions,
    notes,
    lanes,
    ...presentationMaps(nodes),
  };
}

function adaptActionDef(g: G.ActionDef): ActionDef {
  const pins = g.members.filter(G.isPinDeclaration).map(adaptPortLike);
  const hasBodyNodes = g.members.some(member => !G.isPinDeclaration(member));
  const activity = hasBodyNodes ? adaptActivityDef(g) : undefined;
  return { kind: "actionDef", name: g.name ?? "", pins, activity };
}

function adaptViewUsage(g: G.ViewUsage, packageName: string): ViewUsage {
  const options = g.metadata.find(metadata => metadata.name === "FpViewPresentation");
  const option = (key: string) => optionalStrOrIdent(
    options?.fields.find(field => field.key === key)?.value,
  );
  const doc = g.members.find(G.isDocumentation);
  const docMatch = doc?.text.match(/^doc\s*\/\*([\s\S]*)\*\/$/);
  return {
    id: g.id ?? "",
    packageName,
    viewType: g.viewType ?? "",
    expose: g.members.find(G.isExpose)?.target,
    rendering: g.members.find(G.isRenderUsage)?.rendering,
    title: docMatch?.[1] ?? doc?.text,
    name: option("name"),
    direction: option("direction") as "LR" | "TB" | undefined,
  };
}

export function adaptPackage(g: G.Package): PackageDecl {
  const portDefs = g.members.filter(G.isPortDef).map(adaptPortDef);
  const partDefs = g.members.filter(G.isPartDef).map(adaptPartDef);
  const actionDefs = g.members.filter(G.isActionDef).map(adaptActionDef);
  const activityDefs = actionDefs.flatMap(action => action.activity ? [action.activity] : []);
  const views = g.members.filter(G.isViewUsage).map(view => adaptViewUsage(view, g.name ?? ""));
  return {
    name: g.name ?? "",
    portDefs,
    partDefs,
    actionDefs,
    activityDefs,
    views,
  };
}

export function adaptDiagramMeta(
  view: ViewUsage | undefined,
  graph: PartDef | ActivityDef | undefined,
): DiagramMeta {
  if (!view) return { diagType: "activity", shows: {}, tooltips: {} };
  const diagType: DiagramType = view.viewType === "FpIbdView" ? "ibd" : "activity";
  const exposeTarget = view.expose?.split("::").at(-1);
  return {
    diagType,
    title: view.title,
    name: view.name,
    direction: view.direction,
    render: exposeTarget,
    shows: graph?.shows ?? {},
    tooltips: graph?.tooltips ?? {},
  };
}

/** Rebuild the heterogeneous member list without losing source order. */
function partitionByKind<M, R extends readonly DispatchEntry<M, unknown>[]>(
  members: readonly M[],
  ...dispatch: R
): { [K in keyof R]: R[K] extends DispatchEntry<M, infer T> ? T[] : never } {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any -- mapped tuple cast unavoidable
  const result = dispatch.map(() => [] as unknown[]) as any;
  members.forEach(member => {
    const index = dispatch.findIndex(entry => entry[0](member));
    if (index >= 0) result[index].push(dispatch[index][1](member));
  });
  return result;
}

type DispatchEntry<M, T> = readonly [(member: M) => member is M & object, (member: any) => T];
