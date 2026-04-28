/**
 * SysML v2 (subset) parser built on Langium.
 *
 * The Langium-generated parser produces its own AST shape (see
 * `generated/ast.ts`).  This module wraps Langium's services and adapts the
 * generated AST to the renderer-facing `Model` type defined in
 * `./types/ast.ts`, so existing callers and the SVG snapshots stay stable.
 *
 * Public API:
 *   parse(src: string): Model
 */

import type { LangiumServices } from "langium/lsp";
import {
  EmptyFileSystem, inject, DefaultValueConverter,
  type CstNode, type GrammarAST, type ValueType,
} from "langium";
import { createDefaultCoreModule, createDefaultSharedCoreModule } from "langium";
import { SysmlGeneratedModule, SysmlGeneratedSharedModule } from "./generated/module.js";
import * as G from "./generated/ast.js";
import type {
  Role, DiagramType,
  PortDef, PortUsage, PartUsage, ConnectionUsage,
  PartDef, ActionDef, ActionUsage, ObjectNode,
  DecisionNode, MergeNode, FlowUsage, SuccessionUsage,
  NoteUsage,
  ActivityDef, PackageDecl, DiagramMeta, Model,
} from "./types.ts";

// ── Langium services bootstrap ──────────────────────────────────────────────

/**
 * Custom value converter: keep STRING values exactly as the previous
 * hand-rolled parser did — strip the surrounding quotes and unescape `\"`,
 * but leave other escape sequences (`\n`, `\t`, …) as literal two-character
 * sequences.  This preserves the existing SVG snapshot output.
 */
