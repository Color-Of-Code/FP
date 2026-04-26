# Yoneda Lemma

The **Yoneda lemma** is the most important theorem in category theory for programmers: it states
that a functor $F$ is completely determined by the natural transformations _from_ its representable
functor. In practice it says that **any data type can be replaced by a function that produces it**
without loss of information — a principle that underlies Church encodings, continuation-passing, and
profunctor optics.

## Definition

### Hom-functor

For any locally small category $\mathcal{C}$ and an object $A \in \mathcal{C}$, the **covariant
hom-functor** is:

$$\mathcal{C}(A, -) : \mathcal{C} \to \mathbf{Set}$$

$$\mathcal{C}(A, -)(X) = \mathrm{Hom}(A, X) \qquad \mathcal{C}(A, -)(f) = f \circ -$$

### Yoneda lemma (covariant)

For any locally small category $\mathcal{C}$, any object $A$, and any functor
$F : \mathcal{C} \to \mathbf{Set}$:

$$\mathrm{Nat}(\mathcal{C}(A, -),\; F) \;\cong\; F A$$

The set of natural transformations from $\mathcal{C}(A, -)$ to $F$ is in **natural bijection** with
the elements of $F A$.

The bijection is:

- **Forward** $\Phi$ : given $\alpha : \mathcal{C}(A, -) \Rightarrow F$, take
  $\Phi(\alpha) = \alpha_A(\mathrm{id}_A) \in F A$
- **Backward** $\Psi$ : given $x \in F A$, define $\Psi(x)_X : \mathcal{C}(A, X) \to F X$ by
  $f \mapsto F f(x)$

### Yoneda embedding

The **Yoneda embedding** is the fully faithful functor:

$$\mathbf{Y} : \mathcal{C}^{op} \to [\mathcal{C}, \mathbf{Set}] \qquad \mathbf{Y}(A) = \mathcal{C}(A, -)$$

It embeds $\mathcal{C}$ into its functor category; fully faithful means it preserves and reflects
all structure. In particular $\mathcal{C}(A, B) \cong \mathrm{Nat}(\mathbf{Y}B, \mathbf{Y}A)$ (the
contravariant form).

### Contravariant Yoneda

Dually, using $\mathcal{C}(-, A) : \mathcal{C}^{op} \to \mathbf{Set}$:

$$\mathrm{Nat}(\mathcal{C}(-, A),\; F) \cong F A$$

for any $F : \mathcal{C}^{op} \to \mathbf{Set}$ (presheaf).

## Laws

The bijection $\mathrm{Nat}(\mathcal{C}(A,-), F) \cong FA$ is:

1. **Natural in $A$**: as $A$ varies, the bijection is natural
2. **Natural in $F$**: as $F$ varies, the bijection is natural

These naturality conditions mean the Yoneda isomorphism is not just a bijection but a **natural
isomorphism of functors**, making it canonical.

## FP Analog

| CT concept                                            | Haskell                                                                            |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------- |
| $\mathrm{Nat}(\mathcal{C}(A,-), F) \cong FA$          | `(forall x. (a -> x) -> f x) ≅ f a`                                                |
| Hom-functor $\mathcal{C}(A,-)$                        | `(->) a` — the reader functor                                                      |
| Yoneda forward $\alpha \mapsto \alpha_A(\mathrm{id})$ | `phi alpha = alpha id`                                                             |
| Yoneda backward $x \mapsto \lambda f.\, Ff(x)$        | `psi x = \f -> fmap f x`                                                           |
| Church encoding                                       | `forall r. (a -> r) -> r` ≅ `a` (Yoneda with $F = \mathrm{Id}$)                    |
| CPS transform                                         | Any type can be Yoneda-encoded as a continuation                                   |
| Profunctor Yoneda                                     | `forall p. Profunctor p => p a b -> p s t` encodes optics (van Laarhoven form)     |
| `Lens s t a b`                                        | `forall f. Functor f => (a -> f b) -> s -> f t` — Yoneda over the Functor argument |

### Yoneda in practice

```haskell
-- The Yoneda type (covariant)
newtype Yoneda f a = Yoneda { runYoneda :: forall b. (a -> b) -> f b }

-- toYoneda: backward map (psi)
toYoneda :: Functor f => f a -> Yoneda f a
toYoneda fa = Yoneda (\f -> fmap f fa)

-- fromYoneda: forward map (phi)
fromYoneda :: Yoneda f a -> f a
fromYoneda (Yoneda y) = y id

-- Yoneda fuses fmaps without touching the container:
-- fmap g . fmap f = fmap (g . f)   — proven by Yoneda
```

### Van Laarhoven lenses as Yoneda

A `Lens s t a b` in the van Laarhoven encoding is a natural transformation between functors
parameterised by a `Functor f`:

$$\text{Lens}\; s\; t\; a\; b \;=\; \forall f.\; \text{Functor}\; f \Rightarrow (a \to f\, b) \to s \to f\, t$$

This is exactly the Yoneda lemma applied to the functor category of Haskell functors: the lens is
determined by what it does on every `Functor`, and Yoneda guarantees the whole family is determined
by one representative.

→ FP track: [25. Profunctor](../docs/25-profunctor.md) — profunctor optics use Yoneda over
`Profunctor` | [27. Lens / Optics](../docs/27-optics.md) — van Laarhoven encoding is Yoneda |
[14. Natural Transformations](../docs/14-natural-transformations.md) |
[31. Computation Models](../docs/31-computation-models.md) — Church numerals are Yoneda with
$F = \mathrm{Id}$

## CTFP Reference

| Resource                     | Link                                                                                           |
| ---------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — The Yoneda Lemma | [Part 2 Ch 5](https://bartoszmilewski.com/2015/09/01/the-yoneda-lemma/)                        |
| CTFP blog — Yoneda Embedding | [Part 2 Ch 6](https://bartoszmilewski.com/2015/10/28/yoneda-embedding/)                        |
| CTFP LaTeX source Ch 2.5     | [`src/content/2.5/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/2.5) |
| CTFP LaTeX source Ch 2.6     | [`src/content/2.6/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/2.6) |

## See Also

- [Functor](./functor.md) — $F$ and $\mathcal{C}(A,-)$ in the Yoneda lemma are functors
- [Natural Transformation](./natural-transformation.md) — the LHS
  $\mathrm{Nat}(\mathcal{C}(A,-), F)$ is a set of natural transformations
- [Adjunction](./adjunction.md) — the Yoneda embedding is the unit of the "free" adjunction;
  representable functors arise from adjunctions
- [Lambda Calculus](./lambda-calculus.md) — Church encodings are Yoneda with the identity functor
