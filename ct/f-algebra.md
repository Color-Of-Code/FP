# F-Algebra

An **F-algebra** is a structure built from an endofunctor $F$: a carrier object $A$ together with an
evaluation morphism $F A \to A$. The **initial F-algebra** provides the canonical recursive type for
$F$, making F-algebras the categorical foundation of recursion schemes.

## Definition

Let $F : \mathcal{C} \to \mathcal{C}$ be an endofunctor.

An **F-algebra** is a pair $(A, \alpha)$ where $A$ is an object in $\mathcal{C}$ (the **carrier**)
and $\alpha : F A \to A$ is a morphism (the **structure map** or evaluation).

A **morphism of F-algebras** from $(A, \alpha)$ to $(B, \beta)$ is a morphism $h : A \to B$ in
$\mathcal{C}$ such that the following square commutes:

$$
\begin{array}{ccc}
  FA & \xrightarrow{\alpha} & A \\
  {Fh}\downarrow & & \downarrow{h} \\
  FB & \xrightarrow{\beta} & B
\end{array}
$$

F-algebras and their morphisms form a category $F\text{-}\mathbf{Alg}$.

### Initial algebra

The **initial F-algebra** $(\mu F, \mathrm{in})$ — if it exists — is an F-algebra with a unique
morphism to every other F-algebra. By **Lambek's lemma** the structure map
$\mathrm{in} : F(\mu F) \to \mu F$ is an isomorphism, so $\mu F \cong F(\mu F)$: the carrier is a
fixed point of $F$.

### F-coalgebra and anamorphism

Dually, an **F-coalgebra** is a pair $(A, \alpha)$ with $\alpha : A \to F A$. The terminal
F-coalgebra $(\nu F, \mathrm{out})$ is the greatest fixed point, corresponding to potentially
infinite (corecursive) structures.

## FP Analog

In Hask, the initial algebra of a functor $F$ corresponds to the **recursive type** `Fix F`:

```haskell
newtype Fix f = Fix { unFix :: f (Fix f) }
```

The structure map `in = Fix` and its inverse `out = unFix` correspond to Lambek's isomorphism.

| CT concept                 | Haskell                                      | Meaning                               |
| -------------------------- | -------------------------------------------- | ------------------------------------- |
| Endofunctor $F$            | Base functor `f` (e.g. `ListF a`, `TreeF a`) | Shape of one layer                    |
| F-algebra $(A, \alpha)$    | `f a -> a`                                   | How to evaluate one layer to a result |
| Initial algebra $\mu F$    | `Fix f`                                      | Full recursive type                   |
| Catamorphism `cata`        | `(f a -> a) -> Fix f -> a`                   | Fold over any F-algebra               |
| F-coalgebra $(A, \alpha)$  | `a -> f a`                                   | How to unfold one layer from a seed   |
| Terminal coalgebra $\nu F$ | `Fix f` (also, for corecursion)              | Potentially infinite type             |
| Anamorphism `ana`          | `(a -> f a) -> a -> Fix f`                   | Unfold from any F-coalgebra           |
| Hylomorphism `hylo`        | `(f b -> b) -> (a -> f a) -> a -> b`         | Unfold then fold                      |

→ FP track: [28. Recursion Schemes](../docs/28-recursion-schemes.md) |
[7. Algebraic Data Types](../docs/07-adt.md)

## CTFP Reference

| Resource                        | Link                                                                                           |
| ------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — F-Algebras          | [Part 3 Ch 8](http://bartoszmilewski.com/2017/02/28/f-algebras/)                               |
| CTFP blog — Algebras for Monads | [Part 3 Ch 9](http://bartoszmilewski.com/2017/03/14/algebras-for-monads/)                      |
| CTFP LaTeX source Ch 3.8        | [`src/content/3.8/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.8) |
| CTFP LaTeX source Ch 3.9        | [`src/content/3.9/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.9) |

## See Also

- [Functor](./functor.md) — $F$ is the endofunctor
- [Monad](./monad.md) — Eilenberg–Moore algebras are F-algebras for a monad
- [Product & Coproduct](./product-coproduct.md) — base functors are built from products and
  coproducts
