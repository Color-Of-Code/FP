/**
 * SysML v2 subset parser AST types.
 *
 * These are the structures produced by the parser and consumed by the
 * renderers.  No rendering or layout code belongs here.
 */

// ── Shared ─────────────────────────────────────────────────────────────────

export type Role       = "hof" | "type" | "value" | "function" | "initial" | "final" | "decision" | "merge" | "note";
export type DiagramType = "ibd" | "activity";

// ── IBD AST ────────────────────────────────────────────────────────────────

export interface PortDef {
  kind: "portDef";
  name: string;
}

export interface PortUsage {
  kind: "port";
  id: string;
  type: string;
  direction?: "in" | "out" | "inout";
  role?: Role;
  tooltip?: string;
}

export interface PartUsage {
  kind: "part";
  id: string;
  type: string;
  ports: PortUsage[];
  role?: Role;
  tooltip?: string;
}

export interface ConnectionUsage {
  kind: "connection";
  id?: string;
  from: string;
  to: string;
  via?: string;
  label?: string;
}

export interface PartDef {
  kind: "partDef";
  name: string;
  parts: PartUsage[];
  ports: PortUsage[];
  connections: ConnectionUsage[];
  notes: NoteUsage[];
  shows: Record<string, Role>;
  tooltips: Record<string, string>;
}

// ── Activity AST ───────────────────────────────────────────────────────────

export interface ActionDef {
  kind: "actionDef";
  name: string;
  pins: PortUsage[];
  activity?: ActivityDef;
}

export interface ActionUsage {
  kind: "action";
  id: string;
  type: string;
  role?: Role;
  tooltip?: string;
  laneId?: string;
  laneLabel?: string;
  laneOrder?: number;
  laneMemberOrder?: number;
}

export interface ObjectNode {
  kind: "object";
  id: string;
  type?: string;
  role?: Role;
  tooltip?: string;
  laneId?: string;
  laneLabel?: string;
  laneOrder?: number;
  laneMemberOrder?: number;
}

export interface DecisionNode {
  kind: "decision";
  id: string;
  label?: string;
  role?: Role;
  tooltip?: string;
  laneId?: string;
  laneLabel?: string;
  laneOrder?: number;
  laneMemberOrder?: number;
}

export interface MergeNode {
  kind: "merge";
  id: string;
  label?: string;
  role?: Role;
  tooltip?: string;
  laneId?: string;
  laneLabel?: string;
  laneOrder?: number;
  laneMemberOrder?: number;
}

export interface FlowUsage {
  kind: "flow";
  from: string;
  to: string;
  label?: string;
}

export interface SuccessionUsage {
  kind: "succession";
  from: string;
  to: string;
}

/**
 * A free-floating annotation pinned to an existing node (UML-style note).
 * Renders as a yellow corner-folded rectangle with a dashed line to the
 * target node.  `text` may contain `\n` for line breaks.
 */
export interface NoteUsage {
  kind:   "note";
  id:     string;
  target: string;   // id of the node this note is anchored to
  text:   string;
  role?: Role;
  tooltip?: string;
  laneId?: string;
  laneLabel?: string;
  laneOrder?: number;
  laneMemberOrder?: number;
}

/**
 * A swimlane: a labelled horizontal band that visually groups a set of
 * nodes.  Lanes are decoration only — they draw a titled rectangle behind
 * their members but do not themselves participate in flow.  Cross-lane
 * edges (e.g. an HOF in the top lane feeding into a `bind` in the bottom
 * lane) are routed normally by the layout engine.
 */
export interface LaneBlock {
  kind:    "lane";
  id:      string;
  label?:  string;
  members: string[];
}

export interface ActivityDef {
  kind: "activityDef";
  name: string;
  actions: ActionUsage[];
  objects: ObjectNode[];
  decisions: DecisionNode[];
  merges: MergeNode[];
  flows: FlowUsage[];
  successions: SuccessionUsage[];
  notes: NoteUsage[];
  lanes: LaneBlock[];
  shows: Record<string, Role>;
  tooltips: Record<string, string>;
}

// ── Package / Model ────────────────────────────────────────────────────────

export interface PackageDecl {
  name: string;
  portDefs: PortDef[];
  partDefs: PartDef[];
  actionDefs: ActionDef[];
  activityDefs: ActivityDef[];
  views: ViewUsage[];
}

export interface ViewUsage {
  id: string;
  packageName: string;
  viewType: string;
  expose?: string;
  rendering?: string;
  title?: string;
  name?: string;
  direction?: "LR" | "TB";
}

export interface DiagramMeta {
  diagType: DiagramType;
  title?: string;
  /** Short operation name for the activity-frame tab label (e.g. "traverse") */
  name?: string;
  /** Layout direction: "LR" (default, left→right) or "TB" (top→bottom) */
  direction?: "LR" | "TB";
  shows: Record<string, Role>;
  tooltips: Record<string, string>;
  render?: string;
}

export interface Model {
  packages: PackageDecl[];
  diagram: DiagramMeta;
}
