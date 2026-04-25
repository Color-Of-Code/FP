# Types & Functions

The category **Hask** treats Haskell types as objects and pure total functions as morphisms — making
all of functional programming an instance of category theory.

## Definition

**Hask** is (approximately) a category where:

- **Objects** are Haskell types: `Int`, `Bool`, `Maybe String`, `[a]`, …
- **Morphisms** $A \to B$ are pure Haskell functions of type `a -> b`
- **Composition** is `(.)`: `(g . f) x = g (f x)`
- **Identity** is `id :: a -> a`, `id x = x`

The qualifier _approximately_ is needed because Haskell's `undefined` and lazy evaluation introduce
degenerate bottom values that prevent Hask from being a true category. In practice this distinction
rarely matters, and the informal identification "types = objects, functions = morphisms" is the
productive way to think about it.

## Laws

The category laws hold up to Haskell's evaluation model:

$$\mathtt{(h \mathbin{.} g) \mathbin{.} f} \equiv \mathtt{h \mathbin{.} (g \mathbin{.} f)}$$

$$\mathtt{id \mathbin{.} f} \equiv \mathtt{f} \equiv \mathtt{f \mathbin{.} id}$$

## FP Analog

This page _is_ the FP analog — Hask is defined in terms of programming concepts. The value of the
mapping is that every theorem about categories applies to types and functions: functors, natural
transformations, monads, and adjunctions all become concrete and type-checkable.

The mapping also generalises: by changing what "types" and "functions" mean (e.g. to types-with-
resources in Rust, or to effect types) you get different categories with the same structural laws.

→ FP track: [1. Function](../docs/01-function.md) | [4. Composition](../docs/04-composition.md)

## Sets vs Types

| Property        | **Set**                        | **Hask**                       |
| --------------- | ------------------------------ | ------------------------------ |
| Objects         | Sets                           | Types                          |
| Morphisms       | Total functions                | Pure (possibly lazy) functions |
| Initial object  | ∅                              | `Void`                         |
| Terminal object | `{*}` (singleton)              | `()`                           |
| Products        | Cartesian product $A \times B$ | `(a, b)`                       |
| Coproducts      | Disjoint union $A \sqcup B$    | `Either a b`                   |

## CTFP Reference

| Resource                        | Link                                                                                           |
| ------------------------------- | ---------------------------------------------------------------------------------------------- |
| CTFP blog — Types and Functions | [Part 1 Ch 2](http://bartoszmilewski.com/2014/11/24/types-and-functions/)                      |
| CTFP LaTeX source Ch 1.2        | [`src/content/1.2/`](https://github.com/hmemcpy/milewski-ctfp-pdf/tree/master/src/content/1.2) |

## See Also

- [Category](./category.md) — the definition being instantiated here
- [Product & Coproduct](./product-coproduct.md) — initial/terminal objects and universal
  constructions
- [Functor](./functor.md) — maps that preserve the category structure
