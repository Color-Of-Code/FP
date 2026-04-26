# Category Theory Track

A **math-first parallel track** to the [FP learning track](../docs). Each page explains a category
theory concept precisely, maps it to its programming analog, and links to the corresponding chapter
in Bartosz Milewski's _Category Theory for Programmers_ (CTFP).

Pages contain **no per-language code**. For code examples, follow the FP track links.

> Document template and cross-linking rules:
> [`specs/ct-doc-structure.md`](../specs/ct-doc-structure.md)

---

## Concept catalog

| CT Concept                                            | One-line summary                                                | FP Analog                                    | CTFP Part/Ch |
| ----------------------------------------------------- | --------------------------------------------------------------- | -------------------------------------------- | ------------ |
| [Category](./category.md)                             | Objects, morphisms, composition, identity                       | Types & functions; composition               | 1.1, 1.3     |
| [Types & Functions](./types-functions.md)             | Hask as a category: types = objects, pure functions = morphisms | All of functional programming                | 1.2          |
| [Product & Coproduct](./product-coproduct.md)         | Universal constructions for pairing and choice                  | Product types (tuples) & sum types (enums)   | 1.5, 1.6     |
| [Functor](./functor.md)                               | Structure-preserving map between categories                     | `Functor` / `fmap`                           | 1.7, 1.8     |
| [Natural Transformation](./natural-transformation.md) | Morphism between functors; a family of component maps           | Polymorphic functions `F a → G a`            | 1.10         |
| [Kleisli Category](./kleisli.md)                      | Category built from Kleisli arrows of a monad                   | `>=>` (fish operator); `Kleisli m` Arrow     | 1.4          |
| [Monad](./monad.md)                                   | Monoid in the category of endofunctors; Kleisli triple          | `Monad` / `>>=` / `return`                   | 1.4, 3.4–3.6 |
| [Comonad](./comonad.md)                               | Dual of monad: extract from context, extend across context      | `extract` / `extend`; Store comonad as lens  | 3.7          |
| [Yoneda Lemma](./yoneda.md)                           | Every functor is determined by its natural transformations out  | Church encoding; van Laarhoven lenses        | 2.5, 2.6     |
| [Adjunction](./adjunction.md)                         | Universal relation between two functors; factory of monads      | Free/forgetful pairs; monad derivation       | 3.2–3.3      |
| [F-Algebra](./f-algebra.md)                           | Algebras for an endofunctor; initial algebra as fixed point     | Recursion schemes: catamorphism, anamorphism | 3.8–3.9      |
| [Lambda Calculus](./lambda-calculus.md)               | The formal computation model behind every FP language           | λ literals, β-reduction, Y combinator, SKI   | 1.2, 1.9     |

---

## Reading order

CT is a web, not a line — but this order minimises forward references:

1. [Category](./category.md)
2. [Types & Functions](./types-functions.md)
3. [Product & Coproduct](./product-coproduct.md)
4. [Functor](./functor.md)
5. [Natural Transformation](./natural-transformation.md)
6. [Kleisli Category](./kleisli.md)
7. [Monad](./monad.md)
8. [Comonad](./comonad.md)
9. [Yoneda Lemma](./yoneda.md)
10. [Adjunction](./adjunction.md)
11. [F-Algebra](./f-algebra.md)
12. [Lambda Calculus](./lambda-calculus.md)

---

## CTFP source

The LaTeX source for CTFP lives at
[`hmemcpy/milewski-ctfp-pdf`](https://github.com/hmemcpy/milewski-ctfp-pdf). A local copy of the
source is in [`../ctpf/`](../ctpf/) (if the submodule is initialised).

| CTFP Part | Chapters | GitHub source directory                                                                                                                                                                           |
| --------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Part 1    | 1–10     | [`src/content/1.1/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.1) … [`src/content/1.10/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.10) |
| Part 2    | 1–6      | [`src/content/2.1/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/2.1) … [`src/content/2.6/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/2.6)   |
| Part 3    | 1–15     | [`src/content/3.1/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.1) … [`src/content/3.15/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.15) |
