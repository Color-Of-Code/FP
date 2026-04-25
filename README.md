# Functional Programming

A learning track through the core concepts of functional programming, each building on the previous.

## Learning track

| #   | Concept                                               | Description                                                                   |
| --- | ----------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1   | [Function](docs/01-function.md)                       | The basic unit: pure vs impure, total vs partial, declaration and application |
| 2   | [Composition](docs/02-composition.md)                 | Combining functions into new functions — the central mechanism of FP          |
| 3   | [Currying & Partial Application](docs/03-currying.md) | Transforming multi-argument functions; functions as results                   |
| 4   | [Functor](docs/04-functor.md)                         | Lifting a function to work inside a wrapped type with `fmap`                  |
| 5   | [Applicative](docs/05-applicative.md)                 | Applying wrapped functions to wrapped values; combining independent effects   |
| 6   | [Fold](docs/06-fold.md)                               | Reducing a collection to a value; `map`, `filter` and more as folds           |
| 7   | [Traversable](docs/07-traversable.md)                 | Effectful mapping that preserves shape; swapping container and effect         |
| 8   | [Monad](docs/08-monad.md)                             | Sequencing effectful computations; solving the `fmap` nesting problem         |

## Diagrams

The `docs/diagrams/` folder contains [D2](https://d2lang.com) source files for each concept diagram.
Monad-specific diagrams live in `docs/monads/diagrams/`.
