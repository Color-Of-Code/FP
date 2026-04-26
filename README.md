# Functional Programming

A learning track through the core concepts of functional programming, each building on the previous.

## Learning track

| #   | Concept                                                            | Description                                                                     |
| --- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| 1   | [Function](docs/01-function.md)                                    | The basic unit: pure vs impure, total vs partial, declaration and application   |
| 2   | [Immutability](docs/02-immutability.md)                            | Values that never change; persistent data structures and structural sharing     |
| 3   | [Equational Reasoning](docs/03-equational-reasoning.md)            | Referential transparency, substitution model, and laws as rewrite rules         |
| 4   | [Composition](docs/04-composition.md)                              | Combining functions into new functions — the central mechanism of FP            |
| 5   | [Higher-Order Functions](docs/05-higher-order-functions.md)        | Functions as values; map, filter, flip, closures, and point-free style          |
| 6   | [Currying & Partial Application](docs/06-currying.md)              | Transforming multi-argument functions; functions as results                     |
| 7   | [Algebraic Data Types](docs/07-adt.md)                             | Product types (AND), sum types (OR), pattern matching; the shape of FP data     |
| 8   | [Newtype / Wrapper Types](docs/08-newtype.md)                      | Type-safe wrappers with zero runtime cost; alternative instances; phantom types |
| 9   | [Type Classes](docs/09-type-classes.md)                            | Ad-hoc polymorphism: contracts, instances, laws, and dispatch by type           |
| 10  | [Lazy Evaluation](docs/10-lazy-evaluation.md)                      | Thunks, non-strict semantics, infinite structures, and eager vs lazy trade-offs |
| 11  | [Semigroup & Monoid](docs/11-semigroup-monoid.md)                  | Associative combination of values; the algebra behind `fold` and `mconcat`      |
| 12  | [Property-Based Testing](docs/12-property-based-testing.md)        | Laws as universal properties; QuickCheck / Hypothesis / fast-check; shrinking   |
| 13  | [Functor](docs/13-functor.md)                                      | Lifting a function to work inside a wrapped type with `fmap`                    |
| 14  | [Natural Transformations](docs/14-natural-transformations.md)      | `∀ a. F a → G a`; parametricity gives the naturality law for free               |
| 15  | [Applicative](docs/15-applicative.md)                              | Applying wrapped functions to wrapped values; combining independent effects     |
| 16  | [Fold](docs/16-fold.md)                                            | Reducing a collection to a value; `map`, `filter` and more as folds             |
| 17  | [Traversable](docs/17-traversable.md)                              | Effectful mapping that preserves shape; swapping container and effect           |
| 18  | [Continuation Passing Style](docs/18-cps.md)                       | CPS transform, callCC, and the bridge from direct style to the Cont monad       |
| 19  | [Monad](docs/19-monad.md)                                          | Sequencing effectful computations; solving the `fmap` nesting problem           |
| 20  | [Comonad](docs/20-comonad.md)                                      | Categorical dual of monad; `extract`/`extend`; streams, Store, Game of Life     |
| 21  | [Monad Transformers](docs/21-transformer.md)                       | Stacking monads to combine multiple effects in one computation                  |
| 22  | [Composing Effects](docs/22-effects.md)                            | Monad Transformers, Free Monad, and Algebraic Effects compared                  |
| 23  | [Tagless Final](docs/23-tagless-final.md)                          | Typeclass-polymorphic programs; capability control; Free Monad alternative      |
| 24  | [Concurrency and Parallelism](docs/24-concurrency.md)              | par/pseq, STM, async tasks, actor model — FP's lock-free concurrency story      |
| 25  | [Profunctor](docs/25-profunctor.md)                                | `dimap`; Strong→Lens, Choice→Prism; profunctor optics unify all optic kinds     |
| 26  | [Arrows](docs/26-arrows.md)                                        | `arr`/`>>>`/`first`; Kleisli; stream processors, FRP, parser combinators        |
| 27  | [Lens / Optics](docs/27-optics.md)                                 | Composable, first-class access and update of nested immutable data              |
| 28  | [Recursion Schemes](docs/28-recursion-schemes.md)                  | Generalised folds: cata, ana, hylo and the base functor pattern                 |
| 29  | [Codata and Coinduction](docs/29-codata.md)                        | Dual of ADTs; infinite structures (streams, comonads) as greatest fixpoints     |
| 30  | [Observable Effects](docs/30-observable-effects.md)                | The effect spectrum from pure FP to physical hardware; side-channel attacks     |
| 31  | [Computation Models and λ-Calculus](docs/31-computation-models.md) | λ-calculus, β-reduction, Church numerals, SKI, Y/Z combinators                  |

