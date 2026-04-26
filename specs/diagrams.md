# D2 Diagram Conventions

## File locations

| Doc type              | Diagram source location        | SVG output location             |
| --------------------- | ------------------------------ | ------------------------------- |
| `docs/NN-name.md`     | `docs/diagrams/name.d2`        | `docs/diagrams/name.svg`        |
| `docs/monads/name.md` | `docs/monads/diagrams/name.d2` | `docs/monads/diagrams/name.svg` |
| `docs/optics/name.md` | `docs/optics/diagrams/name.d2` | `docs/optics/diagrams/name.svg` |

Each concept gets **two diagrams**:

- `name.d2` / `name.svg` — the concept itself (types, operations, flow)
- `name-motivation.d2` / `name-motivation.svg` — before/after showing why the concept exists

Reference them in the doc as:

```markdown
![concept title](diagrams/concept.svg) ![concept motivation](diagrams/concept-motivation.svg)
```

(Monad detail pages use the same relative path — `diagrams/` — because the doc sits in
`docs/monads/` and the SVGs sit in `docs/monads/diagrams/`.)

## Importing styles

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
