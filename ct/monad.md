# Monad

A **monad** is a monoid in the category of endofunctors: an endofunctor $M$ on a category
$\mathcal{C}$ equipped with two natural transformations — unit and multiplication — satisfying
associativity and unit laws. In programming it is also described as a **Kleisli triple**.

## Definition

### Categorical (monad as a monoid)

A **monad** on $\mathcal{C}$ is a triple $(M, \eta, \mu)$ where:

- $M : \mathcal{C} \to \mathcal{C}$ is an endofunctor
- $\eta : \mathrm{Id} \Rightarrow M$ is the **unit** (natural transformation)
- $\mu : M \circ M \Rightarrow M$ is the **multiplication / join** (natural transformation)

### Kleisli triple

Equivalently, a monad is $(M, \mathrm{return}, \mathtt{>>=})$ where:

- $M A$ is the type of "computations returning $A$"
- $\mathrm{return} : A \to M A$ lifts a pure value
- $\mathtt{>>=} : M A \to (A \to M B) \to M B$ sequences computations (bind)

The two presentations are related by $\mathtt{join} = \mu$ and
$m \mathtt{>>=} f = \mu \circ M f(m)$.

### Kleisli category

For a monad $M$, the **Kleisli category** $\mathcal{C}_M$ has:

- The same objects as $\mathcal{C}$
- Morphisms $A \to B$ in $\mathcal{C}_M$ are morphisms $A \to M B$ in $\mathcal{C}$ (Kleisli arrows)
- Composition of $f : A \to M B$ and $g : B \to M C$ is
  $g \mathbin{\star} f = \mu_C \circ M g \circ f$
- Identity: $\mathrm{return}_A : A \to M A$

## Laws

**Left unit:**

$$\mu \circ \eta M = \mathrm{id}_M$$

**Right unit:**

$$\mu \circ M \eta = \mathrm{id}_M$$

**Associativity:**

$$\mu \circ \mu M = \mu \circ M \mu$$

In Kleisli notation these are the **monad laws**:

$$\mathtt{return} \mathbin{\mathtt{>>=}} f \;=\; f$$

$$m \mathbin{\mathtt{>>=}} \mathtt{return} \;=\; m$$

$$
(m \mathbin{\mathtt{>>=}} f) \mathbin{\mathtt{>>=}} g
\;=\;
m \mathbin{\mathtt{>>=}} (\lambda x \to f\,x \mathbin{\mathtt{>>=}} g)
$$

## FP Analog

| CT concept               | Haskell                        | Meaning                         |
| ------------------------ | ------------------------------ | ------------------------------- |
| Endofunctor $M$          | Type constructor `m :: * -> *` | Computation type                |
| Unit $\eta_A$            | `return :: a -> m a`           | Lift pure value                 |
| Multiplication $\mu_A$   | `join :: m (m a) -> m a`       | Flatten nested computation      |
| Kleisli arrow $A \to MB$ | `a -> m b`                     | Effectful function              |
| Kleisli composition      | `(>=>)` (fish operator)        | Chaining effectful functions    |
| Bind                     | `(>>=)`                        | Sequence: run then feed to next |

Every monad instance (`Maybe`, `[]`, `IO`, `State`, …) is a concrete realisation of this structure.

→ FP track: [16. Monad](../docs/16-monad.md) | [17. Monad Transformers](../docs/17-transformer.md)

## CTFP Reference

| Resource                                    | Link                                                                                           |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Kleisli Categories              | [Part 1 Ch 4](http://bartoszmilewski.com/2014/12/23/kleisli-categories/)                       |
| CTFP blog — Monads: Programmer's Definition | [Part 3 Ch 4](http://bartoszmilewski.com/2016/11/21/monads-programmers-definition/)            |
| CTFP blog — Monads and Effects              | [Part 3 Ch 5](http://bartoszmilewski.com/2016/11/30/monads-and-effects/)                       |
| CTFP blog — Monads Categorically            | [Part 3 Ch 6](http://bartoszmilewski.com/2016/12/27/monads-categorically/)                     |
| CTFP LaTeX source Ch 1.4                    | [`src/content/1.4/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.4) |
| CTFP LaTeX source Ch 3.4                    | [`src/content/3.4/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.4) |
| CTFP LaTeX source Ch 3.5                    | [`src/content/3.5/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.5) |
| CTFP LaTeX source Ch 3.6                    | [`src/content/3.6/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.6) |

## See Also

- [Functor](./functor.md) — $M$ is an endofunctor
- [Natural Transformation](./natural-transformation.md) — $\eta$ and $\mu$ are NTs
- [Adjunction](./adjunction.md) — every adjunction generates a monad