## Diagrams

The `docs/diagrams/` folder contains [D2](https://d2lang.com) source files for each concept diagram.
Monad-specific diagrams live in `docs/monads/diagrams/`.

## Monad catalogue

Each monad has a detailed page with type, bind semantics, motivation, diagram, and code examples in
all nine languages.

| Monad          | Effect modelled                               | Detail                             |
| -------------- | --------------------------------------------- | ---------------------------------- |
| `Maybe<a>`     | optional value / silent failure               | [maybe.md](docs/monads/maybe.md)   |
| `Either<e, a>` | failure with an error value                   | [either.md](docs/monads/either.md) |
| `List<a>`      | non-determinism / multiple results            | [list.md](docs/monads/list.md)     |
| `IO a`         | input/output side effects                     | [io.md](docs/monads/io.md)         |
| `State s a`    | stateful computation                          | [state.md](docs/monads/state.md)   |
| `Reader r a`   | read-only shared environment / config         | [reader.md](docs/monads/reader.md) |
| `Writer w a`   | accumulated log / output alongside a result   | [writer.md](docs/monads/writer.md) |
| `Parser a`     | consuming input; parsing as sequenced effects | [parser.md](docs/monads/parser.md) |
| `Cont r a`     | first-class continuations; `callCC`           | [cont.md](docs/monads/cont.md)     |
| `STM a`        | atomic transactions over shared mutable state | [stm.md](docs/monads/stm.md)       |
| `Prob a`       | discrete probability distributions            | [prob.md](docs/monads/prob.md)     |

> Combining multiple monads into one computation: [21. Monad Transformers](docs/21-transformer.md)

## Optics catalogue

Each optic has a dedicated page with type, laws, motivation, and code examples in all nine
languages.

| Optic                                           | Effect modelled                                   |
| ----------------------------------------------- | ------------------------------------------------- |
| [Iso](docs/optics/iso.md)                       | Lossless, reversible conversion between two types |
| [Lens](docs/optics/lens.md)                     | Focus on exactly one field of a product type      |
| [Prism](docs/optics/prism.md)                   | Focus on one constructor of a sum type            |
| [Traversal](docs/optics/traversal.md)           | Focus on zero or more elements; read and write    |
| [Fold](docs/optics/fold.md)                     | Focus on zero or more elements; read only         |
| [Getter / Setter](docs/optics/getter-setter.md) | Read-only (derived values) and write-only optics  |

> Overview and composition rules: [27. Lens / Optics](docs/27-optics.md)

## Category Theory track

A parallel math-first track explaining the categorical origins of the FP abstractions above. Each
page defines a CT concept precisely, maps it to its FP programming analog, and links to the
corresponding chapter in Bartosz Milewski's _Category Theory for Programmers_ (CTFP).

Pages contain **no per-language code** — for code examples follow the links into the FP track.

| CT Concept                                             | One-line summary                             | FP Analog                         |
| ------------------------------------------------------ | -------------------------------------------- | --------------------------------- |
| [Category](ct/category.md)                             | Objects, morphisms, composition, identity    | Types & functions; composition    |
| [Types & Functions](ct/types-functions.md)             | Hask as a category                           | All of functional programming     |
| [Product & Coproduct](ct/product-coproduct.md)         | Universal pairing and choice                 | Product types & sum types         |
| [Functor](ct/functor.md)                               | Structure-preserving map between categories  | `Functor` / `fmap`                |
| [Natural Transformation](ct/natural-transformation.md) | Morphism between functors                    | Polymorphic functions `F a → G a` |
| [Adjunction](ct/adjunction.md)                         | Universal relation between two functors      | Curry/uncurry; monad derivation   |
| [Monad](ct/monad.md)                                   | Monoid in the category of endofunctors       | `Monad` / `>>=` / `return`        |
| [F-Algebra](ct/f-algebra.md)                           | Algebras for an endofunctor; initial algebra | Recursion schemes: cata, ana      |

> Full catalog, reading order, and CTFP source index: [ct/README.md](ct/README.md)
