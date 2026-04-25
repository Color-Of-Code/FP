# Product & Coproduct

**Products** and **coproducts** are the categorical way to build compound objects from simpler ones
— they define _pairing_ and _choice_ through universal properties rather than by construction.

## Definition

### Product

Given objects $A$ and $B$ in a category $\mathcal{C}$, a **product** is an object $A \times B$
together with projection morphisms

$$\pi_1 : A \times B \to A \qquad \pi_2 : A \times B \to B$$

satisfying the **universal property**: for any object $C$ and morphisms $f : C \to A$,
$g : C \to B$, there exists a **unique** morphism $\langle f, g \rangle : C \to A \times B$ such
that

$$\pi_1 \circ \langle f, g \rangle = f \qquad \pi_2 \circ \langle f, g \rangle = g$$

### Coproduct

The **coproduct** $A + B$ is the dual: injection morphisms

$$i_1 : A \to A + B \qquad i_2 : B \to A + B$$

and for any $C$ with $f : A \to C$, $g : B \to C$, a unique $[f, g] : A + B \to C$ with

$$[f, g] \circ i_1 = f \qquad [f, g] \circ i_2 = g$$

## Laws

Products and coproducts are unique **up to unique isomorphism** — a consequence of the universal
property. Any two products of $A$ and $B$ are isomorphic via a canonical isomorphism.

## FP Analog

| CT concept             | FP equivalent                                           |
| ---------------------- | ------------------------------------------------------- |
| Product $A \times B$   | Tuple / record / struct: `(a, b)`                       |
| Projection $\pi_1$     | `fst :: (a, b) -> a`                                    |
| Projection $\pi_2$     | `snd :: (a, b) -> b`                                    |
| $\langle f, g \rangle$ | `\c -> (f c, g c)`                                      |
| Coproduct $A + B$      | Sum type / union: `Either a b` / enum with two variants |
| Injection $i_1$        | `Left :: a -> Either a b`                               |
| Injection $i_2$        | `Right :: b -> Either a b`                              |
| $[f, g]$               | `either f g :: Either a b -> c` / pattern match         |

Algebraic data types (ADTs) are built from products (records with multiple fields) and coproducts
(enums with multiple constructors). Nested combinations yield the full richness of ADTs.

→ FP track: [7. Algebraic Data Types](../docs/07-adt.md)

## CTFP Reference

| Resource                                | Link                                                                                           |
| --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Products and Coproducts     | [Part 1 Ch 5](http://bartoszmilewski.com/2015/01/07/products-and-coproducts/)                  |
| CTFP blog — Simple Algebraic Data Types | [Part 1 Ch 6](http://bartoszmilewski.com/2015/01/13/simple-algebraic-data-types/)              |
| CTFP LaTeX source Ch 1.5                | [`src/content/1.5/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.5) |
| CTFP LaTeX source Ch 1.6                | [`src/content/1.6/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.6) |

## See Also

- [Category](./category.md) — what objects and morphisms are
- [Types & Functions](./types-functions.md) — how products/coproducts look in Hask
- [Functor](./functor.md) — products lead to bifunctors
