# 3. Equational Reasoning

> **In plain terms:** Equational reasoning is refactoring by substitution: because pure functions
> have no hidden state, you can replace any call `f x` with its definition — like simplifying an
> algebra expression — without changing the program's meaning.

**Equational reasoning** is the technique of proving properties of programs by treating code as
algebra: replace any expression with an equal expression, simplify, and arrive at the result. It
works because pure functions, introduced in [1. Function](./01-function.md), and
[2. Immutability](./02-immutability.md) together guarantee **referential transparency** — every
occurrence of a name can be replaced by its definition without changing the meaning of the program.

![equational reasoning](03-equational-reasoning/equational-reasoning.svg)

## Referential transparency

An expression is **referentially transparent** if it can be replaced by its value anywhere in the
program without changing the outcome.

```text
-- pure function: always the same result for the same input
double x = x + x

-- we can substitute the definition anywhere
double (double 3)
= double (3 + 3)   -- substitute inner call
= double 6
= 6 + 6            -- substitute outer call
= 12
```

Impure code breaks this immediately: if `double` also printed to the screen, substituting it would
change the number of print statements — so the substitution would not be safe.

## Laws as equalities

Every type class in this track comes with **laws** expressed as equalities. A law is a property that
must hold for _all_ values of the relevant types:

```text
-- Functor identity law
fmap id = id

-- Reading this as an equation: for any functor value f,
-- fmap id f  can always be replaced by  f
-- This means the compiler, the programmer, and any refactoring tool
-- can freely make that substitution.
```

Laws are not checked by the compiler (in most languages) but they are the reason that abstractions
like `Functor`, `Monoid`, and `Monad` are _predictable_ and _composable_.

## The substitution model

The substitution model is a simple evaluation strategy: reduce an expression to a value by
repeatedly replacing a sub-expression with its definition until no more substitutions are possible.

```text
-- Definitions
square x = x * x
sumOfSquares a b = square a + square b

-- Evaluate sumOfSquares 3 4 step by step:
sumOfSquares 3 4
= square 3 + square 4   -- unfold sumOfSquares
= (3 * 3) + square 4   -- unfold first square
= 9 + square 4         -- arithmetic
= 9 + (4 * 4)          -- unfold second square
= 9 + 16               -- arithmetic
= 25                   -- arithmetic
```

Every step is justified by equality. No hidden state, no execution order surprises.

## Why this matters

| Benefit                   | How equational reasoning enables it                                           |
| ------------------------- | ----------------------------------------------------------------------------- |
| **Safe refactoring**      | Replace any sub-expression with an equal one without risk                     |
| **Compiler optimisation** | The compiler can inline, fuse loops, or reorder operations                    |
| **Testing via laws**      | A law like `fmap id = id` can be checked by a property-based test generator   |
| **Parallelism**           | Expressions with no shared state can be evaluated in any order or in parallel |
| **Mental model**          | Understand a function by substituting its body — no need to simulate state    |

## Motivation

```text
-- without referential transparency: must simulate execution state

counter = 0

def tick():
    counter += 1   -- mutation: side effect not visible in signature
    return counter

x = tick() + tick()   -- x = 3 (not 2!): tick() returns different values
                      -- tick() cannot be substituted for its "value"
                      -- reasoning requires tracking counter across calls
```

```text
-- with referential transparency: substitute and simplify

tick count = (count + 1, count + 1)   -- returns new count; no mutation

let (c1, v1) = tick 0    -- c1 = 1, v1 = 1
let (c2, v2) = tick c1   -- c2 = 2, v2 = 2
x = v1 + v2              -- x = 3, derivable by substitution alone
                         -- no need to track any mutable variable
```

![equational reasoning motivation](03-equational-reasoning/equational-reasoning-motivation.svg)

## Examples

### C\#

```csharp
// Pure function: same input always gives same output
static int Square(int x) => x * x;
static int SumOfSquares(int a, int b) => Square(a) + Square(b);

// We can reason about SumOfSquares(3, 4) by substitution:
// SumOfSquares(3, 4)
// = Square(3) + Square(4)   // unfold definition
// = (3 * 3)   + (4 * 4)    // unfold Square
// = 9         + 16         // arithmetic
// = 25

// Property-based test expressing the identity law for fmap-equivalent (Select)
// using FsCheck (run via NuGet):
// Prop.ForAll<int[]>(xs => xs.Select(x => x).SequenceEqual(xs))
//   .QuickCheckThrowOnFailure();
```

### F\#

```fsharp
let square x = x * x
let sumOfSquares a b = square a + square b

// Equational proof (by substitution, expressed as comments):
// sumOfSquares 3 4
// = square 3 + square 4     // unfold
// = (3 * 3) + (4 * 4)       // unfold square
// = 9 + 16 = 25

// Property test with FsCheck
open FsCheck
let ``map id = id`` (xs: int list) = List.map id xs = xs
Check.Quick ``map id = id``
```

