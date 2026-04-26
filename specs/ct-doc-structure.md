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

## CTFP chapter coverage

The table below maps every CTFP chapter to its `ct/` page and the primary `docs/` chapter it
supports. Use this when deciding whether a new `ct/` page is worth adding: create one when a CTFP
chapter has a **direct analog in `docs/`** and the CT perspective genuinely illuminates the FP
concept.

| CTFP     | Title                       | `ct/` page                  | Primary `docs/` analog                         | Status       |
| -------- | --------------------------- | --------------------------- | ---------------------------------------------- | ------------ |
| 1.1, 1.3 | Category / Composition      | `category.md`               | `04-composition.md`                            | ✅           |
| 1.2      | Types & Functions           | `types-functions.md`        | `01-function.md`                               | ✅           |
| 1.4      | Kleisli Categories          | `kleisli.md`                | `19-monad.md`, `26-arrows.md`                  | ✅           |
| 1.5–1.6  | Products & Coproducts       | `product-coproduct.md`      | `07-adt.md`                                    | ✅           |
| 1.7–1.8  | Functors / Functoriality    | `functor.md`                | `13-functor.md`                                | ✅           |
| 1.9      | Function Types              | `lambda-calculus.md`        | `01-function.md`, `31-computation-models.md`   | ✅ (partial) |
| 1.10     | Natural Transformations     | `natural-transformation.md` | `14-natural-transformations.md`                | ✅           |
| 2.1      | Declarative Programming     | —                           | philosophical survey; no CT page needed        | ➖           |
| 2.2      | Limits & Colimits           | `limits-colimits.md`        | `07-adt.md`                                    | ✅           |
| 2.3      | Free Monoids                | `free-monoid.md`            | `11-semigroup-monoid.md`                       | ✅           |
| 2.4      | Representable Functors      | `representable.md`          | `13-functor.md`, `20-comonad.md`               | ✅           |
| 2.5–2.6  | Yoneda Lemma / Embedding    | `yoneda.md`                 | `25-profunctor.md`, `27-optics.md`             | ✅           |
| 3.1      | It's All About Morphisms    | —                           | survey; no dedicated CT page needed            | ➖           |
| 3.2–3.3  | Adjunctions                 | `adjunction.md`             | `06-currying.md`, `19-monad.md`                | ✅           |
| 3.4–3.6  | Monads                      | `monad.md`                  | `19-monad.md`                                  | ✅           |
| 3.7      | Comonads                    | `comonad.md`                | `20-comonad.md`                                | ✅           |
| 3.8–3.9  | F-Algebras                  | `f-algebra.md`              | `28-recursion-schemes.md`                      | ✅           |
| 3.10     | Ends & Coends               | `ends-coends.md`            | `25-profunctor.md`                             | ✅           |
| 3.11     | Kan Extensions              | `kan-extensions.md`         | `14-natural-transformations.md`                | ✅           |
| 3.12     | Enriched Categories         | —                           | very abstract; defer                           | ➖           |
| 3.13     | Topoi                       | —                           | very abstract; defer                           | ➖           |
| 3.14     | Lawvere Theories            | `lawvere-theories.md`       | `09-type-classes.md`, `11-semigroup-monoid.md` | ✅           |
| 3.15     | Monads, Monoids, Categories | —                           | extends `monad.md`                             | 🔲 candidate |
| —        | Lambda Calculus             | `lambda-calculus.md`        | `01-function.md`, `31-computation-models.md`   | ✅           |

**Status key:** ✅ done · 🔲 good candidate for a new page · ➖ no page warranted
