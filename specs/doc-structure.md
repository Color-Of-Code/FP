# Document Structure Conventions

## Top-level learning-track docs (`docs/NN-name.md`)

Filename pattern: `docs/NN-kebab-case-name.md` where `NN` is a zero-padded two-digit number. The
number determines the position in the README learning-track table and must be unique.

### Required section order

```markdown
# NN. Concept Title

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
3. Create `docs/diagrams/concept.d2` and `docs/diagrams/concept-motivation.d2`.
4. Compile SVGs: `make -C .tools svgs` (or `d2 --layout=elk src.d2 src.svg`).
5. Add a row to the README learning-track table.
6. Run `make -C .tools fmt-md lint-md lint-langs` and fix any errors before committing.

## Adding a new monad detail page

1. Create `docs/monads/name.md` following the monad template above.
2. Create `docs/monads/diagrams/name.d2` and `docs/monads/diagrams/name-motivation.d2`.
3. Compile SVGs: `make -C .tools svgs`.
4. Add a row to the monad catalogue in `docs/10-monad.md` and in `README.md`.
5. Run `make -C .tools fmt-md lint-md lint-langs`.

## Renaming or renumbering docs

- Update the filename.
- Update the `# NN. Title` heading inside the file.
- Update every cross-link in other docs and in `README.md`.
- If the old file was tracked by git, use `git mv` to preserve history.
- Re-run `make -C .tools lint-md lint-langs`.
