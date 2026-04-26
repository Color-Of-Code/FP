# Representable Functors

A functor $F : \mathcal{C} \to \mathbf{Set}$ is **representable** if it is naturally isomorphic to a
hom-functor $\mathcal{C}(A, -)$ for some object $A$. The representing object $A$ encodes all the
"shape" of $F$: every element of $F(X)$ corresponds uniquely to a morphism $A \to X$. In programming
this means a container is representable if it can be indexed by some fixed key type.

## Definition

### Representable functor

A functor $F : \mathcal{C} \to \mathbf{Set}$ is **representable** if there exists an object
$A \in \mathcal{C}$ and a natural isomorphism:

$$\alpha : \mathcal{C}(A, -) \xrightarrow{\;\sim\;} F$$

The pair $(A, \alpha)$ is called a **representation** of $F$. By the Yoneda lemma, this is
equivalent to a **universal element** $u \in F(A)$ (the image of $\mathrm{id}_A$ under $\alpha_A$):

$$\alpha_X(f : A \to X) = F(f)(u)$$

### Tabulate / Index

Given a representation $(A, u)$, the natural isomorphism has two directions:

- **`tabulate`**: $(A \to X) \to F(X)$, given by $f \mapsto F(f)(u)$
- **`index`**: $F(X) \to (A \to X)$, the inverse (requires the full isomorphism)

For a container $F$ with key type $A$: **`index`** looks up an element by key; **`tabulate`** builds
the container from a total function on keys.

### Adjunction connection

A representable functor $\mathcal{C}(A, -)$ is the image of $A$ under the Yoneda embedding
$\mathbf{Y} : \mathcal{C}^{op} \to [\mathcal{C}, \mathbf{Set}]$. Representability is the question of
whether a given $F$ lies in the image of $\mathbf{Y}$.

## Laws

A representation is unique up to unique isomorphism (by Yoneda).

For the Haskell `Representable` typeclass:

```haskell
index (tabulate f) = f               -- tabulate then index = identity
tabulate (index xs) = xs             -- index then tabulate = identity
```

These are the two directions of the natural isomorphism, witnessed by `tabulate` and `index`.

## FP Analog

| CT concept                    | Haskell                                                          |
| ----------------------------- | ---------------------------------------------------------------- |
| Representing object $A$       | `type Rep f` — the key/index type                                |
| $\mathcal{C}(A, X) \cong F X$ | `(Rep f -> a) ≅ f a`                                             |
| `tabulate`                    | `tabulate :: (Rep f -> a) -> f a` — build from a lookup function |
| `index`                       | `index :: f a -> Rep f -> a` — extract by key                    |
| `Identity`                    | `Rep Identity = ()` — the trivial representable                  |
| `(->) r` (Reader)             | `Rep ((->) r) = r` — functions _are_ representable               |
| `Stream a`                    | `Rep Stream = Nat` — infinite stream indexed by position         |
| `Pair a = (a, a)`             | `Rep Pair = Bool` — a two-element container                      |
| Store comonad `Store s a`     | `s -> a` is the index-form; `Rep (Store s) = s`                  |
| Memoisation                   | `tabulate` memoises a function: build the full lookup table once |

Any `Representable` functor is automatically an `Applicative`, a `Monad` (the Reader monad!), and a
`Distributive` functor. The `distribute` operation (transposing containers) is only possible for
representable functors.

→ FP track: [13. Functor](../docs/13-functor.md) — representable functors are a special class |
[25. Profunctor](../docs/25-profunctor.md) — `Star f a b = a -> f b` is representable in `b` |
[20. Comonad](../docs/20-comonad.md) — Store comonad arises from the representable structure

## CTFP Reference

| Resource                           | Link                                                                                           |
| ---------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Representable Functors | [Part 2 Ch 4](https://bartoszmilewski.com/2015/07/29/representable-functors/)                  |
| CTFP LaTeX source Ch 2.4           | [`src/content/2.4/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/2.4) |

## See Also

- [Yoneda Lemma](./yoneda.md) — representability is exactly the question of lying in the image of
  Yoneda
- [Functor](./functor.md) — representable functors are functors with a universal element
- [Adjunction](./adjunction.md) — the universal element witnesses a unit of an adjunction
- [Comonad](./comonad.md) — every representable functor gives a Store comonad
