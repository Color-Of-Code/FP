# Functional Programming

A learning track through the core concepts of functional programming, each building on the previous.

## Learning track

| #   | Concept                                               | Description                                                                   |
| --- | ----------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1   | [Function](docs/01-function.md)                       | The basic unit: pure vs impure, total vs partial, declaration and application |
| 2   | [Composition](docs/02-composition.md)                 | Combining functions into new functions — the central mechanism of FP          |
| 3   | [Currying & Partial Application](docs/03-currying.md) | Transforming multi-argument functions; functions as results                   |
| 4   | [Algebraic Data Types](docs/04-adt.md)                | Product types (AND), sum types (OR), pattern matching; the shape of FP data   |
| 5   | [Semigroup & Monoid](docs/05-semigroup-monoid.md)     | Associative combination of values; the algebra behind `fold` and `mconcat`    |
| 6   | [Functor](docs/06-functor.md)                         | Lifting a function to work inside a wrapped type with `fmap`                  |
| 7   | [Applicative](docs/07-applicative.md)                 | Applying wrapped functions to wrapped values; combining independent effects   |
| 8   | [Fold](docs/08-fold.md)                               | Reducing a collection to a value; `map`, `filter` and more as folds           |
| 9   | [Traversable](docs/09-traversable.md)                 | Effectful mapping that preserves shape; swapping container and effect         |
| 10  | [Monad](docs/10-monad.md)                             | Sequencing effectful computations; solving the `fmap` nesting problem         |
| 11  | [Monad Transformers](docs/11-transformer.md)          | Stacking monads to combine multiple effects in one computation                |
| 12  | [Composing Effects](docs/12-effects.md)               | Monad Transformers, Free Monad, and Algebraic Effects compared                |

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

> Combining multiple monads into one computation: [11. Monad Transformers](docs/11-transformer.md)
