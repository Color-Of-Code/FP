# Diagram Conventions

This repository uses two source formats for diagrams:

| Format   | Source ext | Toolchain             | Used for                                                                                              |
| -------- | ---------- | --------------------- | ----------------------------------------------------------------------------------------------------- |
| D2       | `.d2`      | `d2 --layout=elk`     | Most concept, motivation and detail diagrams                                                          |
| SysML v2 | `.sysml`   | `.tools/sysml/cli.ts` | Activity and IBD diagrams for fold, applicative, traversable, monad, and currying/partial-application |

Both produce `.svg` files that are embedded in Markdown docs identically.

## File locations

| Doc type              | Diagram source location             | SVG output location             |
| --------------------- | ----------------------------------- | ------------------------------- |
| `docs/NN-name.md`     | `docs/diagrams/name.d2` or `.sysml` | `docs/diagrams/name.svg`        |
| `docs/monads/name.md` | `docs/monads/diagrams/name.d2`      | `docs/monads/diagrams/name.svg` |
| `docs/optics/name.md` | `docs/optics/diagrams/name.d2`      | `docs/optics/diagrams/name.svg` |

Each concept gets **two diagrams**:

- `name.d2` / `name.svg` — the concept itself (types, operations, flow)
- `name-motivation.d2` / `name-motivation.svg` — before/after showing why the concept exists

Reference them in the doc as:

```markdown
![concept title](diagrams/concept.svg) ![concept motivation](diagrams/concept-motivation.svg)
```

---

## SysML v2 source format

### Diagram-type selection rationale

SysML v2 draws a hard line between **structure** and **behavior**. The same line exists in FP: a
function's _type signature_ is structural; its _execution_ is behavioral.

| Diagram type                     | SysML v2 keyword | Answers                          | Use for                                                      |
| -------------------------------- | ---------------- | -------------------------------- | ------------------------------------------------------------ |
| **IBD** (Internal Block Diagram) | `part def`       | "what is wired to what at rest?" | Type signatures; how types compose structurally              |
| **Activity diagram**             | `activity def`   | "how do values flow and when?"   | HOF inputs as tokens; chaining; accumulation; effectful maps |

**Rule:** every FP combinator with a polymorphic HOF signature gets **both** diagrams:

- An **IBD** (`-ibd.sysml`) showing the _type signature_ — parts connected by typed wires.
- An **Activity** (`.sysml`) showing the _execution_ — tokens flowing through action nodes.

A function-type value passed as an argument is an **object node** (a data token) in the activity
diagram — this is semantically precise: it is data, not a structural wire. In the IBD it is a `part`
node with a `show ... as hof` style so it renders teal.

### FP → SysML v2 element mapping

This table is the canonical guide for choosing which SysML v2 construct to use for each FP concept.
Follow it when writing new `.sysml` files.

| FP concept                              | SysML v2 element                                                                                       | Diagram  |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------ | -------- |
| Type `a`, `Fa`, `Ma`                    | `part <id> : Type` (IBD) / `object <id> : Type` (activity)                                             | both     |
| Function type `a → b` as value argument | `part <id> : "a → b"` with `show as hof` (IBD) / `object <id> : "a → b"` with `show as hof` (activity) | both     |
| Operation signature `f :: A → B → C`    | `part def FContext` with internal `part` nodes + `connection` wires                                    | IBD      |
| Operation execution (token flow)        | `action def` + `action` usage + `flow from/to`                                                         | activity |
| Structural composition                  | `connection connect A to B`                                                                            | IBD      |
| Token movement (data flow)              | `flow from A to B [: "label"]`                                                                         | activity |
| Sequencing (ordering constraint)        | `succession A then B`                                                                                  | activity |
| Container cardinality (`[0..*]`)        | flow label `"∀ a"` or type annotation `"List a"`                                                       | activity |
| Input pin of an action                  | `in <id> : <Type>` inside `action def`                                                                 | activity |
| Output pin of an action                 | `out <id> : <Type>` inside `action def`                                                                | activity |

**Types as quoted strings** — complex math types (`a → Mb`, `F(a → b)`, `List a`) are written as
quoted strings in the SysML source: `object f : "a → Mb"`. The renderer strips the quotes and
displays the math notation verbatim.

### Which diagrams use SysML v2

#### Activity diagrams (behavioral — token flow)

