grammar Sysml

entry Model:
    packages+=Package*;

Package:
    'package' name=QualifiedName '{'
        members+=PackageMember*
    '}';

PackageMember:
    ImportDeclaration
    | PortDef
    | PartDef
    | ActionDef
    | MetadataDef
    | ViewDefinition
    | RenderingDefinition
    | ViewUsage;

ImportDeclaration:
    ('private' | 'public')? 'import' path=ImportPath ';'?;

ImportPath returns string:
    Name ('::' (Name | '*'))?;

PortDef:
    'port' 'def' name=Name ';'?;

MetadataDef:
    'metadata' 'def' name=Name (
        '{' attributes+=MetadataAttribute* '}'
        | ';'
    );

MetadataAttribute:
    'attribute' name=Name ':' type=Name ';'?;

ViewDefinition:
    'view' 'def' name=Name ('specializes' superType=Name)? (
        '{' '}'
        | ';'
    );

RenderingDefinition:
    'rendering' 'def' name=Name ('specializes' superType=Name)? (
        '{' '}'
        | ';'
    );

ViewUsage:
    metadata+=NodeMetadata*
    'view' id=Name ':' viewType=Name '{'
        members+=ViewMember*
    '}';

ViewMember:
    Documentation
    | Expose
    | RenderUsage;

Documentation:
    text=DOC_COMMENT;

Expose:
    'expose' target=QualifiedName ';'?;

RenderUsage:
    'render' rendering=QualifiedName ';'?;

NodeMetadata:
    '#' name=Name (
        '{' fields+=MetadataField* '}'
        | ';'
    )?;

MetadataField:
    key=Name '=' value=StrOrIdent ';'?;

PartDef:
    'part' 'def' name=QualifiedName (
        '{' members+=PartDefMember* '}'
        | ';'
    );

PartDefMember:
    PartUsage
    | InlinePort
    | ConnectionUsage
    | NoteUsage;

PartUsage:
    metadata+=NodeMetadata*
    'part' id=Name (':' type=StrOrIdent)? (
        '{' ports+=InlinePort* '}'
        | ';'
    )?;

InlinePort:
    metadata+=NodeMetadata*
    'port' direction=Direction? id=Name (':' type=StrOrIdent)? ';'?;

ConnectionUsage:
    metadata+=NodeMetadata*
    'connection' (cid=ID)? 'connect' from=Path 'to' to=Path
    ('via' via=QualifiedName)?
    (':' label=StrOrIdent)? ';'?;

ActionDef:
    'action' 'def' name=QualifiedName (
        '{' members+=ActionBodyMember* '}'
        | ';'
    );

ActionBodyMember:
    PinDeclaration
    | ActionUsage
    | ItemUsage
    | DecisionNode
    | MergeNode
    | FlowUsage
    | SuccessionUsage
    | NoteUsage;

PinDeclaration:
    direction=Direction id=Name (':' type=StrOrIdent)? ';'?;

ActionUsage:
    metadata+=NodeMetadata*
    'action' id=Name (':' type=StrOrIdent)? ';'?;

ItemUsage:
    metadata+=NodeMetadata*
    'item' id=Name (':' type=StrOrIdent)? ';'?;

DecisionNode:
    metadata+=NodeMetadata*
    'decide' id=Name (':' label=StrOrIdent)? ';'?;

MergeNode:
    metadata+=NodeMetadata*
    'merge' id=Name (':' label=StrOrIdent)? ';'?;

FlowUsage:
    metadata+=NodeMetadata*
    'flow' 'from' from=Path 'to' to=Path (':' label=StrOrIdent)? ';'?;

SuccessionUsage:
    'succession' from=Path 'then' to=Path ';'?;

NoteUsage:
    metadata+=NodeMetadata*
    'note' id=Name 'on' target=Path ':' text=StrOrIdent ';'?;

Direction returns string:
    'in' | 'out' | 'inout';

StrOrIdent returns string:
    STRING | QualifiedName;

Name returns string:
    ID | 'type' | 'name' | 'title' | 'direction' | 'layout' | 'render'
    | 'merge' | 'decide' | 'note' | 'on' | 'attribute' | 'role' | 'tooltip'
    | 'target' | 'label' | 'members' | 'kind' | 'frameName' | 'renderTarget';

QualifiedName returns string:
    Name (
        '.' Name
        | '::' Name
        | '<' Name '>'?
    )*;

Path returns string:
    Name ('.' Name)*;

terminal DOC_COMMENT: /doc\s*\/\*[\s\S]*?\*\//;
terminal ID: /[A-Za-z_][\w]*/;
terminal STRING: /"(?:[^"\\]|\\.)*"/;

hidden terminal WS: /\s+/;
hidden terminal LINE_COMMENT: /\/\/[^\n\r]*/;
hidden terminal BLOCK_COMMENT: /\/\*[\s\S]*?\*\//;
