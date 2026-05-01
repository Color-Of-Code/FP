# Agent Guidelines — FP Learning Track

This repo is a multi-language FP learning track. Every document explains one concept through prose,
a D2 diagram, motivation, and code examples in **all nine languages in a fixed order**.

See `specs/` for detailed specifications.

## Build system

All tooling lives in `.tools/`. Run from the repo root:

```sh
make -C .tools <target>
```

| Target       | What it does                                         |
| ------------ | ---------------------------------------------------- |
| `fmt-md`     | Format all Markdown with prettier                    |
| `lint-md`    | Lint all Markdown with markdownlint-cli2             |
| `lint-langs` | Check 9-language completeness and order in every doc |
| `svgs`       | Compile all D2 sources to SVG                        |
| `fmt`        | `fmt-md` + D2 formatter                              |
| `all`        | `svgs` + `fmt` + `lint-md` + `lint-langs`            |

**After every edit run at minimum:** `make -C .tools fmt-md lint-md lint-langs`

**After adding or editing any diagram:** also run `make -C .tools svgs`

## Key constraints — read before touching anything

1. **9 languages, fixed order**: every `docs/*.md` and `docs/monads/*.md` (except SKIP_FILES) must
   contain exactly one `### <Lang>` section per language in this order: `C#` → `F#` → `Ruby` → `C++`
   → `JavaScript` → `Python` → `Haskell` → `Rust` → `Go` See
   [`specs/languages.md`](specs/languages.md).

2. **File numbering is sequential**: `docs/NN-kebab-name.md`. Inserting a new concept in the middle
   requires renumbering all higher files, updating cross-links, and updating README. See
   [`specs/doc-structure.md`](specs/doc-structure.md).

3. **Every new concept diagram** must be referenced by the doc and compiled to SVG before commit.
   See [`specs/diagrams.md`](specs/diagrams.md).

4. **SKIP_FILES**: only discussion/comparison chapters (no tutorial code) belong in this set in
   `.tools/check-lang-order.js`. Do not add a file there to silence a check — fix the content.

5. **README table, monad catalogue, and optics catalogue** must be kept in sync with actual files.
   - `docs/monads/` — monad detail pages (linked from `docs/10-monad.md` and README)
   - `docs/optics/` — optic detail pages (linked from `docs/13-optics.md` and README) See
     [`specs/doc-structure.md`](specs/doc-structure.md).

6. **Category Theory track (`ct/`)** — a math-first parallel track with no per-language code.
   - `ct/*.md` pages follow the mandatory template in
     [`specs/ct-doc-structure.md`](specs/ct-doc-structure.md): Definition → Laws → FP Analog → CTFP
     Reference.
   - **No 9-language requirement** in `ct/`. The `lint-langs` check does not apply. Do not add `ct/`
     files to `SKIP_FILES` in `.tools/check-lang-order.js` — the checker only scans `docs/`.
   - Every `ct/` page must link to the corresponding `docs/NN-` chapter (relative path
     `../docs/NN-name.md`) and to the CTFP source (GitHub URL, not local path).
   - Every `docs/` page that has a CT counterpart must carry a one-line blockquote near the top:
     `> Mathematical background: [CT concept](../ct/concept.md) — one-line description`
   - The `ct/README.md` catalog table must be updated whenever a new `ct/` page is added.
   - Run `make -C .tools fmt-md lint-md` after editing `ct/` pages (not `lint-langs`).

## SysML activity diagrams — conventions

1. **Pins represent typed values** (a slot where a value flows). The type constrains what flows; the
   name labels the value. Type information belongs on the flow edge, not duplicated on the pin.

2. **Anonymous pins**: use `_` as the pin name to render the pin square without a text label. Use
   this when the pin's purpose is already obvious from the flow-edge type annotation (e.g., output
   pins whose type like `"Maybe User"` is on the outgoing edge).

3. **Motivation-pair consistency**: "without" and "with" diagrams for the same monad should use
   **identical type names** (e.g., `Maybe User` in both). This makes the structural parallel
   immediately visible — the difference is in _handling_ (manual guards vs. automatic bind), not in
   the types themselves.

4. **Minimize label noise**: if information is already carried on a flow edge, do not repeat it on a
   pin label. Prefer fewer, meaningful labels over exhaustive annotation.

5. **Show monadic combinators as real nodes, not edge labels**. A function `f : a → m b` cannot
   compose directly with `g : b → m c` — the types do not line up. The combinator (`bind`/`>>=`,
   `ap`/`<*>`, `fmap`, etc.) is a real operation with its own type signature, not just notation.
   - Render the combinator as an `action` node on the main flow.
   - Pass the chained function in as a side **HOF input** (rendered with `show … as hof`), typed
     `a ⟶ m b` (or whatever its signature is). It must not sit on the main flow, because its input
     type does not match the `m a` flowing through.
   - Edge labels on the main flow carry the monadic types (`Maybe User`, `Maybe Address`, …).
   - This makes the central insight visible: the chain runs through the combinator nodes; the
     fallible/effectful functions are arguments to those combinators.

6. **Anonymous combinator output pins**: `bind`, `ap`, etc. typically have one output. Use
   `out _ : "Maybe b"` (or similar) so the pin square is rendered without a noisy `result` label.

7. **Swimlanes (`lane` blocks)** in `*-motivation-with.sysml` files split plain-value land from
   monadic land. Conventions:
   - Top lane is `lane plain : "Plain values & functions" = …` and lists raw input, all HOF argument
     objects, and the final output object.
   - Bottom lane is `lane monad : "<Name> monad" = …` and lists the chain entry (`pureX`) and the
     bind/ap/fmap action nodes.
   - **Member order matters**: list members left-to-right in the order they should appear along the
     chain. The layout engine column-aligns each cross-lane HOF object to its target action's x —
     the natural "HOF dropping straight down into its bind" reading depends on the declaration order
     matching the flow order.
   - Lanes are decoration only. Do not try to encode flow direction or semantics through lanes.

## Lessons learned — do not repeat

- **Generated Langium imports** (`.tools/sysml/generated/module.ts`): after running
  `make -C .tools langium-gen`, the generated `import './ast.js'` / `import './grammar.js'` lines
  must be patched to `.ts` because the SysML CLI runs via `node --experimental-strip-types`. See
  `/memories/repo/sysml-cli-imports.md`.
- **ELK + lanes layout**: anchoring lane-row y-coordinates only works with
  `elk.layered.nodePlacement.strategy = INTERACTIVE`. Mixing lane anchors with `mergeEdges = true`
  causes straight horizontal chain edges to detour up through the inter-row routing channel; keep
  `mergeEdges = false` and post-process same-lane horizontal edges into pure straight segments
  (already implemented in `.tools/sysml/layout.ts`).
- **HOF column alignment**: do not try to use `elk.layered.layering.layerChoiceConstraint` to pin
  HOFs above their binds — it conflicts with the topological layering and produces compressed
  columns. Instead, post-layout shift each cross-lane HOF object's `x` to match its target action's
  `x` (one HOF → one bind), then rewrite the edge polyline to a clean vertical drop.
- **Snapshots**: after any change to `.tools/sysml/` layout, parser, or render code, run
  `make -C .tools test-update` to refresh the JSON / SVG snapshots, then `make -C .tools test` to
  confirm. The snapshot suite is the regression net for the SysML pipeline.
- **`isInitialSource` excludes HOFs**: a HOF object node has `n.isHof === true` and must not be
  treated as a chain entry point even when it has no incoming edges. Otherwise ELK pins it to the
  first layer and the chain entry node loses its FIRST-layer slot.