| SysML source                        | SVG output                        | Chapter                  |
| ----------------------------------- | --------------------------------- | ------------------------ |
| `docs/diagrams/fold.sysml`          | `docs/diagrams/fold.svg`          | ch 08 Fold               |
| `docs/diagrams/applicative.sysml`   | `docs/diagrams/applicative.svg`   | ch 07 Applicative        |
| `docs/diagrams/applicative-2.sysml` | `docs/diagrams/applicative-2.svg` | ch 07 Applicative (fmap) |
| `docs/diagrams/traversable.sysml`   | `docs/diagrams/traversable.svg`   | ch 09 Traversable        |
| `docs/diagrams/traversable-2.sysml` | `docs/diagrams/traversable-2.svg` | ch 09 Traversable (seq)  |
| `docs/diagrams/monad.sysml`         | `docs/diagrams/monad.svg`         | ch 10 Monad (chain)      |
| `docs/diagrams/monad-2.sysml`       | `docs/diagrams/monad-2.svg`       | ch 10 Monad (bind/pure)  |
| `docs/diagrams/monad-3.sysml`       | `docs/diagrams/monad-3.svg`       | ch 10 Monad (Maybe)      |
| `docs/diagrams/monad-4.sysml`       | `docs/diagrams/monad-4.svg`       | ch 10 Monad (List)       |
| `docs/diagrams/function2.sysml`     | `docs/diagrams/function2.svg`     | ch 03 Currying/partial   |
| `docs/diagrams/function2-2.sysml`   | `docs/diagrams/function2-2.svg`   | ch 03 Currying           |

#### IBD diagrams (structural — type signatures)

| SysML source                          | SVG output                          | Chapter           |
| ------------------------------------- | ----------------------------------- | ----------------- |
| `docs/diagrams/functor-ibd.sysml`     | `docs/diagrams/functor-ibd.svg`     | ch 06 Functor     |
| `docs/diagrams/applicative-ibd.sysml` | `docs/diagrams/applicative-ibd.svg` | ch 07 Applicative |
| `docs/diagrams/traversable-ibd.sysml` | `docs/diagrams/traversable-ibd.svg` | ch 09 Traversable |
| `docs/diagrams/monad-ibd.sysml`       | `docs/diagrams/monad-ibd.svg`       | ch 10 Monad       |
| `docs/diagrams/fold-ibd.sysml`        | `docs/diagrams/fold-ibd.svg`        | ch 08 Fold        |

### SysML v2 constructs used

These files use a subset of the official SysML v2 textual notation (OMG SysML 2.0, adopted 2025).

#### Activity diagram syntax

```sysml
package <Name> {

    // ── action type declarations ───────────────────────────────────────────
    action def <ActionName> {
        in  <id> : <Type>;          // input pin
        out <id> : <Type>;          // output pin
    }

    // ── activity (one diagram per activity def) ────────────────────────────
    activity def <DiagramName> {
        object <id> : <Type>;       // object node — a typed data token
        action <id> : <ActionDef>;  // action node — executes a transformation

        // object flow: a data token moves from one node to another
        flow from <id> to <id> [: "<label>"];

        // control flow: ordering constraint (no data carried)
        succession <id> then <id>;
    }
}

// ── diagram metadata (vendor extension, not part of SysML v2 grammar) ────────
#diagram {
    type  = activity                 // or: ibd
    title = "<diagram title>"
    render = <ActivityDefName>       // optional: which activity def to render
    show <id> as <role>              // role: hof | type | value | function
    tooltip <id> = "<hover text>"
}
```

**HOF inputs in activity diagrams**: a function type passed as an argument is modelled as an
`object` node with role `hof`. It flows into an `action` node exactly like any data token — this is
the correct SysML v2 semantics. Mark it `show <id> as hof` to render it with a `«function»`
stereotype and teal fill, and the flow edge will render as a solid teal arrow.

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

#diagram {
    type  = ibd
    title = "..."
    render = <PartDefName>       // optional: which part def to render
    show <id> as <role>
    tooltip <id> = "..."
}
```

### `#diagram` vendor extension

The `#diagram { ... }` block is a project-specific extension (prefixed `#` to distinguish from
standard SysML keywords). It controls visual rendering only.

```sysml
#diagram {
    type      = activity          // or: ibd
    title     = "fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ List<a> ⟶ b"
    name      = "fold"            // short label for the activity-frame tab
    direction = TB                // layout direction: LR (default) or TB (top→bottom)
    render    = FoldProcess       // which activity def or part def to render
    show f     as hof             // rectangle with «function» stereotype + teal fill
    show step1 as function        // rounded rectangle — the action that executes
    show b0    as value           // plain rectangle — a concrete value
    show ta    as type            // plain rectangle — a data type
    tooltip f  = "The combining function (b ⟶ a ⟶ b) — a HOF data token"
}
```

