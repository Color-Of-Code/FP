/**
 * Recursive-descent parser for SysML v2 textual notation subset.
 * Produces a Model AST from a token array.
 */

import type {
  Role, DiagramType, PortDef, PortUsage, PartUsage, ConnectionUsage,
  PartDef, ActionDef, ActivityDef, PackageDecl, DiagramMeta, Model,
  DecisionNode, MergeNode,
} from "./types.ts";

export class Parser {
  private tokens: string[];
  private pos = 0;

  constructor(tokens: string[]) { this.tokens = tokens; }

  peek(): string | undefined { return this.tokens[this.pos]; }
  consume(): string { return this.tokens[this.pos++]; }
  expect(tok: string): void {
    const got = this.consume();
    if (got !== tok) throw new Error(`Expected '${tok}', got '${got}' at pos ${this.pos}`);
  }
  at(tok: string): boolean { return this.peek() === tok; }
  tryConsume(tok: string): boolean { if (this.at(tok)) { this.consume(); return true; } return false; }

  parseModel(): Model {
    const model: Model = {
      packages: [],
      diagram: { diagType: "activity", shows: {}, tooltips: {} },
    };
    while (this.peek() !== undefined) {
      if (this.peek() === "package") { model.packages.push(this.parsePackage()); }
      else if (this.peek() === "#" && this.tokens[this.pos + 1] === "diagram") {
        this.consume(); this.consume(); this.parseDiagramBlock(model.diagram);
      } else { this.consume(); }
    }
    return model;
  }

  parsePackage(): PackageDecl {
    this.expect("package");
    const name = this.parseQualifiedName();
    this.expect("{");
    const pkg: PackageDecl = { name, portDefs: [], partDefs: [], actionDefs: [], activityDefs: [] };
    while (!this.at("}") && this.peek() !== undefined) {
      const tok = this.peek()!;
      if (tok === "port" && this.tokens[this.pos + 1] === "def") {
        this.consume(); this.consume();
        const name = this.consume();
        if (this.at("{")) this.skipBlock(); else this.tryConsume(";");
        pkg.portDefs.push({ kind: "portDef", name });
      } else if (tok === "part" && this.tokens[this.pos + 1] === "def") {
        this.consume(); this.consume(); pkg.partDefs.push(this.parsePartDef());
      } else if (tok === "action" && this.tokens[this.pos + 1] === "def") {
        this.consume(); this.consume(); pkg.actionDefs.push(this.parseActionDef());
      } else if (tok === "activity" && this.tokens[this.pos + 1] === "def") {
        this.consume(); this.consume(); pkg.activityDefs.push(this.parseActivityDef());
      } else { this.consume(); }
    }
    this.tryConsume("}");
    return pkg;
  }

  parsePartDef(): PartDef {
    const name = this.parseQualifiedName();
    const def: PartDef = { kind: "partDef", name, parts: [], ports: [], connections: [] };
    if (!this.at("{")) { this.tryConsume(";"); return def; }
    this.consume();
    while (!this.at("}") && this.peek() !== undefined) {
      const tok = this.peek()!;
      if (tok === "part") {
        this.consume(); def.parts.push(this.parsePartUsage());
      } else if (tok === "port") {
        this.consume(); def.ports.push(this.parsePortUsage());
      } else if (tok === "connection") {
        this.consume(); def.connections.push(this.parseConnectionUsage());
      } else { this.consume(); }
    }
    this.tryConsume("}");
    return def;
  }

  parsePartUsage(): PartUsage {
    const id = this.consume();
    let type = id;
    if (this.at(":")) { this.consume(); type = this.parseStringOrIdent(); }
    const usage: PartUsage = { kind: "part", id, type, ports: [] };
    if (this.at("{")) {
      this.consume();
      while (!this.at("}") && this.peek() !== undefined) {
        if (this.peek() === "port") { this.consume(); usage.ports.push(this.parsePortUsage()); }
        else { this.consume(); }
      }
      this.tryConsume("}");
    } else { this.tryConsume(";"); }
    return usage;
  }

  parsePortUsage(): PortUsage {
    let direction: "in" | "out" | "inout" | undefined;
    if (this.at("in") || this.at("out") || this.at("inout")) direction = this.consume() as "in" | "out" | "inout";
    const id = this.consume();
    let type = id;
    if (this.at(":")) { this.consume(); type = this.parseStringOrIdent(); }
    this.tryConsume(";");
    return { kind: "port", id, type, direction };
  }

  parseConnectionUsage(): ConnectionUsage {
    let id: string | undefined;
    if (this.tokens[this.pos + 1] === "connect") id = this.consume();
    this.expect("connect");
    const from = this.parseDottedPath();
    this.expect("to");
    const to = this.parseDottedPath();
    let via: string | undefined;
    if (this.tryConsume("via")) via = this.parseQualifiedName();
    let label: string | undefined;
    if (this.at(":")) { this.consume(); label = this.parseStringOrIdent(); }
    this.tryConsume(";");
    return { kind: "connection", id, from, to, via, label };
  }

