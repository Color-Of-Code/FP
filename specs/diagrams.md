# Diagram Conventions

During the migration, diagrams in `docs/` use D2 or the SysML-based renderer:

| Format    | Source ext | Toolchain             | Used for                                                                               |
| --------- | ---------- | --------------------- | -------------------------------------------------------------------------------------- |
| D2        | `.d2`      | `d2 --layout=elk`     | Concepts not yet migrated                                                              |
| SysML v2* | `.sysml`   | `.tools/sysml/cli.ts` | All 88 existing SysML sources use `view` / `render`; D2 migration is still in progress |

Both produce `.svg` files embedded in Markdown docs. *The local parser supports a narrow SysML v2
textual subset and project-specific presentation metadata; see
[the grammar reference](../.tools/sysml/grammar.md).

## File locations

Diagram sources and the generated SVGs live in a per-chapter folder named after the chapter filename
stem, sitting next to the Markdown page itself:

| Doc type              | Diagram source location                     | SVG output location              |
| --------------------- | ------------------------------------------- | -------------------------------- |
| `docs/NN-name.md`     | `docs/NN-name/<diagram>.d2` or `.sysml`     | `docs/NN-name/<diagram>.svg`     |
| `docs/monads/name.md` | `docs/monads/name/<diagram>.d2` or `.sysml` | `docs/monads/name/<diagram>.svg` |
| `docs/optics/name.md` | `docs/optics/name/<diagram>.d2`             | `docs/optics/name/<diagram>.svg` |

Each SVG is committed alongside its source. Adding a new chapter is self-contained: drop the
`<chapter>.md` and a sibling `<chapter>/` folder with the diagrams in it; the build picks them up
automatically.

Each concept gets **at minimum two diagrams**:

- `name.d2` / `name.svg` — the concept itself (types, operations, flow)
- `name-motivation.d2` / `name-motivation.svg` — before/after showing why the concept exists

Monad detail pages additionally use SysML for the two monad operations and their shared type
signature:

- `name-pure.sysml` / `name-pure.svg` — activity: `pure :: a ⟶ Maybe a` (wrap in context)
- `name-bind.sysml` / `name-bind.svg` — activity: `bind` (pattern match, apply, short-circuit)
- `name-ibd.sysml` / `name-ibd.svg` — IBD: type signature for `bind`

---

## SysML-based source format

The SysML sources use a small SysML v2 textual subset plus project metadata and rendering
definitions in [`.tools/sysml/FpDiagram.sysml`](../.tools/sysml/FpDiagram.sysml). The local parser
does not resolve imports or validate against an independent SysML implementation. Do not treat it as
a general-purpose SysML v2 parser.

### Diagram-type selection rationale

SysML v2 draws a hard line between **structure** and **behavior**. The same line exists in FP: a
function's _type signature_ is structural; its _execution_ is behavioral.

| Diagram type                     | SysML v2 keyword | Answers                          | Use for                                                      |
| -------------------------------- | ---------------- | -------------------------------- | ------------------------------------------------------------ |
| **IBD** (Internal Block Diagram) | `part def`       | "what is wired to what at rest?" | Type signatures; how types compose structurally              |
| **Activity diagram**             | `action def`     | "how do values flow and when?"   | HOF inputs as tokens; chaining; accumulation; effectful maps |

**Rule:** every FP combinator with a polymorphic HOF signature gets **both** diagrams:

- An **IBD** (`-ibd.sysml`) showing the _type signature_ — parts connected by typed wires.
- An **Activity** (`.sysml`) showing the _execution_ — tokens flowing through action nodes.

A function-type value passed as an argument is an **item** (a data token) in the activity diagram —
it is data, not a structural wire. In the IBD it is a `part` node; use `FpNodePresentation` metadata
with `role = "hof"` so it renders as a function argument.

### FP → SysML v2 element mapping

This table is the canonical guide for choosing which SysML v2 construct to use for each FP concept.
Follow it when writing new `.sysml` files.

