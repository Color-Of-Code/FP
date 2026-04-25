# Adjunction

An **adjunction** $F \dashv G$ is a universal relationship between two functors: every morphism
$F A \to B$ corresponds bijectively and naturally to a morphism $A \to G B$. Adjunctions are the
categorical origin of most monads.

## Definition

Let $F : \mathcal{C} \to \mathcal{D}$ and $G : \mathcal{D} \to \mathcal{C}$. We say $F$ is **left
adjoint** to $G$ (written $F \dashv G$) if there is a natural bijection

$$\mathcal{D}(F A, B) \cong \mathcal{C}(A, G B)$$

for all objects $A \in \mathcal{C}$ and $B \in \mathcal{D}$.

The bijection is given by two natural transformations:

- **Unit**: $\eta : \mathrm{Id}_{\mathcal{C}} \Rightarrow G \circ F$ with components
  $\eta_A : A \to G(FA)$
- **Counit**: $\varepsilon : F \circ G \Rightarrow \mathrm{Id}_{\mathcal{D}}$ with components
  $\varepsilon_B : F(GB) \to B$

### Triangle identities

$$G \varepsilon \circ \eta G = \mathrm{id}_G \qquad \varepsilon F \circ F \eta = \mathrm{id}_F$$

These ensure that unit and counit are mutual inverses in the appropriate sense.

## Adjunctions generate monads

Every adjunction $F \dashv G$ produces a monad $G \circ F$ on $\mathcal{C}$:

- **Unit** of the monad: $\eta : \mathrm{Id} \Rightarrow G \circ F$ (the adjunction unit)
- **Multiplication**: $\mu = G \varepsilon F : G F G F \Rightarrow G F$ (counit sandwiched)

Every monad arises from an adjunction — specifically from its Kleisli adjunction or its
Eilenberg–Moore adjunction.

## FP Analog

The most prominent programming adjunction is the **curry/uncurry** pair:

$$({-} \times A) \dashv (A \Rightarrow {-})$$

The bijection is currying:

$$\mathtt{uncurry}\;f = f' \iff \mathtt{curry}\;f' = f$$

$$\mathtt{(A, B) \to C} \cong \mathtt{A \to (B \to C)}$$

This adjunction generates the **Reader monad** `(->) r`.

Other adjunctions of interest:

| Left adjoint $F$      | Right adjoint $G$     | Generated monad                 |
| --------------------- | --------------------- | ------------------------------- |
| Free monoid $({-})^*$ | Forgetful             | List monad `[]`                 |
| $({-}) \times S$      | $S \Rightarrow ({-})$ | State monad `State S`           |
| Discrete category     | Constant functor      | (foundational; no single monad) |

→ FP track: [6. Currying & Partial Application](../docs/06-currying.md) |
[15. Monad](../docs/15-monad.md)

## CTFP Reference

| Resource                               | Link                                                                                           |
| -------------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Adjunctions                | [Part 3 Ch 2](http://bartoszmilewski.com/2016/04/18/adjunctions/)                              |
| CTFP blog — Free/Forgetful Adjunctions | [Part 3 Ch 3](http://bartoszmilewski.com/2016/06/15/freeforgetful-adjunctions/)                |
| CTFP LaTeX source Ch 3.2               | [`src/content/3.2/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.2) |
| CTFP LaTeX source Ch 3.3               | [`src/content/3.3/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.3) |

## See Also

- [Functor](./functor.md) — $F$ and $G$ are functors
- [Natural Transformation](./natural-transformation.md) — unit and counit are NTs
- [Monad](./monad.md) — every monad arises from an adjunction