class SysmlValueConverter extends DefaultValueConverter {
  protected override runConverter(
    rule: GrammarAST.AbstractRule,
    input: string,
    cstNode: CstNode,
  ): ValueType {
    if (rule.name === "STRING") {
      return input.slice(1, -1).replace(/\\"/g, '"');
    }
    return super.runConverter(rule, input, cstNode);
  }
}

function createSysmlServices(): { Sysml: { parser: { LangiumParser: any } } } {
  const shared = inject(
    createDefaultSharedCoreModule(EmptyFileSystem),
    SysmlGeneratedSharedModule,
  );
  const Sysml = inject(
    createDefaultCoreModule({ shared }),
    SysmlGeneratedModule,
    { parser: { ValueConverter: () => new SysmlValueConverter() } },
  );
  shared.ServiceRegistry.register(Sysml as unknown as LangiumServices);
  return { Sysml: Sysml as any };
}

const { Sysml } = createSysmlServices();
const langiumParser = Sysml.parser.LangiumParser;

// ── Adapter helpers ─────────────────────────────────────────────────────────

const stripQuotes = (s: string | undefined): string =>
  s && s.startsWith('"') ? s.slice(1, -1).replace(/\\"/g, '"') : (s ?? "");

// `StrOrIdent` is a string in the generated AST: either a quoted literal
// (with the surrounding quotes preserved by the data-type rule) or a bare
// identifier.  Normalise either to plain text.
function strOrIdent(value: string | undefined): string {
  return stripQuotes(value);
}

function adaptPortDef(g: G.PortDef): PortDef {
  return { kind: "portDef", name: g.name ?? "" };
}

function adaptInlinePort(g: G.InlinePort): PortUsage {
  const id = g.id ?? "";
  return {
    kind: "port",
    id,
    type: g.type !== undefined ? strOrIdent(g.type) : id,
    direction: g.direction,
  };
}

function adaptPinDecl(g: G.PinDecl): PortUsage {
  const id = g.id ?? "";
  return {
    kind: "port",
    id,
    type: g.type !== undefined ? strOrIdent(g.type) : id,
    direction: g.direction,
  };
}

function adaptPartUsage(g: G.PartUsage): PartUsage {
  const id = g.id ?? "";
  return {
    kind: "part",
    id,
    type: g.type !== undefined ? strOrIdent(g.type) : id,
    ports: g.ports.map(adaptInlinePort),
  };
}

function adaptConnection(g: G.ConnectionUsage): ConnectionUsage {
  return {
    kind: "connection",
    id:    g.cid ?? undefined,
    from:  g.from ?? "",
    to:    g.to ?? "",
    via:   g.via ?? undefined,
    label: g.label !== undefined ? strOrIdent(g.label) : undefined,
  };
}

function adaptPartDef(g: G.PartDef): PartDef {
  const parts:       PartUsage[]       = [];
  const ports:       PortUsage[]       = [];
  const connections: ConnectionUsage[] = [];
  const notes:       NoteUsage[]       = [];
  for (const m of g.members) {
    if (G.isPartUsage(m))            parts.push(adaptPartUsage(m));
    else if (G.isInlinePort(m))      ports.push(adaptInlinePort(m));
    else if (G.isConnectionUsage(m)) connections.push(adaptConnection(m));
    else if (G.isNoteUsage(m))       notes.push(adaptNote(m));
  }
  return { kind: "partDef", name: g.name ?? "", parts, ports, connections, notes };
}

function adaptActionDef(g: G.ActionDef): ActionDef {
  return {
    kind: "actionDef",
    name: g.name ?? "",
    pins: g.pins.map(adaptPinDecl),
  };
}

function adaptActionUsage(g: G.ActionUsage): ActionUsage {
  const id = g.id ?? "";
  return { kind: "action", id, type: g.type !== undefined ? strOrIdent(g.type) : id };
}

function adaptObjectNode(g: G.ObjectNode): ObjectNode {
  const id = g.id ?? "";
  return { kind: "object", id, type: g.type !== undefined ? strOrIdent(g.type) : id };
}

function adaptDecisionNode(g: G.DecisionNode): DecisionNode {
  return {
    kind:  "decision",
    id:    g.id ?? "",
    label: g.label !== undefined ? strOrIdent(g.label) : undefined,
  };
}

function adaptMergeNode(g: G.MergeNode): MergeNode {
  return {
    kind:  "merge",
    id:    g.id ?? "",
    label: g.label !== undefined ? strOrIdent(g.label) : undefined,
  };
}

function adaptFlowUsage(g: G.FlowUsage): FlowUsage {
  return {
    kind:  "flow",
    from:  g.from ?? "",
    to:    g.to ?? "",
    label: g.label !== undefined ? strOrIdent(g.label) : undefined,
  };
}

function adaptSuccession(g: G.SuccessionUsage): SuccessionUsage {
  return { kind: "succession", from: g.from ?? "", to: g.to ?? "" };
}

function adaptNote(g: G.NoteUsage): NoteUsage {
  return {
    kind:   "note",
    id:     g.id ?? "",
    target: g.target ?? "",
    text:   strOrIdent(g.text),
  };
}

function adaptActivityDef(g: G.ActivityDef): ActivityDef {
  const actions:     ActionUsage[]     = [];
  const objects:     ObjectNode[]      = [];
  const decisions:   DecisionNode[]    = [];
  const merges:      MergeNode[]       = [];
  const flows:       FlowUsage[]       = [];
  const successions: SuccessionUsage[] = [];
  const notes:       NoteUsage[]       = [];
  for (const m of g.members) {
    if      (G.isActionUsage(m))     actions.push(adaptActionUsage(m));
    else if (G.isObjectNode(m))      objects.push(adaptObjectNode(m));
    else if (G.isDecisionNode(m))    decisions.push(adaptDecisionNode(m));
    else if (G.isMergeNode(m))       merges.push(adaptMergeNode(m));
    else if (G.isFlowUsage(m))       flows.push(adaptFlowUsage(m));
    else if (G.isSuccessionUsage(m)) successions.push(adaptSuccession(m));
    else if (G.isNoteUsage(m))       notes.push(adaptNote(m));
  }
  return {
    kind: "activityDef",
    name: g.name ?? "",
    actions, objects, decisions, merges, flows, successions, notes,
  };
}

function adaptPackage(g: G.Package): PackageDecl {
  const portDefs:     PortDef[]     = [];
  const partDefs:     PartDef[]     = [];
  const actionDefs:   ActionDef[]   = [];
  const activityDefs: ActivityDef[] = [];
  for (const m of g.members) {
    if      (G.isPortDef(m))     portDefs.push(adaptPortDef(m));
    else if (G.isPartDef(m))     partDefs.push(adaptPartDef(m));
    else if (G.isActionDef(m))   actionDefs.push(adaptActionDef(m));
    else if (G.isActivityDef(m)) activityDefs.push(adaptActivityDef(m));
  }
  return { name: g.name ?? "", portDefs, partDefs, actionDefs, activityDefs };
}

function adaptDiagramMeta(g: G.DiagramMeta | undefined): DiagramMeta {
  const out: DiagramMeta = { diagType: "activity", shows: {}, tooltips: {} };
  if (!g) return out;
  for (const f of g.fields) {
    if (G.isKvField(f)) {
      const value = strOrIdent(f.value as unknown as string);
      switch (f.key) {
        case "type":      out.diagType  = value as DiagramType; break;
        case "title":     out.title     = value;                break;
        case "name":      out.name      = value;                break;
        case "direction": out.direction = value as "LR" | "TB"; break;
        case "layout":    out.layout    = value as "dagre" | "elk"; break;
        case "render":    out.render    = value;                break;
      }
    } else if (G.isShowField(f)) {
      out.shows[f.id ?? ""] = (f.role ?? "") as Role;
    } else if (G.isTooltipField(f)) {
      out.tooltips[f.id ?? ""] = strOrIdent(f.text);
    }
  }
  return out;
}

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Parse SysML v2 (subset) source text into a renderer-facing `Model`.
 * Throws on lexer or parser errors.
 */
export function parse(src: string): Model {
  const result = (langiumParser as any).parse(src) as {
    value: G.Model;
    lexerErrors: Array<{ line?: number; column?: number; message: string }>;
    parserErrors: Array<{ message: string; token?: { image: string } }>;
  };
  if (result.lexerErrors.length > 0) {
    const e = result.lexerErrors[0];
    throw new Error(`Lexer error at ${e.line}:${e.column}: ${e.message}`);
  }
  if (result.parserErrors.length > 0) {
    const e = result.parserErrors[0];
    throw new Error(`Parse error: ${e.message} (token '${e.token?.image ?? "<eof>"}')`);
  }
  const m = result.value;
  return {
    packages: m.packages.map(adaptPackage),
    diagram:  adaptDiagramMeta(m.diagram),
  };
}
