# Functional Programming

A learning track through the core concepts of functional programming, each building on the previous.

## Learning track

| #   | Concept                                               | Description                                                                   |
| --- | ----------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1   | [Function](docs/01-function.md)                       | The basic unit: pure vs impure, total vs partial, declaration and application |
| 2   | [Composition](docs/02-composition.md)                 | Combining functions into new functions — the central mechanism of FP          |
| 3   | [Currying & Partial Application](docs/03-currying.md) | Transforming multi-argument functions; functions as results                   |
| 4   | [Algebraic Data Types](docs/04-adt.md)                | Product types (AND), sum types (OR), pattern matching; the shape of FP data   |
| 5   | [Functor](docs/05-functor.md)                         | Lifting a function to work inside a wrapped type with `fmap`                  |
| 6   | [Applicative](docs/06-applicative.md)                 | Applying wrapped functions to wrapped values; combining independent effects   |
| 7   | [Fold](docs/07-fold.md)                               | Reducing a collection to a value; `map`, `filter` and more as folds           |
| 8   | [Traversable](docs/08-traversable.md)                 | Effectful mapping that preserves shape; swapping container and effect         |
| 9   | [Monad](docs/09-monad.md)                             | Sequencing effectful computations; solving the `fmap` nesting problem         |

## Diagrams

The `docs/diagrams/` folder contains [D2](https://d2lang.com) source files for each concept diagram.
Monad-specific diagrams live in `docs/monads/diagrams/`.
