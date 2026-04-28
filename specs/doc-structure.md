# Document Structure Conventions

## Top-level learning-track docs (`docs/NN-name.md`)

Filename pattern: `docs/NN-kebab-case-name.md` where `NN` is a zero-padded two-digit number. The
number determines the position in the README learning-track table and must be unique.

### Required section order

```markdown
# NN. Concept Title

> Mathematical background: [CT Concept](../ct/concept.md) — one-line description (optional)

> **In plain terms:** One sentence programmer-friendly analogy (optional, for abstract concepts)

Intro paragraph (2–4 sentences). State what the concept is and which earlier concept it builds on.
Link backward with [N. Name](./NN-name.md) syntax.

![concept](diagrams/concept.svg)

## Laws / Operations / Key ideas

(tables and bullet points — no code here)

## Motivation

Two code blocks in `text` fences (no language highlighting):

1. "without" — the painful status quo
2. "with" — the improvement the concept provides

![concept motivation](diagrams/concept-motivation.svg)

## Examples

### C\#

... code block ...

### F\#

... (repeat for all 9 languages in order)
```

### Rules

- Heading `# NN. Concept Title` — the number must match the filename.
- The intro paragraph must not contain code fences or headings.
- Motivation blocks use ` ```text ``` ` fences (no syntax highlighting) so they render identically
  in all renderers and do not trigger language-specific linters.
- Each language section is exactly one `###` heading; no sub-headings underneath it.
- Tables: align pipes; no trailing whitespace. `MD013` allows long table rows.
- Cross-links to other docs use relative paths: `[10. Monad](./10-monad.md)`.
- Cross-links to monad detail pages use: `[maybe.md](monads/maybe.md)` (from `docs/`).
- Do not use raw HTML (`MD033` is off but keeping Markdown-only keeps diffs clean).

## Monad detail docs (`docs/monads/name.md`)

Filename pattern: `docs/monads/name.md` (no number prefix).

### Required section order

````markdown
# <Name> Monad

Short definition sentence.

![concept diagram](diagrams/concept.svg)

![bind type signature](diagrams/concept-ibd.svg)

![pure implementation](diagrams/concept-pure.svg)

![bind implementation](diagrams/concept-bind.svg)

## Type

(```text fence showing the type constructors)

## How bind works

(table with Input column and "bind behaviour" column)

## Key use cases

(bullet list, 4–6 items)

## Motivation

(two ```text fences: without-bind pain, then with-bind relief)

![motivation diagram](diagrams/concept-motivation.svg)

## Examples

### C\#

... (all 9 languages in order)
````

## Inserting a new top-level concept

1. Pick the next `NN` number (do not insert in the middle without renumbering).
2. Create `docs/NN-kebab-name.md` following the template above.
3. Create `docs/NN-kebab-name/concept.d2` and `docs/NN-kebab-name/concept-motivation.d2`.
4. Compile SVGs: `make -C .tools svgs` (or `d2 --layout=elk src.d2 src.svg`).
5. Add a row to the README learning-track table.
6. Run `make -C .tools fmt-md lint-md lint-langs` and fix any errors before committing.

## Adding a new monad detail page

1. Create `docs/monads/name.md` following the monad template above.
2. Create the following diagram sources in `docs/monads/name/`:
   - `name.d2` — concept overview (type constructors, flow)
   - `name-motivation.d2` — before/after motivation
   - `name-pure.sysml` — activity diagram: `pure :: a ⟶ Maybe a` (wrap into context)
   - `name-bind.sysml` — activity diagram: `bind` (pattern match, apply f, short-circuit)
   - `name-ibd.sysml` — IBD: structural type signature for `bind`
3. Compile SVGs: `make -C .tools svgs`.
4. Add a row to the monad catalogue in `docs/10-monad.md` and in `README.md`.
5. Run `make -C .tools fmt-md lint-md lint-langs`.

## Optic detail docs (`docs/optics/name.md`)

Filename pattern: `docs/optics/name.md` (no number prefix). Currently: `iso.md`, `lens.md`,
`prism.md`, `traversal.md`, `fold.md`, `getter-setter.md`.

### Required section order

````markdown
# <Name>

Short definition sentence. State the optic's position in the hierarchy (stronger/weaker than).

![concept diagram](diagrams/concept.svg)

## Type

(```text fence: the optic type, its operations, and the van Laarhoven encoding)

## Laws

(table with Law / Expression / Meaning columns)

## Key use cases

(bullet list, 4–6 items)

## Motivation

(two ```text fences: without-optic pain, then with-optic relief)

![motivation diagram](diagrams/concept-motivation.svg)

## Examples

### C\#

... (all 9 languages in order)
````

### Rules

- Diagrams live in `docs/optics/name/` and import `...@../../styles`.
- Cross-links to other optic pages use relative paths: `[Lens](lens.md)`.
- Cross-links from `docs/` use: `[lens.md](optics/lens.md)`.

## Adding a new optic detail page

1. Create `docs/optics/name.md` following the optic template above.
2. Create `docs/optics/name/name.d2` and `docs/optics/name/name-motivation.d2`.
3. Compile SVGs: `make -C .tools svgs`.
4. Add a row to the optics catalogue table in `docs/13-optics.md` and in `README.md`.
5. Run `make -C .tools fmt-md lint-md lint-langs`.

## Renaming or renumbering docs

- Update the filename.
- Update the `# NN. Title` heading inside the file.
- Update every cross-link in other docs and in `README.md`.
- If the old file was tracked by git, use `git mv` to preserve history.
- Re-run `make -C .tools lint-md lint-langs`.
