# Natural Transformation

A **natural transformation** is a morphism between functors: a family of morphisms — one for each
object in the source category — that commute with every morphism in that category.

## Definition

Let $F, G : \mathcal{C} \to \mathcal{D}$ be functors. A **natural transformation**
$\eta : F \Rightarrow G$ assigns to every object $A \in \mathcal{C}$ a morphism (the **component**
at $A$)

$$\eta_A : F A \to G A$$

subject to the **naturality condition**: for every morphism $f : A \to B$ in $\mathcal{C}$,

$$\eta_B \circ F f = G f \circ \eta_A$$

This condition says the two paths through the **naturality square** are equal:

$$
\begin{array}{ccc}
  FA & \xrightarrow{Ff} & FB \\
  {\scriptstyle\eta_A}\downarrow & & \downarrow{\scriptstyle\eta_B} \\
  GA & \xrightarrow{Gf} & GB
\end{array}
$$

## Composition of natural transformations

**Vertical composition** — stacking $\eta : F \Rightarrow G$ and $\mu : G \Rightarrow H$ gives
$\mu \circ \eta : F \Rightarrow H$ with components $(\mu \circ \eta)_A = \mu_A \circ \eta_A$.

**Horizontal composition** — for $\eta : F \Rightarrow G$ between functors
$\mathcal{C} \to \mathcal{D}$ and $\epsilon : H \Rightarrow K$ between functors
$\mathcal{D} \to \mathcal{E}$, the horizontal composite
$\epsilon * \eta : H \circ F \Rightarrow K \circ G$ captures how NTs interact under functor
composition.

## Laws

Natural transformations form a category (the **functor category** $[\mathcal{C}, \mathcal{D}]$):

- Identity NT: $\mathrm{id}_F$ with $(\mathrm{id}_F)_A = \mathrm{id}_{FA}$
- Vertical composition is associative

## FP Analog

In Hask, a natural transformation $\eta : F \Rightarrow G$ is a **polymorphic function**

```haskell
eta :: forall a. F a -> G a
```

The naturality condition is automatically satisfied by parametric polymorphism (**free theorems** —
Wadler 1989). Any function `forall a. F a -> G a` that cannot inspect the value at type `a` is
automatically natural.

Examples:

| NT                    | Type             | What it does                                   |
| --------------------- | ---------------- | ---------------------------------------------- |
| `safeHead`            | `[a] -> Maybe a` | List → Maybe; `[]` → Nothing, `(x:_)` → Just x |
| `maybeToList`         | `Maybe a -> [a]` | Maybe → List; Nothing → `[]`, Just x → `[x]`   |
| `reverse`             | `[a] -> [a]`     | List → List; reversal is natural               |
| `return` (monad unit) | `a -> M a`       | Id → M; lifts a pure value into the monad      |

→ FP track: [11. Functor](../docs/11-functor.md) (functor laws encode the square),
[15. Monad](../docs/15-monad.md) (unit and join are NTs)

## CTFP Reference

| Resource                            | Link                                                                                             |
| ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| CTFP blog — Natural Transformations | [Part 1 Ch 10](http://bartoszmilewski.com/2015/04/07/natural-transformations/)                   |
| CTFP LaTeX source Ch 1.10           | [`src/content/1.10/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.10) |

## See Also

- [Functor](./functor.md) — the structures being transformed
- [Monad](./monad.md) — `return` and `join` are natural transformations
- [Adjunction](./adjunction.md) — the unit and counit of an adjunction are NTs
