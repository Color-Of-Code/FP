# SysML grammar reference

This repository uses a small SysML v2 textual notation subset plus a project-specific `#diagram`
block for rendering metadata. This file is the reference grammar for the subset accepted by
`.tools/sysml/lexer.ts` and `.tools/sysml/parser.ts`.

This is a derived reference, not a verbatim copy of the full OMG grammar.

## Upstream basis

The local subset was matched against the official SysML v2 release BNF:

- <https://github.com/systems-modeling/sysml-v2-release/blob/main/bnf/SysML-textual-bnf.html>
- <https://github.com/systems-modeling/sysml-v2-release/blob/main/bnf/KerML-textual-bnf.html>

Those files define the complete language. The grammar below is intentionally narrower: it captures
the concrete syntax used in this repo's `.sysml` sources and the constructs the local transpiler
actually parses.

## Scope

Supported standard-ish SysML concepts:

- `package`
- `port def`
- `part def`, `part`, `port`, `connection`
- `action def`, `activity def`, `action`, `object`
- `decision`, `merge`, `flow`, `succession`

Supported project-specific extension:

- `#diagram { ... }`

Deliberately not modeled here:

- the full SysML v2 namespace and type system
- `::`-qualified names and the broader KerML lexical space
- guards, expressions, multiplicities, metadata, imports, and most other SysML constructs
- parser recovery behavior for unknown syntax

## Lexical notes

The lexer is intentionally small. In practice, author files using the conventions below.

```ebnf
LINE_COMMENT  = "//" , { any character except newline } ;
BLOCK_COMMENT = "/*" , { any character } , "*/" ;
STRING        = '"' , { escaped_quote | any character except '"' } , '"' ;
PUNCT         = "{" | "}" | ":" | ";" | "," | "#" | "=" | "." | "[" | "]" ;
IDENT         = letter_or_digit_or_underscore_or_angle_bracket ,
                { letter_or_digit_or_underscore_or_angle_bracket } ;
```

Notes:

- Whitespace and comments are ignored.
- The only string escape the lexer handles explicitly is `\"`.
- Complex FP types are usually written as quoted strings, for example `"F(a ⟶ b)"`.
- The implementation is permissive about tokens inside names; the grammar below documents the
  intended authoring subset rather than every recovery edge case.

## Supported grammar

The grammar below describes the supported happy-path syntax. The parser will also skip unknown items
up to the next `;` or balanced `{ ... }` block, but that recovery behavior is not part of the
authoring contract.

```ebnf
Model             = { TopLevelItem } ;

TopLevelItem      = PackageDecl | DiagramMeta ;

PackageDecl       = "package" , QualifiedName , "{" , { PackageItem } , "}" ;

PackageItem       = PortDef
                  | PartDefDecl
                  | ActionDefDecl
                  | ActivityDefDecl ;

PortDef           = "port" , "def" , IDENT , PortDefTail ;
PortDefTail       = ";" | Block | Empty ;

PartDefDecl       = "part" , "def" , PartDef ;
PartDef           = QualifiedName , ( ";" | "{" , { PartBodyItem } , "}" ) ;

PartBodyItem      = "part" , PartUsage
                  | "port" , PortUsage
                  | "connection" , ConnectionUsage ;

PartUsage         = IDENT , [ ":" , TypeRef ] , ( ";" | "{" , { PartMember } , "}" ) ;
PartMember        = "port" , PortUsage ;

PortUsage         = [ Direction ] , IDENT , [ ":" , TypeRef ] , [ ";" ] ;
Direction         = "in" | "out" | "inout" ;

ConnectionUsage   = [ ConnectionId ] , "connect" , DottedPath ,
                    "to" , DottedPath ,
                    [ "via" , QualifiedName ] ,
                    [ ":" , StringOrIdent ] ,
                    [ ";" ] ;
ConnectionId      = IDENT ;

ActionDefDecl     = "action" , "def" , ActionDef ;
ActionDef         = QualifiedName , ( ";" | "{" , { PinDecl } , "}" ) ;
PinDecl           = Direction , IDENT , [ ":" , TypeRef ] , [ ";" ] ;

ActivityDefDecl   = "activity" , "def" , ActivityDef ;
ActivityDef       = QualifiedName , ( ";" | "{" , { ActivityBodyItem } , "}" ) ;

ActivityBodyItem  = ActionUsage
                  | ObjectNode
                  | DecisionNode
                  | MergeNode
                  | FlowUsage
                  | SuccessionUsage ;

ActionUsage       = "action" , IDENT , [ ":" , TypeRef ] , [ ";" ] ;
ObjectNode        = "object" , IDENT , [ ":" , TypeRef ] , [ ";" ] ;
DecisionNode      = "decision" , IDENT , [ ":" , StringOrIdent ] , [ ";" ] ;
MergeNode         = "merge" , IDENT , [ ":" , StringOrIdent ] , [ ";" ] ;

FlowUsage         = "flow" , "from" , DottedPath ,
                    "to" , DottedPath ,
                    [ ":" , StringOrIdent ] ,
                    [ ";" ] ;

SuccessionUsage   = "succession" , DottedPath , "then" , DottedPath , [ ";" ] ;

DiagramMeta       = "#" , "diagram" , "{" , { DiagramField } , "}" ;

DiagramField      = "type" , [ "=" ] , DiagramType
                  | "title" , [ "=" ] , StringOrIdent
                  | "name" , [ "=" ] , StringOrIdent
                  | "direction" , [ "=" ] , LayoutDirection
                  | "layout" , [ "=" ] , LayoutEngine
                  | "render" , [ "=" ] , StringOrIdent
                  | "show" , DottedPath , "as" , Role
                  | "tooltip" , DottedPath , [ "=" ] , StringOrIdent ;

DiagramType       = "activity" | "ibd" ;
LayoutDirection   = "LR" | "TB" ;
LayoutEngine      = "dagre" | "elk" ;

Role              = "hof"
                  | "type"
                  | "value"
                  | "function"
                  | "initial"
                  | "final"
                  | "decision"
                  | "merge" ;

TypeRef           = StringOrIdent ;
StringOrIdent     = STRING | IDENT ;

QualifiedName     = IDENT , { GenericSuffix | DottedSuffix } ;
GenericSuffix     = "<" , IDENT , [ ">" ] ;
DottedSuffix      = "." , IDENT ;

DottedPath        = IDENT , { "." , IDENT } ;

Block             = "{" , { any supported or unsupported nested tokens } , "}" ;
Empty             = ;
```

## `#diagram` extension

The `#diagram` block is not part of SysML v2. It is a repo-local rendering extension consumed by the
SVG transpiler.

```sysml
#diagram {
    type      = activity
    title     = "Applicative: (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb"
    name      = "<*>"
    direction = LR
    layout    = elk
    render    = ApplicativeProcess
    show fff    as hof
    show apStar as function
    tooltip fff = "Wrapped function token"
}
```

Supported fields:

- `type`: `activity` or `ibd`
- `title`: diagram title
- `name`: short frame label
- `direction`: `LR` or `TB`
- `layout`: `dagre` or `elk`
- `render`: activity or part definition name to render
- `show`: assign a render role to a node
- `tooltip`: hover text for a node

## Practical constraints

- Use quoted strings for math-heavy type expressions.
- Keep names simple. The local parser is much smaller than the full SysML v2 grammar.
- If you need syntax beyond this file, either extend `.tools/sysml/parser.ts` and
  `.tools/sysml/lexer.ts`, or switch that diagram back to D2.

Checked against the official SysML v2 release BNF on 2026-04-27.
