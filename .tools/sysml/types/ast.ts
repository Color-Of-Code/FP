/**
 * SysML v2 subset parser AST types.
 *
 * These are the structures produced by the parser and consumed by the
 * renderers.  No rendering or layout code belongs here.
 */

// ── Shared ─────────────────────────────────────────────────────────────────

export type Role       = "hof" | "type" | "value" | "function" | "initial" | "final" | "decision" | "merge";
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
}

export interface PartUsage {
  kind: "part";
  id: string;
  type: string;
  ports: PortUsage[];
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
}

// ── Activity AST ───────────────────────────────────────────────────────────

export interface ActionDef {
  kind: "actionDef";
  name: string;
  pins: PortUsage[];
}

export interface ActionUsage {
  kind: "action";
  id: string;
  type: string;
}

export interface ObjectNode {
  kind: "object";
  id: string;
  type: string;
}

export interface DecisionNode {
  kind: "decision";
  id: string;
  label?: string;
}

export interface MergeNode {
  kind: "merge";
  id: string;
  label?: string;
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

export interface ActivityDef {
  kind: "activityDef";
  name: string;
  actions: ActionUsage[];
  objects: ObjectNode[];
  decisions: DecisionNode[];
  merges: MergeNode[];
  flows: FlowUsage[];
  successions: SuccessionUsage[];
}

// ── Package / Model ────────────────────────────────────────────────────────

export interface PackageDecl {
  name: string;
  portDefs: PortDef[];
  partDefs: PartDef[];
  actionDefs: ActionDef[];
  activityDefs: ActivityDef[];
}

export interface DiagramMeta {
  diagType: DiagramType;
  title?: string;
  /** Short operation name for the activity-frame tab label (e.g. "traverse") */
  name?: string;
  /** Layout direction: "LR" (default, left→right) or "TB" (top→bottom) */
  direction?: "LR" | "TB";
  /** Layout engine: "dagre" (default, fast) or "elk" (better edge routing) */
  layout?: "dagre" | "elk";
  shows: Record<string, Role>;
  tooltips: Record<string, string>;
  render?: string;
}

export interface Model {
  packages: PackageDecl[];
  diagram: DiagramMeta;
}
