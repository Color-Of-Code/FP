# Functional Programming

A learning track through the core concepts of functional programming, each building on the previous.

## Learning track

| #   | Concept                                               | Description                                                                     |
| --- | ----------------------------------------------------- | ------------------------------------------------------------------------------- |
| 1   | [Function](docs/01-function.md)                       | The basic unit: pure vs impure, total vs partial, declaration and application   |
| 2   | [Immutability](docs/02-immutability.md)               | Values that never change; persistent data structures and structural sharing     |
| 3   | [Composition](docs/03-composition.md)                 | Combining functions into new functions — the central mechanism of FP            |
| 4   | [Currying & Partial Application](docs/04-currying.md) | Transforming multi-argument functions; functions as results                     |
| 5   | [Algebraic Data Types](docs/05-adt.md)                | Product types (AND), sum types (OR), pattern matching; the shape of FP data     |
| 6   | [Lazy Evaluation](docs/06-lazy-evaluation.md)         | Thunks, non-strict semantics, infinite structures, and eager vs lazy trade-offs |
| 7   | [Semigroup & Monoid](docs/07-semigroup-monoid.md)     | Associative combination of values; the algebra behind `fold` and `mconcat`      |
| 8   | [Functor](docs/08-functor.md)                         | Lifting a function to work inside a wrapped type with `fmap`                    |
| 9   | [Applicative](docs/09-applicative.md)                 | Applying wrapped functions to wrapped values; combining independent effects     |
| 10  | [Fold](docs/10-fold.md)                               | Reducing a collection to a value; `map`, `filter` and more as folds             |
| 11  | [Traversable](docs/11-traversable.md)                 | Effectful mapping that preserves shape; swapping container and effect           |
| 12  | [Monad](docs/12-monad.md)                             | Sequencing effectful computations; solving the `fmap` nesting problem           |
| 13  | [Monad Transformers](docs/13-transformer.md)          | Stacking monads to combine multiple effects in one computation                  |
| 14  | [Composing Effects](docs/14-effects.md)               | Monad Transformers, Free Monad, and Algebraic Effects compared                  |
| 15  | [Lens / Optics](docs/15-optics.md)                    | Composable, first-class access and update of nested immutable data              |
| 16  | [Recursion Schemes](docs/16-recursion-schemes.md)     | Generalised folds: cata, ana, hylo and the base functor pattern                 |
| 17  | [Observable Effects](docs/17-observable-effects.md)   | The effect spectrum from pure FP to physical hardware; side-channel attacks     |

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

> Combining multiple monads into one computation: [13. Monad Transformers](docs/13-transformer.md)

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

> Overview and composition rules: [15. Lens / Optics](docs/15-optics.md)
