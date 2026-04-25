# Functor

A **functor** is a structure-preserving map between categories: it sends objects to objects and
morphisms to morphisms while respecting composition and identity.

## Definition

Let $\mathcal{C}$ and $\mathcal{D}$ be categories. A **functor** $F : \mathcal{C} \to \mathcal{D}$
consists of:

- An **object map**: for every object $A \in \mathcal{C}$, an object $F A \in \mathcal{D}$
- A **morphism map**: for every morphism $f : A \to B$ in $\mathcal{C}$, a morphism
  $F f : F A \to F B$ in $\mathcal{D}$

### Endofunctor

When $\mathcal{C} = \mathcal{D}$ the functor is an **endofunctor**. In programming all functors are
endofunctors on Hask — they map types to types and functions to functions within the same category.

### Bifunctor

A **bifunctor** is a functor from the product category $\mathcal{C} \times \mathcal{D}$ to
$\mathcal{E}$; it maps pairs of objects and lifts pairs of morphisms. Products and coproducts are
bifunctors.

### Contravariant functor

A **contravariant functor** $F : \mathcal{C}^{\mathrm{op}} \to \mathcal{D}$ reverses the direction
of morphisms: from $f : A \to B$ it produces $F f : F B \to F A$.

## Laws

**Preservation of identity:**

$$F(\mathrm{id}_A) = \mathrm{id}_{F A}$$

**Preservation of composition:**

$$F(g \circ f) = F g \circ F f$$

These laws ensure that a functor is not just any mapping but a _homomorphism_ of categorical
structure.

## FP Analog

In Hask, an endofunctor $F$ is a type constructor (e.g. `Maybe`, `[]`, `Tree`) together with an
`fmap` that lifts any function `a -> b` to `F a -> F b`.

| CT concept         | Haskell                           | Other languages         |
| ------------------ | --------------------------------- | ----------------------- |
| Object map $F A$   | Type constructor `f a`            | Generic type `F<A>`     |
| Morphism map $F f$ | `fmap f`                          | `.map(f)` / `Select(f)` |
| Identity law       | `fmap id == id`                   | —                       |
| Composition law    | `fmap (g . f) == fmap g . fmap f` | —                       |

The `Functor` type class in Haskell encodes exactly this structure. Every standard container
(`Maybe`, `[]`, `Either e`, `IO`) is a functor.

→ FP track: [11. Functor](../docs/11-functor.md)

## CTFP Reference

| Resource                  | Link                                                                                           |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Functors      | [Part 1 Ch 7](http://bartoszmilewski.com/2015/01/20/functors/)                                 |
| CTFP blog — Functoriality | [Part 1 Ch 8](http://bartoszmilewski.com/2015/02/03/functoriality/)                            |
| CTFP LaTeX source Ch 1.7  | [`src/content/1.7/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.7) |
| CTFP LaTeX source Ch 1.8  | [`src/content/1.8/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.8) |

## See Also

- [Category](./category.md) — the source and target structures
- [Natural Transformation](./natural-transformation.md) — morphisms _between_ functors
- [Monad](./monad.md) — monads are monoids in the category of endofunctors
- [F-Algebra](./f-algebra.md) — algebras built over an endofunctor
