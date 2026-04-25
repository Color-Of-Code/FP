# CT Track — Document Structure

The `ct/` folder is a **math-first parallel track** to the FP learning track in `docs/`.

## Purpose

Every abstraction in `docs/` (Functor, Monad, ADT, …) has a precise mathematical origin in
**category theory**. The CT track explains that origin: what the concept _is_ formally, what laws it
satisfies, and how the FP version is a specialisation or instance of it.

`ct/` pages contain **no per-language code examples**. Code lives in `docs/`. CT pages are
mathematical prose and notation only.

## Mandatory sections

Every `ct/` page (except `ct/README.md`) must contain these sections in order:

### 1. Title heading — `# <Concept>`

The standard CT name, e.g. `# Functor`.

### 2. One-line summary

A single sentence capturing the essence, _before_ any heading.

### 3. `## Definition`

Formal or semi-formal definition. Use standard mathematical notation:

- Objects/morphisms in a category $C$
- Composition: $g \circ f$
- Identity morphism: $\mathrm{id}_A$
- Natural transformation component: $\eta_A : FA \to GA$
- Commutative diagrams described in prose or as lists (D2 diagrams are optional)

### 4. `## Laws`

Equational laws the concept must satisfy, written as equations.

### 5. `## FP Analog`

What the CT concept becomes in a programming context. Explain the mapping (e.g. _"objects = types,
morphisms = functions"_) and link to the corresponding FP track chapter:

```markdown
→ FP track: [11. Functor](../docs/11-functor.md)
```

### 6. `## CTFP Reference`

A table linking to Bartosz Milewski's _Category Theory for Programmers_:

```markdown
| Resource          | Link                                                                                           |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog post    | [Chapter title](https://bartoszmilewski.com/…)                                                 |
| CTFP LaTeX source | [`src/content/N.N/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/N.N) |
```

For concepts covered in multiple chapters, list each row separately.

## Optional sections

- `## See Also` — cross-links to related `ct/` pages
- `## Diagram` — a D2 diagram stored in `ct/diagrams/`; if added, compile with `make -C .tools svgs`

## File naming

```text
ct/<kebab-concept-name>.md
```

No numeric prefix — CT pages are navigated via `ct/README.md`, not by sequential order.

## Cross-linking rules

- `ct/` → `docs/`: use relative path `../docs/NN-name.md`
- `docs/` → `ct/`: add a one-line note near the top of the `docs/` file:
  `> Mathematical background: [CT concept](../ct/concept.md)`
- `ct/` → `ct/`: use relative path `./other-concept.md`

## What does NOT belong in `ct/`

- Per-language code examples — those go in the corresponding `docs/` file
- Motivation sections comparing imperative vs functional style — that is `docs/` territory
- New FP concepts not yet in `docs/` — add the `docs/` entry first

## Tooling

`ct/` pages are formatted and linted with the same Markdown tooling:

```sh
make -C .tools fmt-md lint-md
```

The `lint-langs` check does **not** apply to `ct/` pages (they have no per-language sections). Do
not add `ct/` files to `SKIP_FILES` in `.tools/check-lang-order.js` — the checker only scans `docs/`
and `docs/monads/`.