| FP concept                              | SysML v2 element                                                             | Diagram  |
| --------------------------------------- | ---------------------------------------------------------------------------- | -------- |
| Type `a`, `Fa`, `Ma`                    | `part <id> : Type` (IBD) / `item <id> : Type` (activity)                     | both     |
| Function type `a → b` as value argument | `part <id> : "a → b"` / `item <id> : "a → b"`, annotated with `role = "hof"` | both     |
| Operation signature `f :: A → B → C`    | `part def FContext` with internal `part` nodes + `connection` wires          | IBD      |
| Operation execution (token flow)        | `action def` + `action` usage + `flow from/to`                               | activity |
| Structural composition                  | `connection connect A to B`                                                  | IBD      |
| Token movement (data flow)              | `flow from A to B [: "label"]`                                               | activity |
| Sequencing (ordering constraint)        | `succession A then B`                                                        | activity |
| Container cardinality (`[0..*]`)        | flow label `"∀ a"` or type annotation `"List a"`                             | activity |
| Input pin of an action                  | `in <id> : <Type>` inside `action def`                                       | activity |
| Output pin of an action                 | `out <id> : <Type>` inside `action def`                                      | activity |
| Pattern match / conditional branch      | `decide <id>` — diamond node with one inflow and guarded outflows            | activity |
| Joining divergent paths                 | `merge <id>` — diamond node that unites branches into a single outflow       | activity |

**Types as quoted strings** — complex math types (`a → Mb`, `F(a → b)`, `List a`) are written as
quoted strings in the SysML source: `item f : "a → Mb"`. The renderer strips the quotes and displays
the math notation verbatim.

### Which diagrams use SysML v2

#### Activity diagrams (behavioral — token flow)

| SysML source                              | SVG output                              | Chapter                   |
| ----------------------------------------- | --------------------------------------- | ------------------------- |
| `docs/16-fold/fold.sysml`                 | `docs/16-fold/fold.svg`                 | ch 16 Fold                |
| `docs/15-applicative/applicative.sysml`   | `docs/15-applicative/applicative.svg`   | ch 15 Applicative         |
| `docs/15-applicative/applicative-2.sysml` | `docs/15-applicative/applicative-2.svg` | ch 15 Applicative (fmap)  |
| `docs/17-traversable/traversable.sysml`   | `docs/17-traversable/traversable.svg`   | ch 17 Traversable         |
| `docs/17-traversable/traversable-2.sysml` | `docs/17-traversable/traversable-2.svg` | ch 17 Traversable (seq)   |
| `docs/19-monad/monad.sysml`               | `docs/19-monad/monad.svg`               | ch 19 Monad (chain)       |
| `docs/19-monad/monad-2.sysml`             | `docs/19-monad/monad-2.svg`             | ch 19 Monad (bind/pure)   |
| `docs/19-monad/monad-3.sysml`             | `docs/19-monad/monad-3.svg`             | ch 19 Monad (Maybe)       |
| `docs/19-monad/monad-4.sysml`             | `docs/19-monad/monad-4.svg`             | ch 19 Monad (List)        |
| `docs/06-currying/function2.sysml`        | `docs/06-currying/function2.svg`        | ch 06 Currying/partial    |
| `docs/06-currying/function2-2.sysml`      | `docs/06-currying/function2-2.svg`      | ch 06 Currying            |
| `docs/monads/maybe/maybe-pure.sysml`      | `docs/monads/maybe/maybe-pure.svg`      | Maybe monad detail (pure) |
| `docs/monads/maybe/maybe-bind.sysml`      | `docs/monads/maybe/maybe-bind.svg`      | Maybe monad detail (bind) |

#### IBD diagrams (structural — type signatures)

| SysML source                                | SVG output                                | Chapter                       |
| ------------------------------------------- | ----------------------------------------- | ----------------------------- |
| `docs/13-functor/functor-ibd.sysml`         | `docs/13-functor/functor-ibd.svg`         | ch 13 Functor                 |
| `docs/15-applicative/applicative-ibd.sysml` | `docs/15-applicative/applicative-ibd.svg` | ch 15 Applicative             |
| `docs/17-traversable/traversable-ibd.sysml` | `docs/17-traversable/traversable-ibd.svg` | ch 17 Traversable             |
| `docs/19-monad/monad-ibd.sysml`             | `docs/19-monad/monad-ibd.svg`             | ch 19 Monad                   |
| `docs/16-fold/fold-ibd.sysml`               | `docs/16-fold/fold-ibd.svg`               | ch 16 Fold                    |
| `docs/monads/maybe/maybe-ibd.sysml`         | `docs/monads/maybe/maybe-ibd.svg`         | Maybe monad detail (bind sig) |

### SysML v2 subset and project metadata

The local parser supports a narrow SysML v2 textual subset plus project-defined presentation
metadata. It does not resolve imports or validate sources against an independent SysML
implementation.

#### Activity view syntax

