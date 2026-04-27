/**
 * SysML v2 (subset) parser built with Chevrotain.
 *
 * Replaces the previous hand-rolled lexer + Parsec-style combinators.
 * Public API:
 *   parse(src: string): Model
 *
 * Grammar (informal — see grammar.md for full reference):
 *
 *   model        ::= (packageDecl | diagramMeta | <skipped>)*
 *   packageDecl  ::= "package" qName "{" packageBody* "}"
 *   packageBody  ::= portDef | partDef | actionDef | activityDef | <skipped>
 *   #diagram     ::= "#" "diagram" "{" diagramField* "}"
 *
 * The grammar is intentionally permissive: anything we don't recognise inside
 * a brace-delimited block is silently skipped at the matching `{` … `}` depth,
 * preserving the behaviour of the previous combinator parser.
 */

import {
  CstParser, Lexer, createToken, EOF,
  type IToken, type CstNode, type ICstVisitor,
} from "chevrotain";
import type {
  Role, DiagramType,
  PortDef, PortUsage, PartUsage, ConnectionUsage,
  PartDef, ActionDef, ActionUsage, ObjectNode,
  DecisionNode, MergeNode, FlowUsage, SuccessionUsage,
  ActivityDef, PackageDecl, DiagramMeta, Model,
} from "./types.ts";

// ── Tokens ──────────────────────────────────────────────────────────────────

const Identifier = createToken({ name: "Identifier", pattern: /[A-Za-z_][\w]*/ });

// Keyword factory: keywords look like identifiers, so use longer_alt for the
// "longest match wins" behaviour Chevrotain expects.
const kw = (word: string) =>
  createToken({ name: word[0].toUpperCase() + word.slice(1), pattern: new RegExp(`${word}\\b`), longer_alt: Identifier });

const Package    = kw("package");
const Port       = kw("port");
const Part       = kw("part");
const Action     = kw("action");
const Activity   = kw("activity");
const Def        = kw("def");
const Connection = kw("connection");
const Connect    = kw("connect");
const To         = kw("to");
const From       = kw("from");
const Via        = kw("via");
const InKw       = kw("in");
const OutKw      = kw("out");
const InoutKw    = kw("inout");
const Object_    = kw("object");
const Decision   = kw("decision");
const Merge      = kw("merge");
const Flow       = kw("flow");
const Succession = kw("succession");
const Then       = kw("then");
const Diagram    = kw("diagram");
const Type_      = kw("type");
const Title      = kw("title");
const Name       = kw("name");
const Direction  = kw("direction");
const Layout     = kw("layout");
const Render     = kw("render");
const Show       = kw("show");
const As         = kw("as");
const Tooltip    = kw("tooltip");

