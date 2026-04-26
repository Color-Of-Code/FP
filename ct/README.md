# Category Theory Track

A **math-first parallel track** to the [FP learning track](../docs). Each page explains a category
theory concept precisely, maps it to its programming analog, and links to the corresponding chapter
in Bartosz Milewski's _Category Theory for Programmers_ (CTFP).

Pages contain **no per-language code**. For code examples, follow the FP track links.

> Document template and cross-linking rules:
> [`specs/ct-doc-structure.md`](../specs/ct-doc-structure.md)

---

## Concept catalog

| CT Concept                                            | One-line summary                                                                | FP Analog                                     | CTFP Part/Ch |
| ----------------------------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------- | ------------ |
| [Category](./category.md)                             | Objects, morphisms, composition, identity                                       | Types & functions; composition                | 1.1, 1.3     |
| [Types & Functions](./types-functions.md)             | Hask as a category: types = objects, pure functions = morphisms                 | All of functional programming                 | 1.2          |
| [Product & Coproduct](./product-coproduct.md)         | Universal constructions for pairing and choice                                  | Product types (tuples) & sum types (enums)    | 1.5, 1.6     |
| [Limits & Colimits](./limits-colimits.md)             | Terminal/initial cones over a diagram; products and coproducts as special cases | `()`, `Void`, tuples, `Either`                | 2.2          |
| [Functor](./functor.md)                               | Structure-preserving map between categories                                     | `Functor` / `fmap`                            | 1.7, 1.8     |
| [Natural Transformation](./natural-transformation.md) | Morphism between functors; a family of component maps                           | Polymorphic functions `F a → G a`             | 1.10         |
| [Kleisli Category](./kleisli.md)                      | Category built from Kleisli arrows of a monad                                   | `>=>` (fish operator); `Kleisli m` Arrow      | 1.4          |
| [Monad](./monad.md)                                   | Monoid in the category of endofunctors; Kleisli triple                          | `Monad` / `>>=` / `return`                    | 1.4, 3.4–3.6 |
| [Comonad](./comonad.md)                               | Dual of monad: extract from context, extend across context                      | `extract` / `extend`; Store comonad as lens   | 3.7          |
| [Yoneda Lemma](./yoneda.md)                           | Every functor is determined by its natural transformations out                  | Church encoding; van Laarhoven lenses         | 2.5, 2.6     |
| [Representable Functors](./representable.md)          | Functors isomorphic to a hom-functor; index/tabulate duality                    | `Representable`; `Stream`; memoisation        | 2.4          |
| [Free Monoid](./free-monoid.md)                       | List as the initial monoid; universal homomorphism                              | `[a]`; `foldMap` as unique homomorphism       | 2.3          |
| [Ends & Coends](./ends-coends.md)                     | Twisted limits/colimits; `forall` and `exists` in types                         | `forall c. P c c`; profunctor composition     | 3.10         |
| [Adjunction](./adjunction.md)                         | Universal relation between two functors; factory of monads                      | Free/forgetful pairs; monad derivation        | 3.2–3.3      |
| [Kan Extensions](./kan-extensions.md)                 | Right/left extensions along a functor; all CT concepts generalised              | Codensity monad; `Ran`/`Lan` types            | 3.11         |
| [Lawvere Theories](./lawvere-theories.md)             | Algebraic theories as categories with finite products                           | Type classes as theories; instances as models | 3.14         |
| [F-Algebra](./f-algebra.md)                           | Algebras for an endofunctor; initial algebra as fixed point                     | Recursion schemes: catamorphism, anamorphism  | 3.8–3.9      |
| [Lambda Calculus](./lambda-calculus.md)               | The formal computation model behind every FP language                           | λ literals, β-reduction, Y combinator, SKI    | 1.2, 1.9     |

---

## Reading order

CT is a web, not a line — but this order minimises forward references:

1. [Category](./category.md)
2. [Types & Functions](./types-functions.md)
3. [Product & Coproduct](./product-coproduct.md)
4. [Limits & Colimits](./limits-colimits.md)
5. [Functor](./functor.md)
6. [Natural Transformation](./natural-transformation.md)
7. [Kleisli Category](./kleisli.md)
8. [Monad](./monad.md)
9. [Comonad](./comonad.md)
10. [Yoneda Lemma](./yoneda.md)
11. [Representable Functors](./representable.md)
12. [Free Monoid](./free-monoid.md)
13. [Ends & Coends](./ends-coends.md)
14. [Adjunction](./adjunction.md)
15. [Kan Extensions](./kan-extensions.md)
16. [Lawvere Theories](./lawvere-theories.md)
17. [F-Algebra](./f-algebra.md)
18. [Lambda Calculus](./lambda-calculus.md)

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