### Ruby

```ruby
# Pure function — no side effects
square       = ->(x)    { x * x }
sum_of_squares = ->(a, b) { square.(a) + square.(b) }

# Equational proof in comments:
# sum_of_squares.(3, 4)
# = square.(3) + square.(4)   # unfold definition
# = 9 + 16                    # arithmetic
# = 25

# Property-based test with rantly gem
# property { integer.map { |x| [x] }.flat_map { |x| x } == integer.map { |x| x } }
require 'minitest/autorun'
class EqReasonTest < Minitest::Test
  def test_map_id
    xs = [1, 2, 3, 4, 5]
    assert_equal xs, xs.map { |x| x }
  end
end
```

### C++

```cpp
#include <cassert>
#include <vector>
#include <algorithm>

// Pure function
constexpr int square(int x) { return x * x; }
constexpr int sumOfSquares(int a, int b) { return square(a) + square(b); }

// The compiler can constant-fold at compile time because the function is pure:
static_assert(sumOfSquares(3, 4) == 25);

// Property: map(id) == id  (std::transform with identity)
void testMapId() {
    std::vector<int> xs = {1, 2, 3, 4, 5};
    std::vector<int> ys(xs.size());
    std::transform(xs.begin(), xs.end(), ys.begin(), [](int x) { return x; });
    assert(xs == ys);
}
// see: rapidcheck for property-based testing in C++
```

### JavaScript

```js
// Pure functions — safe to substitute
const square = (x) => x * x;
const sumOfSquares = (a, b) => square(a) + square(b);

// Equational proof:
// sumOfSquares(3, 4)
// = square(3) + square(4)   // expand definition
// = 9 + 16 = 25

// Property-based test with fast-check
import fc from "fast-check";
fc.assert(
  fc.property(fc.array(fc.integer()), (xs) => {
    return xs.map((x) => x).every((v, i) => v === xs[i]); // map(id) = id
  }),
);
```

### Python

```python
from hypothesis import given, strategies as st

# Pure functions
def square(x: int) -> int:
    return x * x

def sum_of_squares(a: int, b: int) -> int:
    return square(a) + square(b)

# Equational proof:
# sum_of_squares(3, 4)
# = square(3) + square(4)   # unfold
# = 9 + 16 = 25

# Property test: map(id) = id
@given(st.lists(st.integers()))
def test_map_id(xs: list[int]) -> None:
    assert list(map(lambda x: x, xs)) == xs
```

### Haskell

```hs
-- Pure functions; all reasoning is equational in Haskell by default
square :: Int -> Int
square x = x * x

sumOfSquares :: Int -> Int -> Int
sumOfSquares a b = square a + square b

-- Equational proof that map id = id (Functor identity law):
--
--   map id []
--   = []                             -- definition of map on []
--
--   map id (x : xs)
--   = id x : map id xs               -- definition of map on (x:xs)
--   = x    : map id xs               -- id x = x
--   = x    : xs                      -- induction hypothesis: map id xs = xs
--   = x : xs                         -- QED
--
-- Property test with QuickCheck:
import Test.QuickCheck
prop_mapId :: [Int] -> Bool
prop_mapId xs = map id xs == xs
-- quickCheck prop_mapId  =>  +++ OK, passed 100 tests.
```

### Rust

```rust
// Pure functions; Rust's ownership ensures no hidden mutation
fn square(x: i32) -> i32 { x * x }
fn sum_of_squares(a: i32, b: i32) -> i32 { square(a) + square(b) }

// The compiler constant-folds pure const fn at compile time
const _: i32 = sum_of_squares(3, 4); // = 25, verified at compile time

// Property test with proptest crate
#[cfg(test)]
mod tests {
    use proptest::prelude::*;
    proptest! {
        #[test]
        fn map_id(xs: Vec<i32>) {
            let mapped: Vec<i32> = xs.iter().map(|&x| x).collect();
            prop_assert_eq!(mapped, xs);
        }
    }
}
```

### Go

```go
package main

// Pure functions — no side effects, same input always gives same output
func square(x int) int        { return x * x }
func sumOfSquares(a, b int) int { return square(a) + square(b) }

// Equational reasoning (as comments):
// sumOfSquares(3, 4)
// = square(3) + square(4)   // expand
// = 9 + 16 = 25

// Property-based test with rapid (github.com/nicholasgasior/rapid or gopter)
// using gopter:
// parameters := gopter.DefaultTestParameters()
// properties := gopter.NewProperties(parameters)
// properties.Property("map id = id", prop.ForAll(
//     func(xs []int) bool {
//         ys := make([]int, len(xs))
//         for i, x := range xs { ys[i] = x }
//         return reflect.DeepEqual(xs, ys)
//     }, gen.SliceOf(gen.Int()),
// ))
// properties.TestingRun(t)
// see: pgregory.net/rapid, github.com/leanovate/gopter
```