```sysml
package <Name> {

    // ── action type declarations ───────────────────────────────────────────
    action def <ActionName> {
        in  <id> : <Type>;          // input pin
        out <id> : <Type>;          // output pin
    }

    // ── action model selected by one view ──────────────────────────────────
    action def <DiagramName> {
        item <id> : <Type>;         // typed data token
        action <id> : <ActionDef>;  // operation
        flow from <id> to <id> [: "<label>"];
        succession <id> then <id>;
        decide <id>;
        merge <id>;
    }
    #FpViewPresentation { name = "map"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /* fmap applies a function inside the functor. */
        expose <DiagramName>;
        render fpActivityDiagram;
    }
}
```

`FpActivityView` specializes `ActionFlowView`. A function passed to a combinator is an `item`
annotated with `#FpNodePresentation { role = "hof"; }`; it flows into the combinator action as an
argument while the main chain remains on the combinator nodes.

#### IBD syntax (for structural/signature diagrams)

```sysml
package <Name> {
    port def <PortTypeName>;

    part def <BlockName> {
        port in  <id> : <PortType>;          // port on block boundary (in)
        port out <id> : <PortType>;          // port on block boundary (out)
        part <id> : <TypeName>;              // internal node
        connection [<id>] connect <a> to <b> [via <ConnType>] [: "<label>"];
    }
}

view diagram : FpIbdView {
    doc /* Type signature of the operation. */
    expose <PartDefName>;
    render fpIbdDiagram;
}
```

### Presentation metadata

Node and view presentation are declared with the project metadata types in
[`FpDiagram.sysml`](../.tools/sysml/FpDiagram.sysml). They control visual rendering only.

```sysml
#FpNodePresentation { role = "hof"; tooltip = "The combining function"; }
item f : "b ⟶ a ⟶ b";

#FpViewPresentation { name = "fold"; direction = "TB"; }
view diagram : FpActivityView {
    doc /* fold combines a collection into one value. */
    expose FoldProcess;
    render fpActivityDiagram;
}
```

| Metadata field                 | Purpose                                                                                               |
| ------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `role`                         | Selects node styling: `hof`, `type`, `value`, `function`, `initial`, `final`, `decision`, or `merge`. |
| `tooltip`                      | Adds hover text to a node.                                                                            |
| `laneId`, `laneLabel`          | Assigns a node to a lane and labels that lane.                                                        |
| `laneOrder`, `laneMemberOrder` | Explicitly controls lane and within-lane order.                                                       |
| View `name`                    | Short frame label.                                                                                    |
| View `direction`               | `LR` or `TB`; layout engine details are renderer-controlled.                                          |

Each source has one `view`. `expose` selects the definition and `render` selects the activity or IBD
renderer. The view's `doc` comment supplies the SVG title. The legacy `#diagram` extension is not
supported.

#### Multiplicity and cardinality

To express "this processes any number of elements" without unrolling N steps, use flow labels and
quoted type annotations:

```sysml
item la  : "List a";          // type annotation communicates the container
item lb  : "List b";
flow from la to bind : "∀ a";  // "for every element"
flow from bind to lb : "[0..*]"; // produces zero or more results
```

This keeps the diagram abstract and avoids the literal enumeration that only works for a fixed N.

#### IBD constructs

| SysML v2 construct           | FP diagram meaning                                        |
| ---------------------------- | --------------------------------------------------------- |
| `part def` + internal `part` | Type-signature block with named components                |
| `part <id> : "a → b"`        | A function type as a structural component (show as `hof`) |
| `connection connect A to B`  | Structural wire — types are related / composed            |

#### Activity constructs

| SysML v2 construct             | FP diagram meaning                                            |
| ------------------------------ | ------------------------------------------------------------- |
| `action def` + `in`/`out` pins | Type signature of an operation                                |
| `item <id> : <Type>`           | A typed data token (value, type, or HOF function)             |
| `action <id> : <ActionDef>`    | An operation that transforms tokens                           |
| `flow from A to B`             | Object flow — a token moves from node A to node B             |
| `succession A then B`          | Control flow — A completes before B starts (dashed arrow)     |
| `decide <id>`                  | Diamond node — conditional branch (pattern match / guard)     |
| `merge <id>`                   | Diamond node — joins divergent branches into a single outflow |
| `part def` + `port in/out`     | IBD structural block with typed boundary ports                |
| `connection connect A to B`    | IBD wire (structural, not a data flow)                        |

**Decision / merge nodes**: Use a `decide` node when the flow depends on the shape or value of an
incoming token (e.g. a pattern match on `Just a` vs `Nothing`). Outgoing flows from a decision carry
**guard labels** (the `flow … : "label"` syntax). A corresponding `merge` node joins the branches
back into a single output. Both render as yellow diamonds.

#### Visual notation (SysML v2 compliant)

