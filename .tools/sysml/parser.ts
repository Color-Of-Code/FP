/**
 * Token-stream parser for SysML v2 textual notation subset.
 *
 * Rewritten as a set of composable Parser<A> values using the Parsec-style
 * combinators from ./parsec.ts.  The grammar is declarative: each construct
 * is expressed as a composition of smaller parsers rather than imperative
 * consume/peek/expect calls.
 *
 * Entry point:  parse(tokens: readonly string[]): Model
 */

import {
  Parser, tok, satisfy, anyTok, succeed, alt, lookahead,
} from "./parsec.ts";
import type {
  Role, DiagramType,
  PortDef, PortUsage, PartUsage, ConnectionUsage,
  PartDef, ActionDef, ActionUsage, ObjectNode,
  DecisionNode, MergeNode, FlowUsage, SuccessionUsage,
  ActivityDef, PackageDecl, DiagramMeta, Model,
} from "./types.ts";

// ── Low-level primitives ────────────────────────────────────────────────────

const isIdent = (t: string): boolean => /^\w/.test(t);

/** A bare identifier token (starts with a word character). */
const ident: Parser<string> = satisfy(isIdent);

/** A quoted string literal — strips the outer quotes and unescapes \". */
const str: Parser<string> =
  satisfy(t => t.startsWith('"'))
    .map(t => t.slice(1, -1).replace(/\\"/g, '"'));

/** Either a quoted string or a bare identifier. */
const stringOrIdent: Parser<string> = alt<string>(str, ident);

/** Optional semicolon — matches and discards ";" if present. */
const optSemi: Parser<string | undefined> = tok(";").opt();

// ── Name parsers ────────────────────────────────────────────────────────────

/**
 * One suffix segment of a qualified name:
 *   "<" ident ">"?   (generic argument — lexer may or may not include ">")
 *   "." ident        (qualified name segment)
 */
const qNameSuffix: Parser<string> = alt<string>(
  tok("<").thenR(anyTok).then(tok(">").opt())
    .map(([inner, gt]) => `<${inner}${gt ?? ""}`),
  tok(".").thenR(anyTok).map(seg => `.${seg}`),
);

/**
 * Qualified name: an identifier optionally followed by repeated
 * generic-argument or dotted-segment suffixes.
 * Handles both compact ("Foo<Bar>") and spaced ("Foo < Bar >") lexer forms.
 */
const qualifiedName: Parser<string> =
  anyTok.flatMap(head =>
    qNameSuffix.many().map(sfxs => head + sfxs.join(""))
  );

/** Dotted path: a.b.c — successive "." ident pairs after a leading ident. */
const dottedPath: Parser<string> =
  anyTok.flatMap(head =>
    tok(".").thenR(anyTok).many()
      .map(segs => segs.length > 0 ? `${head}.${segs.join(".")}` : head)
  );

// ── Block helper ────────────────────────────────────────────────────────────

/**
 * Skip an unrecognised block or inline definition.
 *
 * • If the current token is "{": depth-tracked skip of the whole "{…}" block.
 * • Otherwise: skip tokens up to and including the next ";", or stop
 *   before "}" (so the caller's block-close is not accidentally consumed).
 * • At "}": returns a zero-width success — triggers many()'s loop-guard and
 *   lets the surrounding braced() parser consume the closing brace itself.
 */
const skipBlock: Parser<undefined> = new Parser((ts, pos) => {
  if (ts[pos] === "}") return { value: undefined, pos }; // zero-width at close
  if (ts[pos] !== "{") {
    let cur = pos;
    while (cur < ts.length && ts[cur] !== ";" && ts[cur] !== "}") cur++;
    if (ts[cur] === ";") cur++;
    return { value: undefined, pos: cur };
  }
  // balanced block skip
  let cur = pos + 1;
  let depth = 1;
  while (cur < ts.length && depth > 0) {
    if (ts[cur] === "{") depth++;
    else if (ts[cur] === "}") depth--;
    cur++;
  }
  return { value: undefined, pos: cur };
});

/** Parse p between a "{" and a "}". */
const braced = <A>(p: Parser<A>): Parser<A> =>
  tok("{").thenR(p).thenL(tok("}"));

// ── IBD parsers ─────────────────────────────────────────────────────────────

const direction: Parser<"in" | "out" | "inout"> =
  (alt(tok("in"), tok("out"), tok("inout")) as Parser<"in" | "out" | "inout">);

/**
 * Port usage: [direction] id [":" type] [";"]
 * Used for part/action pin declarations and inline block ports.
 */
const portUsage: Parser<PortUsage> =
  direction.opt().flatMap(dir =>
    anyTok.flatMap(id =>
      tok(":").thenR(stringOrIdent).opt()
        .thenL(optSemi)
        .map(type => ({ kind: "port" as const, id, type: type ?? id, direction: dir }))
    )
  );

/** Part usage: id [":" type] ["{" port* "}"] */
const partUsage: Parser<PartUsage> =
  anyTok.flatMap(id =>
    tok(":").thenR(stringOrIdent).opt().flatMap(type =>
      alt<PortUsage[]>(
        braced(
          alt<PortUsage | null>(
            tok("port").thenR(portUsage),
            skipBlock.map(() => null),
          ).many()
        ).map(items => items.flatMap(x => x ? [x] : [])),
        optSemi.map(() => []),
      ).map(ports => ({ kind: "part" as const, id, type: type ?? id, ports }))
    )
  );

/**
 * Optional leading id before "connect".
 * Uses lookahead so the id token is consumed only when "connect" follows —
 * otherwise the alt backtracks to the original position.
 */
const connectionId: Parser<string | undefined> = alt<string | undefined>(
  satisfy(t => t !== "connect").thenL(lookahead(tok("connect"))),
  succeed(undefined),
);

/** Connection usage: [id] connect from to [via …] [":" label] */
const connectionUsage: Parser<ConnectionUsage> =
  connectionId.thenL(tok("connect")).flatMap(id =>
    dottedPath.flatMap(from =>
      tok("to").thenR(dottedPath).flatMap(to =>
        tok("via").thenR(qualifiedName).opt().flatMap(via =>
          tok(":").thenR(stringOrIdent).opt().thenL(optSemi)
            .map(label => ({ kind: "connection" as const, id, from, to, via, label }))
        )
      )
    )
  );

type PartBodyItem =
  | { k: "part"; v: PartUsage }
  | { k: "port"; v: PortUsage }
  | { k: "connection"; v: ConnectionUsage };

const partBodyItem: Parser<PartBodyItem | null> = alt<PartBodyItem | null>(
  tok("part").thenR(partUsage).map(v => ({ k: "part" as const, v })),
  tok("port").thenR(portUsage).map(v => ({ k: "port" as const, v })),
  tok("connection").thenR(connectionUsage).map(v => ({ k: "connection" as const, v })),
  skipBlock.map(() => null),
);

/** Part def: QualifiedName ["{" (part | port | connection | skip)* "}"] */
const partDef: Parser<PartDef> =
  qualifiedName.flatMap(name =>
    alt<{ parts: PartUsage[]; ports: PortUsage[]; connections: ConnectionUsage[] }>(
      braced(partBodyItem.many()).map(items => ({
        parts:       items.flatMap(x => x?.k === "part"       ? [x.v] : []),
        ports:       items.flatMap(x => x?.k === "port"       ? [x.v] : []),
        connections: items.flatMap(x => x?.k === "connection" ? [x.v] : []),
      })),
      optSemi.map(() => ({ parts: [], ports: [], connections: [] })),
    ).map(body => ({ kind: "partDef" as const, name, ...body }))
  );

// ── Action / Activity parsers ───────────────────────────────────────────────

/** Action def: QualifiedName ["{" (direction pin | skip)* "}"] */
const actionDef: Parser<ActionDef> =
  qualifiedName.flatMap(name =>
    alt<PortUsage[]>(
      braced(
        alt<PortUsage | null>(
          direction.flatMap(dir =>
            anyTok.flatMap(id =>
              tok(":").thenR(stringOrIdent).opt().thenL(optSemi)
                .map(type => ({ kind: "port" as const, id, type: type ?? id, direction: dir }))
            )
          ),
          skipBlock.map(() => null),
        ).many()
      ).map(items => items.flatMap(x => x ? [x] : [])),
      optSemi.map(() => []),
    ).map(pins => ({ kind: "actionDef" as const, name, pins }))
  );

type ActivityBodyItem =
  | { k: "action";     v: ActionUsage }
  | { k: "object";     v: ObjectNode }
  | { k: "decision";   v: DecisionNode }
  | { k: "merge";      v: MergeNode }
  | { k: "flow";       v: FlowUsage }
  | { k: "succession"; v: SuccessionUsage };

const activityBodyItem: Parser<ActivityBodyItem | null> = alt<ActivityBodyItem | null>(
  tok("action").thenR(anyTok).flatMap(id =>
    tok(":").thenR(stringOrIdent).opt().thenL(optSemi)
      .map(type => ({ k: "action" as const, v: { kind: "action" as const, id, type: type ?? id } }))
  ),
  tok("object").thenR(anyTok).flatMap(id =>
    tok(":").thenR(stringOrIdent).opt().thenL(optSemi)
      .map(type => ({ k: "object" as const, v: { kind: "object" as const, id, type: type ?? id } }))
  ),
  tok("decision").thenR(anyTok).thenL(optSemi)
    .map(id => ({ k: "decision" as const, v: { kind: "decision" as const, id } })),
  tok("merge").thenR(anyTok).thenL(optSemi)
    .map(id => ({ k: "merge" as const, v: { kind: "merge" as const, id } })),
  tok("flow").thenR(tok("from")).thenR(dottedPath).flatMap(from =>
    tok("to").thenR(dottedPath).flatMap(to =>
      tok(":").thenR(stringOrIdent).opt().thenL(optSemi)
        .map(label => ({ k: "flow" as const, v: { kind: "flow" as const, from, to, label } }))
    )
  ),
  tok("succession").thenR(dottedPath).flatMap(from =>
    tok("then").thenR(dottedPath).thenL(optSemi)
      .map(to => ({ k: "succession" as const, v: { kind: "succession" as const, from, to } }))
  ),
  skipBlock.map(() => null),
);

/** Activity def: QualifiedName ["{" body* "}"] */
const activityDef: Parser<ActivityDef> =
  qualifiedName.flatMap(name =>
    alt<Omit<ActivityDef, "kind" | "name">>(
      braced(activityBodyItem.many()).map(items => ({
        actions:     items.flatMap(x => x?.k === "action"     ? [x.v] : []),
        objects:     items.flatMap(x => x?.k === "object"     ? [x.v] : []),
        decisions:   items.flatMap(x => x?.k === "decision"   ? [x.v] : []),
        merges:      items.flatMap(x => x?.k === "merge"      ? [x.v] : []),
        flows:       items.flatMap(x => x?.k === "flow"       ? [x.v] : []),
        successions: items.flatMap(x => x?.k === "succession" ? [x.v] : []),
      })),
      optSemi.map(() => ({
        actions: [], objects: [], decisions: [],
        merges: [], flows: [], successions: [],
      })),
    ).map(body => ({ kind: "activityDef" as const, name, ...body }))
  );

// ── Package parser ──────────────────────────────────────────────────────────

type PkgItem =
  | { k: "portDef";    v: PortDef }
  | { k: "partDef";    v: PartDef }
  | { k: "actionDef";  v: ActionDef }
  | { k: "activityDef"; v: ActivityDef };

const pkgBodyItem: Parser<PkgItem | null> = alt<PkgItem | null>(
  tok("port").thenR(tok("def")).thenR(anyTok).thenL(skipBlock)
    .map(name => ({ k: "portDef" as const, v: { kind: "portDef" as const, name } })),
  tok("part").thenR(tok("def")).thenR(partDef)
    .map(v => ({ k: "partDef" as const, v })),
  tok("action").thenR(tok("def")).thenR(actionDef)
    .map(v => ({ k: "actionDef" as const, v })),
  tok("activity").thenR(tok("def")).thenR(activityDef)
    .map(v => ({ k: "activityDef" as const, v })),
  skipBlock.map(() => null),
);

/** Package declaration: "package" QualifiedName "{" body* "}" */
const packageDecl: Parser<PackageDecl> =
  tok("package").thenR(qualifiedName).flatMap(name =>
    braced(pkgBodyItem.many()).map(items => ({
      name,
      portDefs:     items.flatMap(x => x?.k === "portDef"     ? [x.v] : []),
      partDefs:     items.flatMap(x => x?.k === "partDef"     ? [x.v] : []),
      actionDefs:   items.flatMap(x => x?.k === "actionDef"   ? [x.v] : []),
      activityDefs: items.flatMap(x => x?.k === "activityDef" ? [x.v] : []),
    }))
  );

// ── Diagram meta parser ─────────────────────────────────────────────────────

type DiagramField =
  | { k: "type";      v: DiagramType }
  | { k: "title";     v: string }
  | { k: "name";      v: string }
  | { k: "direction"; v: "LR" | "TB" }
  | { k: "render";    v: string }
  | { k: "show";      id: string; role: Role }
  | { k: "tooltip";   id: string; text: string };

const diagramField: Parser<DiagramField | null> = alt<DiagramField | null>(
  tok("type").thenR(tok("=").opt()).thenR(anyTok)
    .map(v => ({ k: "type" as const, v: v as DiagramType })),
  tok("title").thenR(tok("=").opt()).thenR(stringOrIdent)
    .map(v => ({ k: "title" as const, v })),
  tok("name").thenR(tok("=").opt()).thenR(stringOrIdent)
    .map(v => ({ k: "name" as const, v })),
  tok("direction").thenR(tok("=").opt()).thenR(anyTok)
    .map(v => ({ k: "direction" as const, v: v as "LR" | "TB" })),
  tok("render").thenR(tok("=").opt()).thenR(stringOrIdent)
    .map(v => ({ k: "render" as const, v })),
  tok("show").thenR(dottedPath).flatMap(id =>
    tok("as").thenR(anyTok).map(role => ({ k: "show" as const, id, role: role as Role }))
  ),
  tok("tooltip").thenR(dottedPath).thenL(tok("=").opt()).flatMap(id =>
    stringOrIdent.map(text => ({ k: "tooltip" as const, id, text }))
  ),
  skipBlock.map(() => null),
);

/**
 * Diagram meta block: "# diagram" "{" fields* "}"
 * Folds the collected fields into a DiagramMeta object.
 */
const diagramMeta: Parser<DiagramMeta> =
  tok("#").thenR(tok("diagram")).thenR(braced(diagramField.many()))
    .map(fields => {
      const diag: DiagramMeta = { diagType: "activity", shows: {}, tooltips: {} };
      for (const f of fields) {
        if (!f) continue;
        if      (f.k === "type")      diag.diagType  = f.v;
        else if (f.k === "title")     diag.title     = f.v;
        else if (f.k === "name")      diag.name      = f.v;
        else if (f.k === "direction") diag.direction = f.v;
        else if (f.k === "render")    diag.render    = f.v;
        else if (f.k === "show")      diag.shows[f.id]    = f.role;
        else if (f.k === "tooltip")   diag.tooltips[f.id] = f.text;
      }
      return diag;
    });

// ── Top-level model parser ──────────────────────────────────────────────────

type ModelItem =
  | { k: "package"; v: PackageDecl }
  | { k: "diagram"; v: DiagramMeta };

const modelItem: Parser<ModelItem | null> = alt<ModelItem | null>(
  packageDecl.map(v => ({ k: "package" as const, v })),
  diagramMeta.map(v => ({ k: "diagram" as const, v })),
  anyTok.map(() => null),   // skip unrecognised top-level tokens
);

const modelParser: Parser<Model> = modelItem.many().map(items => ({
  packages: items.flatMap(x => x?.k === "package" ? [x.v] : []),
  diagram:  items.find(x => x?.k === "diagram")?.v
              ?? { diagType: "activity" as DiagramType, shows: {}, tooltips: {} },
}));

/**
 * Parse a flat token array (produced by tokenise()) into a Model AST.
 * Throws on unrecoverable parse failure.
 */
export function parse(tokens: readonly string[]): Model {
  return modelParser.run(tokens);
}
