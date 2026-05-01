grammar Sysml

entry Model:
    (packages+=Package | diagram=DiagramMeta)*;

// ── Packages ────────────────────────────────────────────────────────────────

Package:
    'package' name=QualifiedName '{'
        members+=PackageMember*
    '}';

PackageMember:
    PortDef | PartDef | ActionDef | ActivityDef;

PortDef:
    {infer PortDef} 'port' 'def' name=Name ';';

PartDef:
    {infer PartDef} 'part' 'def' name=QualifiedName (
        '{' members+=PartDefMember* '}'
        | ';'
    )?;

PartDefMember:
    PartUsage | InlinePort | ConnectionUsage | NoteUsage;

PartUsage:
    {infer PartUsage} 'part' id=Name (':' type=StrOrIdent)? (
        '{' ports+=InlinePort* '}'
        | ';'
    )?;

InlinePort:
    {infer InlinePort} 'port' direction=Direction? id=Name (':' type=StrOrIdent)? ';'?;

Direction returns string:
    'in' | 'out' | 'inout';

ConnectionUsage:
    {infer ConnectionUsage} 'connection' (cid=ID)? 'connect' from=Path 'to' to=Path
    ('via' via=QualifiedName)?
    (':' label=StrOrIdent)? ';'?;

// ── Action / Activity ───────────────────────────────────────────────────────

ActionDef:
    {infer ActionDef} 'action' 'def' name=QualifiedName (
        '{' pins+=PinDecl* '}'
        | ';'
    )?;

PinDecl:
    {infer PinDecl} direction=Direction id=Name (':' type=StrOrIdent)? ';'?;

ActivityDef:
    {infer ActivityDef} 'activity' 'def' name=QualifiedName (
        '{' members+=ActivityMember* '}'
        | ';'
    )?;

ActivityMember:
    ActionUsage | ObjectNode | DecisionNode | MergeNode | FlowUsage | SuccessionUsage | NoteUsage | LaneBlock;

// A swimlane: a labelled horizontal band that groups a set of nodes.
// Lanes are a purely visual grouping — they decorate the rendered diagram
// with a titled rectangle around their members.  In a layout with `direction
// = TB` (top→bottom) the lanes stack vertically and each lane's members lay
// out horizontally inside their band.
LaneBlock:
    {infer LaneBlock} 'lane' id=Name (':' label=StrOrIdent)? '='
        members+=Path (',' members+=Path)* ';'?;

ActionUsage:
    {infer ActionUsage} 'action' id=Name (':' type=StrOrIdent)? ';'?;

ObjectNode:
    {infer ObjectNode} 'object' id=Name (':' type=StrOrIdent)? ';'?;

DecisionNode:
    {infer DecisionNode} 'decision' id=Name (':' label=StrOrIdent)? ';'?;

MergeNode:
    {infer MergeNode} 'merge' id=Name (':' label=StrOrIdent)? ';'?;

FlowUsage:
    {infer FlowUsage} 'flow' 'from' from=Path 'to' to=Path (':' label=StrOrIdent)? ';'?;

SuccessionUsage:
    {infer SuccessionUsage} 'succession' from=Path 'then' to=Path ';'?;

// A free-floating note pinned to an existing node (UML-style).
// Renders as a yellow corner-folded rectangle with a dashed line
// connecting it to the target node.
NoteUsage:
    {infer NoteUsage} 'note' id=Name 'on' target=Path ':' text=StrOrIdent ';'?;

// ── #diagram block ──────────────────────────────────────────────────────────

DiagramMeta:
    {infer DiagramMeta} '#' 'diagram' '{'
        fields+=DiagramField*
    '}';

DiagramField:
    KvField | ShowField | TooltipField;

KvField:
    {infer KvField} key=KvKey '='? value=KvValue;

KvKey returns string:
    'type' | 'title' | 'name' | 'direction' | 'layout' | 'render';

ShowField:
    {infer ShowField} 'show' id=Path 'as' role=Name;

TooltipField:
    {infer TooltipField} 'tooltip' id=Path '='? text=StrOrIdent;

// ── Common atoms (data type rules: no AST nodes) ────────────────────────────

Name returns string:
    ID | 'type' | 'name' | 'title' | 'direction' | 'layout' | 'render'
    | 'merge' | 'decision' | 'activity' | 'note' | 'on' | 'lane';

KvValue returns string:
    STRING | ID | 'ibd' | 'in' | 'out' | 'inout'
    | 'type' | 'title' | 'name' | 'direction' | 'layout' | 'render'
    | 'activity' | 'merge' | 'decision';

StrOrIdent returns string:
    STRING | QualifiedName;

QualifiedName returns string:
    Name (
        '.' Name | '<' Name '>'?
    )*;

Path returns string:
    Name ('.' Name)*;

// ── Terminals ───────────────────────────────────────────────────────────────

terminal ID: /[A-Za-z_][\w]*/;
terminal STRING: /"(?:[^"\\]|\\.)*"/;

hidden terminal WS: /\s+/;
hidden terminal LINE_COMMENT: /\/\/[^\n\r]*/;
hidden terminal BLOCK_COMMENT: /\/\*[\s\S]*?\*\//;
