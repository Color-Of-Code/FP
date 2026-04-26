# Limits and Colimits

**Limits** and **colimits** are universal constructions that generalise many concrete patterns in
category theory — products, coproducts, pullbacks, equalisers, terminal and initial objects — into a
single definition. They are the categorical way to express "best fit" or "most general" object
satisfying a shape constraint.

## Definition

### Diagrams and cones

A **diagram** of shape $J$ in $\mathcal{C}$ is a functor $D : J \to \mathcal{C}$ (a selection of
objects and morphisms indexed by the small category $J$).

A **cone** over $D$ with apex $N$ is an object $N \in \mathcal{C}$ together with morphisms
$\psi_j : N \to D(j)$ for every $j \in J$, such that for every $f : j \to k$ in $J$:

$$D(f) \circ \psi_j = \psi_k$$

### Limit

A **limit** of $D$ is a **terminal cone**: a cone $(\varprojlim D,\; \lambda)$ such that for any
other cone $(N, \psi)$ there is a unique morphism $u : N \to \varprojlim D$ commuting with all
projections:

$$\lambda_j \circ u = \psi_j \qquad \text{for all } j$$

### Colimit

A **colimit** of $D$ is an **initial cocone**: a cone $(\varinjlim D,\; \iota)$ going the other way
(morphisms $\iota_j : D(j) \to \varinjlim D$), universal among all such cocones.

Limits and colimits are dual: a colimit in $\mathcal{C}$ is a limit in $\mathcal{C}^{op}$.

### Special cases

| Shape $J$                                    | Limit                        | Colimit                     |
| -------------------------------------------- | ---------------------------- | --------------------------- |
| Empty ($J = \varnothing$)                    | Terminal object $\mathbf{1}$ | Initial object $\mathbf{0}$ |
| Discrete two objects                         | Binary product $A \times B$  | Binary coproduct $A + B$    |
| Parallel pair $f, g : A \rightrightarrows B$ | Equaliser                    | Coequaliser                 |
| Span $A \leftarrow C \rightarrow B$          | Pullback                     | Pushout                     |

## Laws

Limits and colimits, when they exist, are **unique up to unique isomorphism** (by universality).

A category with all small limits is called **complete**; with all small colimits, **cocomplete**.
$\mathbf{Set}$ is both complete and cocomplete.

**Preservation**: A functor $F$ **preserves** limits if it maps limit cones to limit cones. Right
adjoints preserve limits; left adjoints preserve colimits.

## FP Analog

| CT concept                                    | Haskell / FP                                                               |
| --------------------------------------------- | -------------------------------------------------------------------------- |
| Terminal object $\mathbf{1}$                  | `()` — unit type; every type has a unique function to `()`                 |
| Initial object $\mathbf{0}$                   | `Void` — empty type; `absurd :: Void -> a`                                 |
| Binary product $A \times B$                   | `(a, b)` — tuple; projections `fst`, `snd`                                 |
| Binary coproduct $A + B$                      | `Either a b` — projections `Left`, `Right`                                 |
| Equaliser                                     | Subtype / `filter`-like restriction                                        |
| Pullback                                      | Fibered product — used in dependent types                                  |
| Colimit of types                              | `newtype` fusion; free data types                                          |
| Initial algebra (colimit of $F^n \mathbf{0}$) | Recursive data types: `data List a = Nil \| Cons a (List a)`               |
| `Limit` / `Colimit` in `kan-extensions`       | `type Limit f = forall j. f j`; `data Colimit f = forall j. Colimit (f j)` |

The **initial algebra** of a functor $F$ is a colimit — specifically the colimit of the chain
$\mathbf{0} \to F\mathbf{0} \to F^2\mathbf{0} \to \cdots$ — giving every recursive data type its
categorical foundation. (See [F-Algebra](./f-algebra.md).)

→ FP track: [7. Algebraic Data Types](../docs/07-adt.md) — products/coproducts as limits/colimits |
[28. Recursion Schemes](../docs/28-recursion-schemes.md) — initial algebra as fixed-point colimit

## CTFP Reference

| Resource                        | Link                                                                                           |
| ------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Limits and Colimits | [Part 2 Ch 2](https://bartoszmilewski.com/2015/04/15/limits-and-colimits/)                     |
| CTFP LaTeX source Ch 2.2        | [`src/content/2.2/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/2.2) |

## See Also

- [Product & Coproduct](./product-coproduct.md) — the binary cases of limit and colimit
- [F-Algebra](./f-algebra.md) — initial algebra is the colimit of the free-monad chain
- [Adjunction](./adjunction.md) — right adjoints preserve limits; left adjoints preserve colimits
- [Kan Extensions](./kan-extensions.md) — limits and colimits are special cases of Kan extensions
