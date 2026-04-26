# Kleisli Category

A **Kleisli category** is a category constructed from a monad: its morphisms are the **Kleisli
arrows** $A \to M B$ of the underlying category, composed using the monad's bind. Every monad
defines a Kleisli category, and every adjunction whose composition forms the monad factors through
it.

## Definition

Let $(M, \eta, \mu)$ be a monad on a category $\mathcal{C}$.

The **Kleisli category** $\mathcal{C}_M$ is defined as:

- **Objects**: the same as in $\mathcal{C}$
- **Morphisms**: $\mathrm{Hom}_{\mathcal{C}_M}(A, B) = \mathrm{Hom}_\mathcal{C}(A, M B)$ (a Kleisli
  arrow from $A$ to $B$ is an ordinary arrow from $A$ to $M B$)
- **Composition**: for $f : A \to M B$ and $g : B \to M C$,

$$g \mathbin{\star} f \;=\; \mu_C \circ M g \circ f \;=\; f \mathbin{\mathtt{>>=}} g$$

- **Identity**: $\mathrm{id}_A^{M} = \eta_A : A \to M A$ (the monad unit)

### Functorial structure

There is an adjunction

$$\mathcal{C} \underset{R}{\overset{L}{\rightleftharpoons}} \mathcal{C}_M$$

where $L A = A$ (on objects) and $L f = \eta_B \circ f$ (on morphisms), and $R A = M A$.  
The composition $R \circ L = M$ recovers the original monad from the adjunction.

### Equivalence with the Eilenberg-Moore category

A monad also defines the **Eilenberg-Moore category** $\mathcal{C}^M$ of $M$-algebras. The Kleisli
category is the "free" side: $\mathcal{C}_M$ consists of the free algebras; $\mathcal{C}^M$ consists
of all algebras. Every monad factors as

$$\mathcal{C} \xrightarrow{L} \mathcal{C}_M \hookrightarrow \mathcal{C}^M \xrightarrow{R} \mathcal{C}$$

## Laws

Kleisli composition is associative and has units because $\mathcal{C}_M$ is a valid category:

**Left unit:** $(f \mathbin{\star} \eta_A) = f \qquad$ i.e. `return >>= f = f`

**Right unit:** $(\eta_B \mathbin{\star} f) = f \qquad$ i.e. `f >>= return = f`

**Associativity:**
$h \mathbin{\star} (g \mathbin{\star} f) = (h \mathbin{\star} g) \mathbin{\star} f \qquad$ i.e.
`(f >>= g) >>= h = f >>= (g >=> h)`

These are precisely the **monad laws** expressed as category-theoretic axioms for $\mathcal{C}_M$.

## FP Analog

| CT concept                                | Haskell / FP                                                                   |
| ----------------------------------------- | ------------------------------------------------------------------------------ |
| Kleisli arrow $A \to M B$                 | `a -> m b` — a monadic function                                                |
| Kleisli composition $g \mathbin{\star} f$ | `(>=>)` — the fish operator: `f >=> g = \x -> f x >>= g`                       |
| Identity Kleisli arrow $\eta_A$           | `return` / `pure`                                                              |
| $\mathcal{C}_M$ as a category             | The monad laws are exactly the category laws for $\mathcal{C}_M$               |
| Arrow (Haskell)                           | A `Kleisli m a b` newtype wraps `a -> m b`; `Arrow` generalises Kleisli arrows |
| `>>=`                                     | The bind operation _is_ Kleisli composition with arguments flipped             |

The `Kleisli` newtype in Haskell makes this correspondence explicit:

```haskell
newtype Kleisli m a b = Kleisli { runKleisli :: a -> m b }
instance Monad m => Category (Kleisli m)    -- composition = (>=>)
instance Monad m => Arrow    (Kleisli m)    -- arr f = Kleisli (return . f)
```

Every monad gives a `Kleisli` `Arrow`; the converse does not hold (not every `Arrow` comes from a
monad).

→ FP track: [19. Monad](../docs/19-monad.md) — `>>=` as Kleisli composition |
[26. Arrows](../docs/26-arrows.md) — `Kleisli m` as the canonical `Arrow` example

## CTFP Reference

| Resource                       | Link                                                                                           |
| ------------------------------ | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Kleisli Categories | [Part 1 Ch 4](https://bartoszmilewski.com/2014/12/23/kleisli-categories/)                      |
| CTFP LaTeX source Ch 1.4       | [`src/content/1.4/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.4) |

## See Also

- [Monad](./monad.md) — the monad whose Kleisli category this is; laws are equivalent
- [Adjunction](./adjunction.md) — every adjunction $L \dashv R$ gives a monad $R \circ L$, and its
  Kleisli category is the image of $L$
- [Category](./category.md) — $\mathcal{C}_M$ is a full category in its own right
