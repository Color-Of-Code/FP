# Category

A **category** is the most basic structure in category theory: a collection of objects connected by
directed arrows (morphisms) that compose associatively and carry an identity.

## Definition

A category $\mathcal{C}$ consists of:

- A collection of **objects** $\mathrm{ob}(\mathcal{C})$
- For every pair of objects $A, B$, a collection of **morphisms** (arrows) $\mathcal{C}(A, B)$
- A **composition** operation: given $f : A \to B$ and $g : B \to C$, produce $g \circ f : A \to C$
- For every object $A$, an **identity morphism** $\mathrm{id}_A : A \to A$

## Laws

**Associativity** — composition does not depend on the grouping:

$$h \circ (g \circ f) = (h \circ g) \circ f$$

**Left identity** and **right identity** — $\mathrm{id}$ is a neutral element for composition:

$$\mathrm{id}_B \circ f = f \qquad f \circ \mathrm{id}_A = f$$

These are the _only_ requirements. A category says nothing about what objects _are_ or what
morphisms _do_ internally.

## Key examples

| Category                 | Objects                  | Morphisms                                        |
| ------------------------ | ------------------------ | ------------------------------------------------ |
| **Set**                  | Sets                     | Total functions                                  |
| **Hask**                 | Haskell types            | Pure Haskell functions                           |
| **1**                    | A single object          | Only $\mathrm{id}$                               |
| **Monoid as category**   | One object               | Elements of the monoid (composition = monoid op) |
| **Preorder as category** | Elements of the preorder | At most one arrow $A \to B$ iff $A \le B$        |

## FP Analog

In **Hask**, types are objects and pure functions are morphisms. Function composition (`(.)` in
Haskell, `>>` or `|>` in many other languages) is category composition, and `id` is the identity
morphism.

The category laws correspond directly to the algebraic properties programmers expect from
composition:

- Associativity: `(h . g) . f == h . (g . f)`
- Identity: `id . f == f` and `f . id == f`

→ FP track: [4. Composition](../docs/04-composition.md)

## CTFP Reference

| Resource                                         | Link                                                                                           |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Category: The Essence of Composition | [Part 1 Ch 1](http://bartoszmilewski.com/2014/11/04/category-the-essence-of-composition/)      |
| CTFP blog — Categories Great and Small           | [Part 1 Ch 3](http://bartoszmilewski.com/2014/12/05/categories-great-and-small/)               |
| CTFP LaTeX source Ch 1.1                         | [`src/content/1.1/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.1) |
| CTFP LaTeX source Ch 1.3                         | [`src/content/1.3/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.3) |

## See Also

- [Types & Functions](./types-functions.md) — Hask as a concrete category
- [Functor](./functor.md) — structure-preserving maps _between_ categories
