# Comonad

A **comonad** is the exact categorical dual of a monad: an endofunctor $W$ equipped with a
**counit** (extract) and a **comultiplication** (duplicate), satisfying co-unit and co-associativity
laws. Where monads model effectful computation flowing _into_ a context, comonads model
context-dependent computation flowing _out_.

## Definition

A **comonad** on $\mathcal{C}$ is a triple $(W, \varepsilon, \delta)$ where:

- $W : \mathcal{C} \to \mathcal{C}$ is an endofunctor
- $\varepsilon : W \Rightarrow \mathrm{Id}$ is the **counit** (natural transformation; called
  `extract` in Haskell)
- $\delta : W \Rightarrow W \circ W$ is the **comultiplication / duplicate** (natural
  transformation)

Dually to the monad's Kleisli triple, the comonad has a **co-Kleisli triple**:

- `extract :: W a -> a` — observe the focused value
- `extend :: (W a -> b) -> W a -> W b` — shift the focus and re-observe (cokleisli extension)

The two presentations are related by:

$$\mathrm{extend}\; f = W f \circ \delta \qquad \delta = \mathrm{extend}\;\mathrm{id}$$

### Co-Kleisli category

For a comonad $W$, the **co-Kleisli category** $\mathcal{C}^W$ has:

- The same objects as $\mathcal{C}$
- Morphisms $A \to B$ in $\mathcal{C}^W$ are morphisms $W A \to B$ in $\mathcal{C}$ (co-Kleisli
  arrows)
- Composition of $f : W A \to B$ and $g : W B \to C$ is $g \circ_W f = g \circ W f \circ \delta_A$
- Identity: $\varepsilon_A : W A \to A$

### Duality table

| Monad                                                     | Comonad                                                             |
| --------------------------------------------------------- | ------------------------------------------------------------------- |
| $\eta : \mathrm{Id} \Rightarrow M$ (unit / `return`)      | $\varepsilon : W \Rightarrow \mathrm{Id}$ (counit / `extract`)      |
| $\mu : M \circ M \Rightarrow M$ (multiplication / `join`) | $\delta : W \Rightarrow W \circ W$ (comultiplication / `duplicate`) |
| Kleisli arrow $A \to M B$                                 | Co-Kleisli arrow $W A \to B$                                        |
| `>>=` (bind)                                              | `=>>` (cobind / `extend`)                                           |
| models effects flowing _in_                               | models context flowing _out_                                        |

## Laws

**Counit left:**

$$\varepsilon W \circ \delta = \mathrm{id}_W$$

**Counit right:**

$$W \varepsilon \circ \delta = \mathrm{id}_W$$

**Co-associativity:**

$$\delta W \circ \delta = W \delta \circ \delta$$

These are exactly the monad laws with all arrows reversed.

## FP Analog

| CT concept                         | Haskell                                             |
| ---------------------------------- | --------------------------------------------------- |
| Comonad $(W, \varepsilon, \delta)$ | `class Functor w => Comonad w`                      |
| Counit $\varepsilon$               | `extract :: w a -> a`                               |
| Comultiplication $\delta$          | `duplicate :: w a -> w (w a)`                       |
| Extension $\mathrm{extend}$        | `extend :: (w a -> b) -> w a -> w b`                |
| Co-Kleisli arrow $W A \to B$       | `w a -> b` (context-dependent transform)            |
| `Store s a` comonad                | Lens as a comonad: `extract = get`, `extend = sets` |
| `Env e a` comonad                  | Reader as a comonad (reads from fixed environment)  |
| `Traced m a` comonad               | Writer dual: produces values indexed by a monoid    |

The **Store comonad** `Store s a = (s -> a, s)` is the denotational basis of the `Lens` type: a lens
is precisely a co-Kleisli arrow of `Store`.

→ FP track: [20. Comonad](../docs/20-comonad.md) | [27. Lens / Optics](../docs/27-optics.md) (Store
comonad as lens) | [19. Monad](../docs/19-monad.md) (the dual)

## CTFP Reference

| Resource                 | Link                                                                                           |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Comonads     | [Part 3 Ch 7](https://bartoszmilewski.com/2017/01/02/comonads/)                                |
| CTFP LaTeX source Ch 3.7 | [`src/content/3.7/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/3.7) |

## See Also

- [Monad](./monad.md) — the categorical dual; reversing all arrows gives the comonad laws
- [Adjunction](./adjunction.md) — every adjunction gives both a monad and a comonad
- [F-Algebra](./f-algebra.md) — coalgebras (the dual of algebras) are the formal basis of
  anamorphisms; comonads arise as terminal coalgebras