| Field       | Required | Values / notes                                                               |
| ----------- | -------- | ---------------------------------------------------------------------------- |
| `type`      | yes      | `activity` or `ibd`                                                          |
| `title`     | no       | Displayed in the SVG title row (full signature)                              |
| `name`      | no       | Short label for the activity-frame tab (e.g. `"traverse"`, `">>="`)          |
| `direction` | no       | `LR` (default, left→right) or `TB` (top→bottom, useful for stepped diagrams) |
| `render`    | no       | Which `activity def` or `part def` to render; defaults to the first one      |
| `show`      | no       | Assign a visual role: `hof \| type \| value \| function \| initial \| final` |
| `tooltip`   | no       | Hover text on a node                                                         |

#### Multiplicity and cardinality

To express "this processes any number of elements" without unrolling N steps, use flow labels and
quoted type annotations:

```sysml
object la  : "List a";        // type annotation communicates the container
object lb  : "List b";
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

| ------------------------------ | --------------------------------------------------------- | |
`action def` + `in`/`out` pins | Type signature of an operation | | `object <id> : <Type>` | A typed
data token (value, type, or HOF function) | | `action <id> : <ActionDef>` | An operation that
transforms tokens | | `flow from A to B` | Object flow — a token moves from node A to node B | |
`succession A then B` | Control flow — A completes before B starts (dashed arrow) | | `part def` +
`port in/out` | IBD structural block with typed boundary ports | | `connection connect A to B` | IBD
wire (structural, not a data flow) |

#### Visual notation (SysML v2 compliant)

The renderer follows OMG SysML v2 visual conventions (ISO 19514):

| Element          | Shape                              | Fill / Stroke                  | When to use                                              |
| ---------------- | ---------------------------------- | ------------------------------ | -------------------------------------------------------- |
| Action node      | rounded rectangle (`rx=12`)        | light green `#e8f5e9`          | An **action** — an operation that executes               |
| Object node      | plain rectangle                    | light grey `#f5f5f5`           | A data type or concrete value                            |
| HOF object node  | rectangle with `«function»` stereo | teal `#e0f2f1` / `#00796b`     | A **function type flowing in as a data token** (HOF arg) |
| Object flow edge | solid arrow, filled arrowhead      | grey `#424242` / teal for HOF  | Token moves from node A to node B                        |
| Control flow     | dashed arrow, open arrowhead       | grey `#424242`                 | Ordering only — A completes before B starts              |
| Initial node     | filled black circle                | `#212121`                      | Start pseudo-node                                        |
| Final node       | bull's-eye (outer + inner circle)  | `#212121`                      | End pseudo-node                                          |
| Activity frame   | rounded rect + pentagon name tab   | `#fafafa` frame, `#e0e0e0` tab | Encloses the activity, tab shows `«activity» Name`       |
| Pins             | small squares on action boundary   | `#e0e0e0`                      | Input pins (left) / output pins (right) from action def  |

**Canvas auto-sizing**: the SVG dimensions are computed from actual node widths and edge gaps —
there is no fixed canvas size. The layout engine uses Sugiyama-style layered placement (left→right)
with barycentric ordering to reduce edge crossings.

An `object` node with role `hof` renders as a rectangle with `«function»` stereotype in italic above
the label, with a teal fill. The flow edge from it into an action renders as a solid teal arrow.

A `succession` edge (control flow) renders as a dashed arrow with an open arrowhead.

### Compilation

```sh
# Single file
node --experimental-strip-types .tools/sysml/cli.ts docs/diagrams/fold.sysml docs/diagrams/fold.svg

# All SysML sources (activity + IBD)
make -C .tools sysml

# Everything (D2 + SysML + format + lint)
make -C .tools all
```

---

## D2 source format

(Monad detail pages use the same relative path — `diagrams/` — because the doc sits in
`docs/monads/` and the SVGs sit in `docs/monads/diagrams/`.)

Every D2 file must import the shared style sheet as the **first line after any `direction:`
declaration**:

```d2
# From docs/diagrams/
...@../styles

# From docs/monads/diagrams/
...@../../styles

# From docs/optics/diagrams/
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
/home/jaap/.local/bin/d2 --layout=elk docs/diagrams/foo.d2 docs/diagrams/foo.svg
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