  parseActionDef(): ActionDef {
    const name = this.parseQualifiedName();
    const def: ActionDef = { kind: "actionDef", name, pins: [] };
    if (!this.at("{")) { this.tryConsume(";"); return def; }
    this.consume();
    while (!this.at("}") && this.peek() !== undefined) {
      const tok = this.peek()!;
      if (tok === "in" || tok === "out" || tok === "inout") {
        def.pins.push(this.parsePortUsage());
      } else { this.consume(); }
    }
    this.tryConsume("}");
    return def;
  }

  parseActivityDef(): ActivityDef {
    const name = this.parseQualifiedName();
    const def: ActivityDef = {
      kind: "activityDef", name,
      actions: [], objects: [], decisions: [], merges: [], flows: [], successions: [],
    };
    if (!this.at("{")) { this.tryConsume(";"); return def; }
    this.consume();
    while (!this.at("}") && this.peek() !== undefined) {
      const tok = this.peek()!;
      if (tok === "action") {
        this.consume();
        const id = this.consume();
        let type = id;
        if (this.at(":")) { this.consume(); type = this.parseStringOrIdent(); }
        this.tryConsume(";");
        def.actions.push({ kind: "action", id, type });
      } else if (tok === "object") {
        this.consume();
        const id = this.consume();
        let type = id;
        if (this.at(":")) { this.consume(); type = this.parseStringOrIdent(); }
        this.tryConsume(";");
        def.objects.push({ kind: "object", id, type });
      } else if (tok === "decision") {
        this.consume();
        const id = this.consume();
        this.tryConsume(";");
        def.decisions.push({ kind: "decision", id });
      } else if (tok === "merge") {
        this.consume();
        const id = this.consume();
        this.tryConsume(";");
        def.merges.push({ kind: "merge", id });
      } else if (tok === "flow") {
        this.consume();
        this.expect("from");
        const from = this.parseDottedPath();
        this.expect("to");
        const to = this.parseDottedPath();
        let label: string | undefined;
        if (this.at(":")) { this.consume(); label = this.parseStringOrIdent(); }
        this.tryConsume(";");
        def.flows.push({ kind: "flow", from, to, label });
      } else if (tok === "succession") {
        this.consume();
        const from = this.parseDottedPath();
        this.expect("then");
        const to = this.parseDottedPath();
        this.tryConsume(";");
        def.successions.push({ kind: "succession", from, to });
      } else { this.consume(); }
    }
    this.tryConsume("}");
    return def;
  }

  parseDiagramBlock(diag: DiagramMeta): void {
    this.expect("{");
    while (!this.at("}") && this.peek() !== undefined) {
      const tok = this.peek()!;
      if (tok === "type") {
        this.consume(); this.tryConsume("=");
        diag.diagType = this.consume() as DiagramType;
      } else if (tok === "title") {
        this.consume(); this.tryConsume("=");
        diag.title = this.parseStringOrIdent();
      } else if (tok === "name") {
        this.consume(); this.tryConsume("=");
        diag.name = this.parseStringOrIdent();
      } else if (tok === "direction") {
        this.consume(); this.tryConsume("=");
        diag.direction = this.consume() as "LR" | "TB";
      } else if (tok === "render") {
        this.consume(); this.tryConsume("=");
        diag.render = this.parseStringOrIdent();
      } else if (tok === "show") {
        this.consume();
        const id = this.parseDottedPath();
        this.expect("as");
        diag.shows[id] = this.consume() as Role;
      } else if (tok === "tooltip") {
        this.consume();
        const id = this.parseDottedPath();
        this.tryConsume("=");
        diag.tooltips[id] = this.parseStringOrIdent();
      } else { this.consume(); }
    }
    this.tryConsume("}");
  }

  parseQualifiedName(): string {
    let name = this.consume();
    while (this.at("<") || this.at(".")) {
      name += this.consume(); name += this.consume();
      if (this.at(">")) name += this.consume();
    }
    return name;
  }

  parseDottedPath(): string {
    let p = this.consume();
    while (this.at(".")) { p += this.consume(); p += this.consume(); }
    return p;
  }

  parseStringOrIdent(): string {
    const tok = this.consume();
    if (tok.startsWith('"')) return tok.slice(1, -1).replace(/\\"/g, '"');
    return tok;
  }

  skipBlock(): void {
    if (!this.at("{")) {
      while (this.peek() && this.peek() !== ";" && this.peek() !== "}") this.consume();
      this.tryConsume(";"); return;
    }
    this.consume(); let depth = 1;
    while (this.peek() !== undefined && depth > 0) {
      const t = this.consume();
      if (t === "{") depth++; else if (t === "}") depth--;
    }
  }
}
