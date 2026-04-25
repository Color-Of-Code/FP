# 6. Monad

A **monad** is a functor extended with two operations that allow **sequencing of effectful
computations**.

`fmap` (from [Functor](./04-functor.md)) handles `f :: a ⟶ b`. But when `f :: a ⟶ Mb` (the function
itself produces a wrapped value), `fmap` yields `M(Mb)` — an unwanted nested wrapper. Monads solve
this.

![monad](../basics/monad.svg)

## Operations

- **`pure :: a ⟶ Ma`** — lift a plain value into the monad. Also called `return`.
- **`bind :: Ma ⟶ (a ⟶ Mb) ⟶ Mb`** — unwrap `a` from `Ma`, apply `f`, and flatten `M(Mb)` to `Mb`.
  Also called `flatMap` or `>>=`.

Chaining multiple binds produces a pipeline of effectful steps where each step can see the result of
the previous one.

## Common monads

Each monad below has its own detailed page with diagram and code examples.

| Monad          | Effect modelled                                | Detail                        |
| -------------- | ---------------------------------------------- | ----------------------------- |
| `Maybe<a>`     | optional value / failure without error message | [maybe.md](monads/maybe.md)   |
| `Either<e, a>` | failure with an error value                    | [either.md](monads/either.md) |
| `List<a>`      | non-determinism / multiple results             | [list.md](monads/list.md)     |
| `IO a`         | input/output side effects                      | [io.md](monads/io.md)         |
| `State s a`    | stateful computation                           | [state.md](monads/state.md)   |
| `Reader r a`   | read-only shared environment / config          | [reader.md](monads/reader.md) |
| `Writer w a`   | accumulated log / output alongside a result    | [writer.md](monads/writer.md) |

## Examples

### C\#

```csharp
// Maybe monad pattern (using nullable)
int? SafeDivide(int a, int b) => b == 0 ? null : a / b;

int? result = SafeDivide(10, 2)           // Just 5
    .SelectMany(x => SafeDivide(x, 0))   // Nothing (propagates)
    .SelectMany(x => SafeDivide(x, 1));  // never reached
```

### JavaScript

```js
// List monad — bind is flatMap
const result = [1, 2, 3].flatMap((x) => [x, -x]); // [1,-1, 2,-2, 3,-3]
```

### Python

```py
def safe_div(a, b):
    return None if b == 0 else a / b

def bind(ma, f):
    return None if ma is None else f(ma)

result = bind(bind(10, lambda x: safe_div(x, 2)), lambda x: safe_div(x, 0))  # None
```

### Haskell

All monads support `do`-notation as syntactic sugar for `>>=`.

```hs
safeDivide :: Int -> Int -> Maybe Int
safeDivide _ 0 = Nothing
safeDivide a b = Just (a `div` b)

result :: Maybe Int
result = do
    x <- safeDivide 10 2   -- Just 5
    y <- safeDivide x 0    -- Nothing (short-circuits)
    safeDivide y 1         -- never reached
```