The renderer uses SysML-inspired shapes with a shared light/dark palette from
[`.tools/sysml/types/theme.ts`](../.tools/sysml/types/theme.ts). Do not add literal colors to
renderer code; semantic tokens keep diagrams consistent and allow contrast to be tested.

| Element          | Shape                              | Theme tokens                               | When to use                                                |
| ---------------- | ---------------------------------- | ------------------------------------------ | ---------------------------------------------------------- |
| Action node      | rounded rectangle (`rx=12`)        | `actionFill`, `actionStroke`               | An **action** — an operation that executes                 |
| Object node      | plain rectangle                    | `objFill`, `objStroke`                     | A data type or concrete value                              |
| HOF object node  | rectangle with `«function»` stereo | `hofFill`, `hofStroke`                     | A **function type flowing in as a data token** (HOF arg)   |
| Decision node    | diamond (rotated square)           | `decisionFill`, `decisionStroke`           | Pattern match / conditional branch (one in, N guarded out) |
| Merge node       | diamond (rotated square)           | `decisionFill`, `decisionStroke`           | Joins N branches back into a single flow                   |
| Object flow edge | solid arrow, filled arrowhead      | `edgeStroke`; `hofEdge` for HOF            | Token moves from node A to node B                          |
| Control flow     | dashed arrow, open arrowhead       | `edgeStroke`; `controlFlow` dash pattern   | Ordering only — A completes before B starts                |
| Initial node     | filled circle                      | `initFill`                                 | Start pseudo-node                                          |
| Final node       | bull's-eye (outer + inner circle)  | `finalStroke`, `finalFill`                 | End pseudo-node                                            |
| Activity frame   | rounded rect + pentagon name tab   | `frameFill`, `frameStroke`, `frameTabFill` | Encloses the activity, tab shows `«activity» Name`         |
| Pins             | small squares on action boundary   | `pinFill`, `pinStroke`                     | Input pins (left) / output pins (right) from action def    |

**Canvas auto-sizing**: the SVG dimensions are computed from actual node widths and edge gaps —
there is no fixed canvas size. The layout engine uses Sugiyama-style layered placement (left→right)
with barycentric ordering to reduce edge crossings.

An `item` node with role `hof` renders as a rectangle with `«function»` stereotype above the label.
Its fill, label, and flow use the HOF palette tokens in both color schemes.

A `succession` edge (control flow) renders as a dashed arrow with an open arrowhead.

The SVG canvas is transparent. `prefers-color-scheme` in the embedded SVG selects the light or dark
token set; this follows the browser or operating-system preference, not a site's independent theme
toggle. SVGs include a semantic `<title>` and `<desc>`, and are labelled as images. The view's `doc`
text must exactly match the Markdown image alt text. `lint-diagrams` enforces this, verifies
source/output/embed consistency, and caps each rendered graph at 20 nodes. Contrast tests require at
least 4.5:1 for text and 3:1 for graphical elements in both schemes.

**Law diagrams:** draw the two expressions as separate paths and join their endpoints with a visible
`=` marker. Keep each path's operations explicit; the shared result alone does not communicate the
equivalence.

### Compilation

```sh
# Single file
node --experimental-strip-types .tools/sysml/cli.ts docs/16-fold/fold.sysml docs/16-fold/fold.svg

# All SysML sources (activity + IBD)
make -C .tools sysml

# Diagram metadata, alt text, source links, and node budget
make -C .tools lint-diagrams

# Everything (D2 + SysML + format + lint)
make -C .tools all
```

---

## D2 source format

> **Deprecated for new and updated diagrams.** D2 remains only for existing `docs/` diagrams while
> they are migrated. Do not add or modify `.d2` files; use the SysML-based renderer above. The D2
> ratchet checks that this inventory only shrinks.

(Each diagram source sits in the per-chapter folder next to its `.md` page, e.g.
`docs/16-fold/fold-ibd.sysml` for `docs/16-fold.md`, and `docs/monads/maybe/maybe-bind.sysml` for
`docs/monads/maybe.md`.)

Every D2 file must import the shared style sheet as the **first line after any `direction:`
declaration**:

```d2
# From a top-level chapter folder, e.g. docs/19-monad/
...@../styles

# From a monad detail folder, e.g. docs/monads/maybe/
...@../../styles

# From an optic detail folder, e.g. docs/optics/iso/
...@../../styles
```

`docs/styles.d2` defines all classes and colours. Do not redefine colours or shapes inline.

## Compilation

Always compile with ELK layout:

```sh
d2 --layout=elk source.d2 output.svg
```

The `make -C .tools svgs` target handles all D2 files automatically. To compile a single file during
development:

```sh
/home/jaap/.local/bin/d2 --layout=elk docs/19-monad/monad.d2 docs/19-monad/monad.svg
```

## Available style classes

Defined in `docs/styles.d2`:

| Class        | Shape           | Usage                                                                           |
| ------------ | --------------- | ------------------------------------------------------------------------------- |
| `type`       | circle          | A type or type constructor (`Fix F`, `Maybe a`)                                 |
| `value`      | circle          | A concrete value or term (`Just 5`, `a`)                                        |
| `function`   | rectangle       | A function that **executes** (`fmap`, `alg`, `cata`)                            |
| `hof`        | circle (dashed) | A **function type** flowing in as a value argument — e.g. `(a → b)`, `(a → Mb)` |
| `comment`    | text            | Explanatory label, no border                                                    |
| `definition` | rectangle       | A definition block (wider, larger font)                                         |
| `code`       | rectangle       | Code snippet node                                                               |

### Colour modifier classes (combine with shape class)

| Class | Colour | Typical use                |
| ----- | ------ | -------------------------- |
| `a`   | orange | Input type / first item    |
| `b`   | purple | Output type / second item  |
| `c`   | yellow | Third item / intermediate  |
| `f`   | orange | Function (same hue as `a`) |
| `g`   | purple | Function (same hue as `b`) |
| `h`   | yellow | Function (same hue as `c`) |
| `f2`  | green  | Second function / variant  |
| `p`   | green  | Product / pair             |

> `hof` has a built-in teal fill (`#80c8c0`) — do **not** combine with colour modifier classes.

### Connection classes

| Class      | Usage                                                                 |
| ---------- | --------------------------------------------------------------------- |
| `hof-conn` | Dashed thick arrow from an `hof` node to a `function` node (HOF-wire) |

## HOF-wire convention

When a higher-order function receives **another function as a value argument**, that input has a
different conceptual status from a data type argument. Use two classes to make this visible:

- Mark the input node as `hof` (teal dashed circle) — it represents a **function type** (`a → b`,
  `a → Mb`, `F(a → b)`) flowing in as data, not a computation node.
- Mark the connection `[hof-node] -> [function-node]` with `{ class: hof-conn }` — the dashed thick
  arrow visually separates the function-valued wire from plain data-flow wires.

```d2
# fold :: (b → a → b) → b → [a] → b
def_fold: fold :: ... {
  f -> fold: { class: hof-conn }   # f is a function type flowing in
  b0 -> fold                       # b0 is a plain data value
  as -> fold                       # as is a plain data structure
  f.class: [hof]                   # dashed teal circle
  b0.class: [type; b]
  as.class: [type; a]
  fold.class: [function; g]
}
```

**Rule of thumb:**

| Node is...                              | Class to use           |
| --------------------------------------- | ---------------------- |
| A function executing a computation      | `function` (rectangle) |
| A function type received as an argument | `hof` (dashed circle)  |
| A plain type (data)                     | `type` (circle)        |

Apply multiple classes as an array:

```d2
node.class: [type; a]      # double-bordered circle, orange fill
node.class: [function; f]  # rectangle, orange fill
```

## Block string pitfalls

### Pipe characters inside `|md...|` blocks

If a node label uses `|md...|` for inline markdown and the markdown itself contains `|` (e.g.
Haskell list comprehensions, table rows), the outer delimiter will conflict. Use double-bar
delimiters instead:

```d2
# BAD  — the | in the formula closes the block early
node: |md `[(a, p) | (a, p) <- pairs]` |

# GOOD — double-bar delimiter allows | inside
node: ||md `[(a, p) | (a, p) <- pairs]` ||
```

### Square brackets in unquoted labels

Square brackets `[...]` in an unquoted D2 label are parsed as a class list and will cause a parse
error. Always quote labels that contain brackets:

```d2
# BAD
node: filter [x > 0] xs

# GOOD
node: "filter [x > 0] xs"
```

### Backslash in labels

D2 does not interpret `\n` or other escape sequences in quoted strings the same way as some
languages. Use multi-line block strings (`|...|`) for text that needs newlines.

## Diagram structure guidance

- **Concept diagram**: show the flow of types through operations left-to-right (`direction: right`).
  Highlight inputs with colour class `a`, outputs with `b`, functions with `f`/`g`.
- **Motivation diagram**: split into two containers, `before` (problem) and `after` (solution). Use
  `comment` nodes for explanatory text. Keep it readable at 800 px width.
- Use `tooltip:` on key nodes to add hover-text explanations without cluttering the layout.
- Keep node IDs short and lowercase (they are invisible; the label is what matters).
- Avoid deeply nested containers — two levels maximum.