// Punctuation
const LBrace = createToken({ name: "LBrace", pattern: /\{/ });
const RBrace = createToken({ name: "RBrace", pattern: /\}/ });
const Colon  = createToken({ name: "Colon",  pattern: /:/ });
const Semi   = createToken({ name: "Semi",   pattern: /;/ });
const Comma  = createToken({ name: "Comma",  pattern: /,/ });
const Equals = createToken({ name: "Equals", pattern: /=/ });
const Dot    = createToken({ name: "Dot",    pattern: /\./ });
const LAngle = createToken({ name: "LAngle", pattern: /</ });
const RAngle = createToken({ name: "RAngle", pattern: />/ });
const LBrack = createToken({ name: "LBrack", pattern: /\[/ });
const RBrack = createToken({ name: "RBrack", pattern: /\]/ });
const Hash   = createToken({ name: "Hash",   pattern: /#/ });

// Literals & whitespace
const StringLiteral = createToken({
  name: "StringLiteral",
  pattern: /"(?:[^"\\]|\\.)*"/,
});
const WhiteSpace  = createToken({ name: "WhiteSpace",  pattern: /\s+/, group: Lexer.SKIPPED });
const LineComment = createToken({ name: "LineComment", pattern: /\/\/[^\n]*/, group: Lexer.SKIPPED });
const BlockComment= createToken({ name: "BlockComment",pattern: /\/\*[\s\S]*?\*\//, group: Lexer.SKIPPED });

// Order matters: longer/more-specific patterns first.
const allTokens = [
  WhiteSpace, LineComment, BlockComment,
  StringLiteral,
  // keywords (must come before Identifier; Chevrotain uses longer_alt for ties)
  Package, Port, Part, Action, Activity, Def, Connection, Connect,
  To, From, Via, InKw, OutKw, InoutKw, Object_, Decision, Merge, Flow,
  Succession, Then, Diagram, Type_, Title, Name, Direction, Layout,
  Render, Show, As, Tooltip,
  Identifier,
  LBrace, RBrace, Colon, Semi, Comma, Equals, Dot, LAngle, RAngle,
  LBrack, RBrack, Hash,
];

const SysmlLexer = new Lexer(allTokens);

// ── Parser (CST) ────────────────────────────────────────────────────────────

class SysmlParser extends CstParser {
  constructor() {
    super(allTokens, { recoveryEnabled: false });
    this.performSelfAnalysis();
  }

  // model ::= (packageDecl | diagramMeta | <skip>)*
  public model = this.RULE("model", () => {
    this.MANY(() => {
      this.OR({
        IGNORE_AMBIGUITIES: true,
        DEF: [
          { ALT: () => this.SUBRULE(this.packageDecl) },
          { ALT: () => this.SUBRULE(this.diagramMeta) },
          { ALT: () => this.SUBRULE(this.skipTopLevel) },
        ],
      });
    });
  });

  // qName ::= Identifier ( "." Identifier | "<" Identifier ">" )*
  private qName = this.RULE("qName", () => {
    this.CONSUME(Identifier);
    this.MANY(() => {
      this.OR([
        { ALT: () => { this.CONSUME(Dot); this.CONSUME2(Identifier); } },
        { ALT: () => { this.CONSUME(LAngle); this.CONSUME3(Identifier); this.OPTION(() => this.CONSUME(RAngle)); } },
      ]);
    });
  });

  // strOrIdent ::= StringLiteral | qName
  private strOrIdent = this.RULE("strOrIdent", () => {
    this.OR([
      { ALT: () => this.CONSUME(StringLiteral) },
      { ALT: () => this.SUBRULE(this.qName) },
    ]);
  });

  // packageDecl ::= "package" qName "{" packageBody* "}"
  private packageDecl = this.RULE("packageDecl", () => {
    this.CONSUME(Package);
    this.SUBRULE(this.qName);
    this.CONSUME(LBrace);
    this.MANY(() => this.SUBRULE(this.packageBody));
    this.CONSUME(RBrace);
  });

  private packageBody = this.RULE("packageBody", () => {
    this.OR({
      IGNORE_AMBIGUITIES: true,
      DEF: [
        { GATE: () => this.LA(1).tokenType === Port     && this.LA(2).tokenType === Def, ALT: () => this.SUBRULE(this.portDef) },
        { GATE: () => this.LA(1).tokenType === Part     && this.LA(2).tokenType === Def, ALT: () => this.SUBRULE(this.partDef) },
        { GATE: () => this.LA(1).tokenType === Action   && this.LA(2).tokenType === Def, ALT: () => this.SUBRULE(this.actionDef) },
        { GATE: () => this.LA(1).tokenType === Activity && this.LA(2).tokenType === Def, ALT: () => this.SUBRULE(this.activityDef) },
        { ALT: () => this.SUBRULE(this.skipBlock) },
      ],
    });
  });

  // portDef ::= "port" "def" name ( "{" ... "}" | ";" )?
  private portDef = this.RULE("portDef", () => {
    this.CONSUME(Port);
    this.CONSUME(Def);
    this.SUBRULE(this.nameWord);
    this.OPTION(() => this.SUBRULE(this.skipBlockOrSemi));
  });

  // partDef ::= "part" "def" qName ( "{" partDefBody* "}" | ";" )?
  private partDef = this.RULE("partDef", () => {
    this.CONSUME(Part);
    this.CONSUME(Def);
    this.SUBRULE(this.qName);
    this.OPTION(() => {
      this.OR([
        { ALT: () => {
            this.CONSUME(LBrace);
            this.MANY(() => this.SUBRULE(this.partDefBody));
            this.CONSUME(RBrace);
          } },
        { ALT: () => this.CONSUME(Semi) },
      ]);
    });
  });

  private partDefBody = this.RULE("partDefBody", () => {
    this.OR({
      IGNORE_AMBIGUITIES: true,
      DEF: [
        { ALT: () => this.SUBRULE(this.partUsage) },
        { ALT: () => this.SUBRULE(this.portUsage) },
        { ALT: () => this.SUBRULE(this.connectionUsage) },
        { ALT: () => this.SUBRULE(this.skipBlock) },
      ],
    });
  });

  private partUsage = this.RULE("partUsage", () => {
    this.CONSUME(Part);
    this.SUBRULE(this.nameWord);
    this.OPTION(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION1(() => {
      this.OR([
        { ALT: () => {
            this.CONSUME(LBrace);
            this.MANY(() => this.SUBRULE(this.partUsageBody));
            this.CONSUME(RBrace);
          } },
        { ALT: () => this.CONSUME(Semi) },
      ]);
    });
  });

  private partUsageBody = this.RULE("partUsageBody", () => {
    this.OR({
      IGNORE_AMBIGUITIES: true,
      DEF: [
        { ALT: () => this.SUBRULE(this.portUsage) },
        { ALT: () => this.SUBRULE(this.skipBlock) },
      ],
    });
  });

  private portUsage = this.RULE("portUsage", () => {
    this.CONSUME(Port);
    this.OPTION(() => this.SUBRULE(this.direction));
    this.SUBRULE(this.nameWord);
    this.OPTION1(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION2(() => this.CONSUME(Semi));
  });

  private direction = this.RULE("direction", () => {
    this.OR([
      { ALT: () => this.CONSUME(InKw) },
      { ALT: () => this.CONSUME(OutKw) },
      { ALT: () => this.CONSUME(InoutKw) },
    ]);
  });

  // connection ::= "connection" Identifier? "connect" path "to" path ("via" qName)? (":" strOrIdent)? ";"?
  private connectionUsage = this.RULE("connectionUsage", () => {
    this.CONSUME(Connection);
    this.OPTION({
      GATE: () => this.LA(1).tokenType === Identifier && this.LA(2).tokenType === Connect,
      DEF:  () => this.CONSUME(Identifier),
    });
    this.CONSUME(Connect);
    this.SUBRULE(this.path);
    this.CONSUME(To);
    this.SUBRULE2(this.path);
    this.OPTION1(() => { this.CONSUME(Via); this.SUBRULE(this.qName); });
    this.OPTION2(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION3(() => this.CONSUME(Semi));
  });

  // path ::= word ( "." word )* — words include keywords that overlap with
  // names (e.g. "merge", "decision", "type") since the original grammar was
  // tokenisation-blind to keyword status in name positions.
  private path = this.RULE("path", () => {
    this.SUBRULE(this.nameWord);
    this.MANY(() => { this.CONSUME(Dot); this.SUBRULE2(this.nameWord); });
  });

  private nameWord = this.RULE("nameWord", () => {
    this.OR([
      { ALT: () => this.CONSUME(Identifier) },
      { ALT: () => this.CONSUME(Type_) },
      { ALT: () => this.CONSUME(Decision) },
      { ALT: () => this.CONSUME(Merge) },
      { ALT: () => this.CONSUME(Name) },
      { ALT: () => this.CONSUME(Title) },
      { ALT: () => this.CONSUME(Direction) },
      { ALT: () => this.CONSUME(Layout) },
      { ALT: () => this.CONSUME(Render) },
    ]);
  });

  // actionDef ::= "action" "def" qName ( "{" actionDefBody* "}" | ";" )?
  private actionDef = this.RULE("actionDef", () => {
    this.CONSUME(Action);
    this.CONSUME(Def);
    this.SUBRULE(this.qName);
    this.OPTION(() => {
      this.OR([
        { ALT: () => {
            this.CONSUME(LBrace);
            this.MANY(() => this.SUBRULE(this.actionDefBody));
            this.CONSUME(RBrace);
          } },
        { ALT: () => this.CONSUME(Semi) },
      ]);
    });
  });

  private actionDefBody = this.RULE("actionDefBody", () => {
    this.OR({
      IGNORE_AMBIGUITIES: true,
      DEF: [
        { ALT: () => this.SUBRULE(this.pinDecl) },
        { ALT: () => this.SUBRULE(this.skipBlock) },
      ],
    });
  });

  // pin ::= direction name (":" strOrIdent)? ";"?
  private pinDecl = this.RULE("pinDecl", () => {
    this.SUBRULE(this.direction);
    this.SUBRULE(this.nameWord);
    this.OPTION(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION1(() => this.CONSUME(Semi));
  });

  // activityDef ::= "activity" "def" qName ( "{" activityBody* "}" | ";" )?
  private activityDef = this.RULE("activityDef", () => {
    this.CONSUME(Activity);
    this.CONSUME(Def);
    this.SUBRULE(this.qName);
    this.OPTION(() => {
      this.OR([
        { ALT: () => {
            this.CONSUME(LBrace);
            this.MANY(() => this.SUBRULE(this.activityBody));
            this.CONSUME(RBrace);
          } },
        { ALT: () => this.CONSUME(Semi) },
      ]);
    });
  });

  private activityBody = this.RULE("activityBody", () => {
    this.OR({
      IGNORE_AMBIGUITIES: true,
      DEF: [
        { ALT: () => this.SUBRULE(this.actionUsage) },
        { ALT: () => this.SUBRULE(this.objectNode) },
        { ALT: () => this.SUBRULE(this.decisionNode) },
        { ALT: () => this.SUBRULE(this.mergeNode) },
        { ALT: () => this.SUBRULE(this.flowUsage) },
        { ALT: () => this.SUBRULE(this.successionUsage) },
        { ALT: () => this.SUBRULE(this.skipBlock) },
      ],
    });
  });

  private actionUsage = this.RULE("actionUsage", () => {
    this.CONSUME(Action);
    this.SUBRULE(this.nameWord);
    this.OPTION(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION1(() => this.CONSUME(Semi));
  });

  private objectNode = this.RULE("objectNode", () => {
    this.CONSUME(Object_);
    this.SUBRULE(this.nameWord);
    this.OPTION(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION1(() => this.CONSUME(Semi));
  });

  private decisionNode = this.RULE("decisionNode", () => {
    this.CONSUME(Decision);
    this.SUBRULE(this.nameWord);
    this.OPTION(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION1(() => this.CONSUME(Semi));
  });

  private mergeNode = this.RULE("mergeNode", () => {
    this.CONSUME(Merge);
    this.SUBRULE(this.nameWord);
    this.OPTION(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION1(() => this.CONSUME(Semi));
  });

  private flowUsage = this.RULE("flowUsage", () => {
    this.CONSUME(Flow);
    this.CONSUME(From);
    this.SUBRULE(this.path);
    this.CONSUME(To);
    this.SUBRULE2(this.path);
    this.OPTION(() => { this.CONSUME(Colon); this.SUBRULE(this.strOrIdent); });
    this.OPTION1(() => this.CONSUME(Semi));
  });

  private successionUsage = this.RULE("successionUsage", () => {
    this.CONSUME(Succession);
    this.SUBRULE(this.path);
    this.CONSUME(Then);
    this.SUBRULE2(this.path);
    this.OPTION(() => this.CONSUME(Semi));
  });

  // diagramMeta ::= "#" "diagram" "{" diagramField* "}"
  private diagramMeta = this.RULE("diagramMeta", () => {
    this.CONSUME(Hash);
    this.CONSUME(Diagram);
    this.CONSUME(LBrace);
    this.MANY(() => this.SUBRULE(this.diagramField));
    this.CONSUME(RBrace);
  });

  private diagramField = this.RULE("diagramField", () => {
    this.OR({
      IGNORE_AMBIGUITIES: true,
      DEF: [
        { ALT: () => this.SUBRULE(this.kvField) },
        { ALT: () => this.SUBRULE(this.showField) },
        { ALT: () => this.SUBRULE(this.tooltipField) },
        { ALT: () => this.SUBRULE(this.skipBlock) },
      ],
    });
  });

  private kvField = this.RULE("kvField", () => {
    this.OR([
      { ALT: () => this.CONSUME(Type_) },
      { ALT: () => this.CONSUME(Title) },
      { ALT: () => this.CONSUME(Name) },
      { ALT: () => this.CONSUME(Direction) },
      { ALT: () => this.CONSUME(Layout) },
      { ALT: () => this.CONSUME(Render) },
    ]);
    this.OPTION(() => this.CONSUME(Equals));
    this.SUBRULE(this.kvValue);
  });

  // Values for diagram-meta fields are intentionally permissive: many of
  // them ("activity", "ibd", "LR", "elk", …) lex as identifiers or as
  // keywords depending on the word.  Accept either, plus quoted strings.
  private kvValue = this.RULE("kvValue", () => {
    this.OR([
      { ALT: () => this.CONSUME(StringLiteral) },
      { ALT: () => this.CONSUME(Identifier) },
      { ALT: () => this.SUBRULE(this.keywordWord) },
    ]);
  });

  // Any keyword treated as a plain word — used wherever value/role positions
  // overlap with a reserved word in the surrounding grammar.
  private keywordWord = this.RULE("keywordWord", () => {
    this.OR([
      { ALT: () => this.CONSUME(Package) },
      { ALT: () => this.CONSUME(Port) },
      { ALT: () => this.CONSUME(Part) },
      { ALT: () => this.CONSUME(Action) },
      { ALT: () => this.CONSUME(Activity) },
      { ALT: () => this.CONSUME(Def) },
      { ALT: () => this.CONSUME(Connection) },
      { ALT: () => this.CONSUME(Connect) },
      { ALT: () => this.CONSUME(To) },
      { ALT: () => this.CONSUME(From) },
      { ALT: () => this.CONSUME(Via) },
      { ALT: () => this.CONSUME(InKw) },
      { ALT: () => this.CONSUME(OutKw) },
      { ALT: () => this.CONSUME(InoutKw) },
      { ALT: () => this.CONSUME(Object_) },
      { ALT: () => this.CONSUME(Decision) },
      { ALT: () => this.CONSUME(Merge) },
      { ALT: () => this.CONSUME(Flow) },
      { ALT: () => this.CONSUME(Succession) },
      { ALT: () => this.CONSUME(Then) },
      { ALT: () => this.CONSUME(Diagram) },
      { ALT: () => this.CONSUME(Type_) },
      { ALT: () => this.CONSUME(Title) },
      { ALT: () => this.CONSUME(Name) },
      { ALT: () => this.CONSUME(Direction) },
      { ALT: () => this.CONSUME(Layout) },
      { ALT: () => this.CONSUME(Render) },
      { ALT: () => this.CONSUME(Show) },
      { ALT: () => this.CONSUME(As) },
      { ALT: () => this.CONSUME(Tooltip) },
    ]);
  });

  private showField = this.RULE("showField", () => {
    this.CONSUME(Show);
    this.SUBRULE(this.path);
    this.CONSUME(As);
    this.SUBRULE(this.roleName);
  });

  // Role names overlap with keywords ("type", "decision", "merge", ...).
  // Accept any of them as a role token in show fields.
  private roleName = this.RULE("roleName", () => {
    this.OR([
      { ALT: () => this.CONSUME(Identifier) },
      { ALT: () => this.CONSUME(Type_) },
      { ALT: () => this.CONSUME(Decision) },
      { ALT: () => this.CONSUME(Merge) },
    ]);
  });

  private tooltipField = this.RULE("tooltipField", () => {
    this.CONSUME(Tooltip);
    this.SUBRULE(this.path);
    this.OPTION(() => this.CONSUME(Equals));
    this.SUBRULE(this.strOrIdent);
  });

  // ── Skip helpers ───────────────────────────────────────────────────────────

  // Matches a single token at the top level (used to silently skip stray
  // tokens that are neither `package` nor `#diagram`).  Never matches `{`/`}`
  // so the structural backbone of the file is always respected.
  private skipTopLevel = this.RULE("skipTopLevel", () => {
    this.OR([
      { ALT: () => this.CONSUME(Identifier) },
      { ALT: () => this.CONSUME(StringLiteral) },
      { ALT: () => this.CONSUME(Semi) },
      { ALT: () => this.CONSUME(Colon) },
      { ALT: () => this.CONSUME(Comma) },
      { ALT: () => this.CONSUME(Equals) },
      { ALT: () => this.CONSUME(Dot) },
      { ALT: () => this.CONSUME(LBrack) },
      { ALT: () => this.CONSUME(RBrack) },
    ]);
  });

  // Skips an unrecognised body item: either a balanced "{…}" block or a run
  // of tokens up to the next ";" (without crossing a "}" boundary).
  private skipBlock = this.RULE("skipBlock", () => {
    this.OR([
      { ALT: () => this.SUBRULE(this.balancedBlock) },
      { ALT: () => this.SUBRULE(this.skipUntilSemi) },
    ]);
  });

  private skipBlockOrSemi = this.RULE("skipBlockOrSemi", () => {
    this.OR([
      { ALT: () => this.SUBRULE(this.balancedBlock) },
      { ALT: () => this.CONSUME(Semi) },
    ]);
  });

  private balancedBlock = this.RULE("balancedBlock", () => {
    this.CONSUME(LBrace);
    this.MANY(() => {
      this.OR([
        { ALT: () => this.SUBRULE(this.balancedBlock) },
        { ALT: () => this.SUBRULE(this.anyTokenButBraces) },
      ]);
    });
    this.CONSUME(RBrace);
  });

  private skipUntilSemi = this.RULE("skipUntilSemi", () => {
    this.AT_LEAST_ONE(() => this.SUBRULE(this.anyTokenButBracesOrSemi));
    this.OPTION(() => this.CONSUME(Semi));
  });

  // Any token except "{" "}" — used inside balanced blocks.
  private anyTokenButBraces = this.RULE("anyTokenButBraces", () => {
    this.OR([
      { ALT: () => this.CONSUME(Identifier) },
      { ALT: () => this.CONSUME(StringLiteral) },
      { ALT: () => this.CONSUME(Semi) },
      { ALT: () => this.CONSUME(Colon) },
      { ALT: () => this.CONSUME(Comma) },
      { ALT: () => this.CONSUME(Equals) },
      { ALT: () => this.CONSUME(Dot) },
      { ALT: () => this.CONSUME(LAngle) },
      { ALT: () => this.CONSUME(RAngle) },
      { ALT: () => this.CONSUME(LBrack) },
      { ALT: () => this.CONSUME(RBrack) },
      { ALT: () => this.CONSUME(Hash) },
      // any keyword can appear textually inside skipped content
      { ALT: () => this.CONSUME(Package) },
      { ALT: () => this.CONSUME(Port) },
      { ALT: () => this.CONSUME(Part) },
      { ALT: () => this.CONSUME(Action) },
      { ALT: () => this.CONSUME(Activity) },
      { ALT: () => this.CONSUME(Def) },
      { ALT: () => this.CONSUME(Connection) },
      { ALT: () => this.CONSUME(Connect) },
      { ALT: () => this.CONSUME(To) },
      { ALT: () => this.CONSUME(From) },
      { ALT: () => this.CONSUME(Via) },
      { ALT: () => this.CONSUME(InKw) },
      { ALT: () => this.CONSUME(OutKw) },
      { ALT: () => this.CONSUME(InoutKw) },
      { ALT: () => this.CONSUME(Object_) },
      { ALT: () => this.CONSUME(Decision) },
      { ALT: () => this.CONSUME(Merge) },
      { ALT: () => this.CONSUME(Flow) },
      { ALT: () => this.CONSUME(Succession) },
      { ALT: () => this.CONSUME(Then) },
      { ALT: () => this.CONSUME(Diagram) },
      { ALT: () => this.CONSUME(Type_) },
      { ALT: () => this.CONSUME(Title) },
      { ALT: () => this.CONSUME(Name) },
      { ALT: () => this.CONSUME(Direction) },
      { ALT: () => this.CONSUME(Layout) },
      { ALT: () => this.CONSUME(Render) },
      { ALT: () => this.CONSUME(Show) },
      { ALT: () => this.CONSUME(As) },
      { ALT: () => this.CONSUME(Tooltip) },
    ]);
  });

  // Like anyTokenButBraces but also excludes ";" — used by skipUntilSemi.
  private anyTokenButBracesOrSemi = this.RULE("anyTokenButBracesOrSemi", () => {
    this.OR([
      { ALT: () => this.CONSUME(Identifier) },
      { ALT: () => this.CONSUME(StringLiteral) },
      { ALT: () => this.CONSUME(Colon) },
      { ALT: () => this.CONSUME(Comma) },
      { ALT: () => this.CONSUME(Equals) },
      { ALT: () => this.CONSUME(Dot) },
      { ALT: () => this.CONSUME(LAngle) },
      { ALT: () => this.CONSUME(RAngle) },
      { ALT: () => this.CONSUME(LBrack) },
      { ALT: () => this.CONSUME(RBrack) },
      { ALT: () => this.CONSUME(Hash) },
      { ALT: () => this.CONSUME(Package) },
      { ALT: () => this.CONSUME(Port) },
      { ALT: () => this.CONSUME(Part) },
      { ALT: () => this.CONSUME(Action) },
      { ALT: () => this.CONSUME(Activity) },
      { ALT: () => this.CONSUME(Def) },
      { ALT: () => this.CONSUME(Connection) },
      { ALT: () => this.CONSUME(Connect) },
      { ALT: () => this.CONSUME(To) },
      { ALT: () => this.CONSUME(From) },
      { ALT: () => this.CONSUME(Via) },
      { ALT: () => this.CONSUME(InKw) },
      { ALT: () => this.CONSUME(OutKw) },
      { ALT: () => this.CONSUME(InoutKw) },
      { ALT: () => this.CONSUME(Object_) },
      { ALT: () => this.CONSUME(Decision) },
      { ALT: () => this.CONSUME(Merge) },
      { ALT: () => this.CONSUME(Flow) },
      { ALT: () => this.CONSUME(Succession) },
      { ALT: () => this.CONSUME(Then) },
      { ALT: () => this.CONSUME(Diagram) },
      { ALT: () => this.CONSUME(Type_) },
      { ALT: () => this.CONSUME(Title) },
      { ALT: () => this.CONSUME(Name) },
      { ALT: () => this.CONSUME(Direction) },
      { ALT: () => this.CONSUME(Layout) },
      { ALT: () => this.CONSUME(Render) },
      { ALT: () => this.CONSUME(Show) },
      { ALT: () => this.CONSUME(As) },
      { ALT: () => this.CONSUME(Tooltip) },
    ]);
  });
}

const parserInstance = new SysmlParser();
const BaseVisitor = parserInstance.getBaseCstVisitorConstructorWithDefaults();

// ── CST → AST visitor ───────────────────────────────────────────────────────

const tokText = (t: IToken | undefined): string => t ? t.image : "";
const stripQuotes = (s: string): string => s.slice(1, -1).replace(/\\"/g, '"');

class AstBuilder extends BaseVisitor {
  constructor() {
    super();
    this.validateVisitor();
  }

  model(ctx: any): Model {
    const packages: PackageDecl[] = [];
    let diagram: DiagramMeta = { diagType: "activity", shows: {}, tooltips: {} };
    for (const pkg of ctx.packageDecl ?? []) packages.push(this.visit(pkg));
    if (ctx.diagramMeta?.length) diagram = this.visit(ctx.diagramMeta[0]);
    return { packages, diagram };
  }

  qName(ctx: any): string {
    const ids: IToken[] = ctx.Identifier ?? [];
    if (ids.length === 0) return "";
    let out = ids[0].image;
    let idIdx = 1;
    const dots: IToken[] = ctx.Dot ?? [];
    const angles: IToken[] = ctx.LAngle ?? [];
    // Reconstruct using token offsets to preserve order of "." and "<…>" suffixes.
    const suffixes: { offset: number; text: string }[] = [];
    for (const d of dots) {
      const next = ids[idIdx++];
      suffixes.push({ offset: d.startOffset, text: `.${next?.image ?? ""}` });
    }
    for (const a of angles) {
      const inner = ids[idIdx++];
      // optional ">"
      const closeArr: IToken[] = ctx.RAngle ?? [];
      const close = closeArr.shift();
      suffixes.push({ offset: a.startOffset, text: `<${inner?.image ?? ""}${close ? ">" : ""}` });
    }
    suffixes.sort((x, y) => x.offset - y.offset);
    return out + suffixes.map(s => s.text).join("");
  }

  strOrIdent(ctx: any): string {
    if (ctx.StringLiteral) return stripQuotes(ctx.StringLiteral[0].image);
    return this.visit(ctx.qName);
  }

  path(ctx: any): string {
    const segs: CstNode[] = ctx.nameWord ?? [];
    return segs.map((n) => this.visit(n)).join(".");
  }

  nameWord(ctx: any): string {
    for (const key of Object.keys(ctx)) {
      const arr = ctx[key];
      if (Array.isArray(arr) && arr.length > 0 && (arr[0] as IToken).image) {
        return (arr[0] as IToken).image;
      }
    }
    return "";
  }

  direction(ctx: any): "in" | "out" | "inout" {
    if (ctx.In)    return "in";
    if (ctx.Out)   return "out";
    if (ctx.Inout) return "inout";
    return "in";
  }

  packageDecl(ctx: any): PackageDecl {
    const name = this.visit(ctx.qName);
    const items = (ctx.packageBody ?? []).map((b: CstNode) => this.visit(b)).filter(Boolean);
    return {
      name,
      portDefs:     items.filter((x: any) => x?.kind === "portDef"),
      partDefs:     items.filter((x: any) => x?.kind === "partDef"),
      actionDefs:   items.filter((x: any) => x?.kind === "actionDef"),
      activityDefs: items.filter((x: any) => x?.kind === "activityDef"),
    };
  }

  packageBody(ctx: any): unknown {
    if (ctx.portDef)     return this.visit(ctx.portDef);
    if (ctx.partDef)     return this.visit(ctx.partDef);
    if (ctx.actionDef)   return this.visit(ctx.actionDef);
    if (ctx.activityDef) return this.visit(ctx.activityDef);
    return null;
  }

  portDef(ctx: any): PortDef {
    return { kind: "portDef", name: this.visit(ctx.nameWord) };
  }

  partDef(ctx: any): PartDef {
    const name = this.visit(ctx.qName);
    const bodies: unknown[] = (ctx.partDefBody ?? []).map((b: CstNode) => this.visit(b)).filter(Boolean);
    return {
      kind: "partDef",
      name,
      parts:       bodies.filter((x: any) => x?.kind === "part") as PartUsage[],
      ports:       bodies.filter((x: any) => x?.kind === "port") as PortUsage[],
      connections: bodies.filter((x: any) => x?.kind === "connection") as ConnectionUsage[],
    };
  }

  partDefBody(ctx: any): unknown {
    if (ctx.partUsage)       return this.visit(ctx.partUsage);
    if (ctx.portUsage)       return this.visit(ctx.portUsage);
    if (ctx.connectionUsage) return this.visit(ctx.connectionUsage);
    return null;
  }

  partUsage(ctx: any): PartUsage {
    const id   = this.visit(ctx.nameWord);
    const type = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : id;
    const ports: PortUsage[] = (ctx.partUsageBody ?? [])
      .map((b: CstNode) => this.visit(b))
      .filter((x: any) => x?.kind === "port");
    return { kind: "part", id, type, ports };
  }

  partUsageBody(ctx: any): unknown {
    if (ctx.portUsage) return this.visit(ctx.portUsage);
    return null;
  }

  portUsage(ctx: any): PortUsage {
    const direction = ctx.direction ? this.visit(ctx.direction) : undefined;
    const id   = this.visit(ctx.nameWord);
    const type = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : id;
    return { kind: "port", id, type, direction };
  }

  connectionUsage(ctx: any): ConnectionUsage {
    // Identifier may be the optional connection id or part of paths; the
    // grammar guarantees the first Identifier (when present at all) is the
    // optional connection id thanks to the GATE on OPTION.
    const idTokens: IToken[] = ctx.Identifier ?? [];
    // Heuristic: Chevrotain only stores tokens consumed *directly* by this
    // rule (not by sub-rules), so ctx.Identifier holds at most the optional
    // connection id.
    const id = idTokens.length > 0 ? idTokens[0].image : undefined;
    const paths = (ctx.path ?? []).map((p: CstNode) => this.visit(p));
    const [from, to] = paths;
    const via   = ctx.qName ? this.visit(ctx.qName) : undefined;
    const label = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : undefined;
    return { kind: "connection", id, from, to, via, label };
  }

  actionDef(ctx: any): ActionDef {
    const name = this.visit(ctx.qName);
    const pins: PortUsage[] = (ctx.actionDefBody ?? [])
      .map((b: CstNode) => this.visit(b))
      .filter((x: any) => x?.kind === "port");
    return { kind: "actionDef", name, pins };
  }

  actionDefBody(ctx: any): unknown {
    if (ctx.pinDecl) return this.visit(ctx.pinDecl);
    return null;
  }

  pinDecl(ctx: any): PortUsage {
    const direction = this.visit(ctx.direction);
    const id   = this.visit(ctx.nameWord);
    const type = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : id;
    return { kind: "port", id, type, direction };
  }

  activityDef(ctx: any): ActivityDef {
    const name = this.visit(ctx.qName);
    const items: unknown[] = (ctx.activityBody ?? []).map((b: CstNode) => this.visit(b)).filter(Boolean);
    return {
      kind: "activityDef",
      name,
      actions:     items.filter((x: any) => x?.kind === "action")     as ActionUsage[],
      objects:     items.filter((x: any) => x?.kind === "object")     as ObjectNode[],
      decisions:   items.filter((x: any) => x?.kind === "decision")   as DecisionNode[],
      merges:      items.filter((x: any) => x?.kind === "merge")      as MergeNode[],
      flows:       items.filter((x: any) => x?.kind === "flow")       as FlowUsage[],
      successions: items.filter((x: any) => x?.kind === "succession") as SuccessionUsage[],
    };
  }

  activityBody(ctx: any): unknown {
    if (ctx.actionUsage)     return this.visit(ctx.actionUsage);
    if (ctx.objectNode)      return this.visit(ctx.objectNode);
    if (ctx.decisionNode)    return this.visit(ctx.decisionNode);
    if (ctx.mergeNode)       return this.visit(ctx.mergeNode);
    if (ctx.flowUsage)       return this.visit(ctx.flowUsage);
    if (ctx.successionUsage) return this.visit(ctx.successionUsage);
    return null;
  }

  actionUsage(ctx: any): ActionUsage {
    const id   = this.visit(ctx.nameWord);
    const type = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : id;
    return { kind: "action", id, type };
  }

  objectNode(ctx: any): ObjectNode {
    const id   = this.visit(ctx.nameWord);
    const type = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : id;
    return { kind: "object", id, type };
  }

  decisionNode(ctx: any): DecisionNode {
    const id    = this.visit(ctx.nameWord);
    const label = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : undefined;
    return { kind: "decision", id, label };
  }

  mergeNode(ctx: any): MergeNode {
    const id    = this.visit(ctx.nameWord);
    const label = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : undefined;
    return { kind: "merge", id, label };
  }

  flowUsage(ctx: any): FlowUsage {
    const [from, to] = (ctx.path ?? []).map((p: CstNode) => this.visit(p));
    const label = ctx.strOrIdent ? this.visit(ctx.strOrIdent) : undefined;
    return { kind: "flow", from, to, label };
  }

  successionUsage(ctx: any): SuccessionUsage {
    const [from, to] = (ctx.path ?? []).map((p: CstNode) => this.visit(p));
    return { kind: "succession", from, to };
  }

  diagramMeta(ctx: any): DiagramMeta {
    const out: DiagramMeta = { diagType: "activity", shows: {}, tooltips: {} };
    for (const f of ctx.diagramField ?? []) {
      const v = this.visit(f);
      if (!v) continue;
      if      (v.k === "type")      out.diagType  = v.v as DiagramType;
      else if (v.k === "title")     out.title     = v.v;
      else if (v.k === "name")      out.name      = v.v;
      else if (v.k === "direction") out.direction = v.v as "LR" | "TB";
      else if (v.k === "layout")    out.layout    = v.v as "dagre" | "elk";
      else if (v.k === "render")    out.render    = v.v;
      else if (v.k === "show")      out.shows[v.id]    = v.role;
      else if (v.k === "tooltip")   out.tooltips[v.id] = v.text;
    }
    return out;
  }

  diagramField(ctx: any): unknown {
    if (ctx.kvField)      return this.visit(ctx.kvField);
    if (ctx.showField)    return this.visit(ctx.showField);
    if (ctx.tooltipField) return this.visit(ctx.tooltipField);
    return null;
  }

  kvField(ctx: any): { k: string; v: string } {
    const key =
      ctx.Type      ? "type"      :
      ctx.Title     ? "title"     :
      ctx.Name      ? "name"      :
      ctx.Direction ? "direction" :
      ctx.Layout    ? "layout"    :
      ctx.Render    ? "render"    : "";
    return { k: key, v: this.visit(ctx.kvValue) };
  }

  kvValue(ctx: any): string {
    if (ctx.StringLiteral) return stripQuotes(ctx.StringLiteral[0].image);
    if (ctx.Identifier)    return ctx.Identifier[0].image;
    if (ctx.keywordWord)   return this.visit(ctx.keywordWord);
    return "";
  }

  keywordWord(ctx: any): string {
    // ctx has exactly one keyword-token bucket populated.
    for (const key of Object.keys(ctx)) {
      const arr = ctx[key];
      if (Array.isArray(arr) && arr.length > 0 && (arr[0] as IToken).image) {
        return (arr[0] as IToken).image;
      }
    }
    return "";
  }

  showField(ctx: any): { k: "show"; id: string; role: Role } {
    const id   = this.visit(ctx.path);
    const role = this.visit(ctx.roleName) as Role;
    return { k: "show", id, role };
  }

  roleName(ctx: any): string {
    if (ctx.Identifier) return ctx.Identifier[0].image;
    if (ctx.Type)       return "type";
    if (ctx.Decision)   return "decision";
    if (ctx.Merge)      return "merge";
    return "";
  }

  tooltipField(ctx: any): { k: "tooltip"; id: string; text: string } {
    const id   = this.visit(ctx.path);
    const text = this.visit(ctx.strOrIdent);
    return { k: "tooltip", id, text };
  }

  // unused but required for default visitor coverage
  skipTopLevel(_ctx: any): null { return null; }
  skipBlock(_ctx: any): null { return null; }
  skipBlockOrSemi(_ctx: any): null { return null; }
  balancedBlock(_ctx: any): null { return null; }
  skipUntilSemi(_ctx: any): null { return null; }
  anyTokenButBraces(_ctx: any): null { return null; }
  anyTokenButBracesOrSemi(_ctx: any): null { return null; }
}

const astBuilder = new AstBuilder();

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Parse SysML v2 (subset) source text into a Model AST.
 * Throws on unrecoverable lexer or parser errors.
 */
export function parse(src: string): Model {
  const lex = SysmlLexer.tokenize(src);
  if (lex.errors.length > 0) {
    const e = lex.errors[0];
    throw new Error(`Lexer error at ${e.line}:${e.column}: ${e.message}`);
  }
  parserInstance.input = lex.tokens;
  const cst = parserInstance.model();
  if (parserInstance.errors.length > 0) {
    const e = parserInstance.errors[0];
    throw new Error(`Parse error: ${e.message} (token '${e.token?.image ?? "<eof>"}')`);
  }
  return astBuilder.visit(cst) as Model;
}
