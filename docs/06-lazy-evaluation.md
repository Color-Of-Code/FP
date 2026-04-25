# 6. Lazy Evaluation

**Lazy evaluation** (also called _non-strict_ or _call-by-need_) delays computing a value until the
result is actually needed. The unevaluated expression is stored in a **thunk**; the first time its
value is demanded the thunk is forced, the result is cached, and subsequent accesses return the
cached value for free. The opposite strategy — computing every argument as soon as it is bound — is
called **eager** (or _strict_) evaluation. Understanding the difference is essential before
exploring [7. Semigroup & Monoid](./07-semigroup-monoid.md) and [10. Fold](./10-fold.md), where
evaluation order determines whether folds terminate.

![lazy evaluation](diagrams/lazy-evaluation.svg)

## Comparison

| Property                | Eager (strict)                                                 | Lazy (non-strict)                                 |
| ----------------------- | -------------------------------------------------------------- | ------------------------------------------------- |
| **When evaluated**      | At binding / function call                                     | On first use                                      |
| **Infinite structures** | Impossible (evaluation would never stop)                       | Possible — only demanded elements are computed    |
| **Short-circuiting**    | Must be built in (`&&`, `\|\|`)                                | Falls out naturally for any function              |
| **Memory**              | Predictable; values live for their binding scope               | Thunk pile-up can leak memory if forced too late  |
| **Performance model**   | Simple; easy to profile and reason about                       | Complex; space and time depend on demand patterns |
| **Default in**          | Most languages (C++, Java, Python, JS, Ruby, Go, Rust, C#, F#) | Haskell; opt-in streams elsewhere                 |

## Key patterns enabled by laziness

### Infinite sequences

```text
-- Define an infinite list of natural numbers
nats = 0 : 1 : 2 : 3 : …

-- Use only as many as needed; the rest is never computed
first10 = take 10 nats   -- [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
```

### Composable pipelines without intermediate allocation

```text
-- In an eager language, each step allocates a full intermediate list
result = take 5 (map (*2) (filter even [1..1000000]))
-- eager: filter → 500 000 elements; map → 500 000 elements; take → 5 elements

-- With lazy evaluation, the pipeline is pull-driven:
-- take demands 5; map demands 5 from filter; filter demands elements one at a time
-- Total work proportional to finding 5 even numbers, not 1 000 000
```

### Short-circuit evaluation as a library function

```text
-- In a strict language, (&&) must be a special form or macro to avoid evaluating both sides.
-- In a lazy language, it is an ordinary function:
and :: Bool -> Bool -> Bool
and True  y = y      -- only evaluated if first is True
and False _ = False  -- second argument never forced
```

## Motivation

```text
-- without laziness: must materialise all elements before filtering
--
-- prime candidates up to 1 000 000:
candidates = [2..1000000]          -- allocate 1M elements
primes     = filter isPrime candidates  -- allocate up to 1M elements
first5     = take 5 primes         -- discard all but 5
--
-- Space: O(N).  All three lists exist simultaneously.
```

```text
-- with laziness: elements generated on demand, one at a time
--
-- prime candidates — infinite; nothing allocated yet
candidates = [2..]
primes     = filter isPrime candidates  -- no allocation yet
first5     = take 5 primes  -- forces exactly enough elements to find 5 primes
--
-- Space: O(1) working set (current element + thunk chain).
-- Works even if the source is infinite.
```

![lazy evaluation motivation](diagrams/lazy-evaluation-motivation.svg)

## Examples

### C\#

```csharp
using System.Collections.Generic;
using System.Linq;

// C# is eager by default.
// IEnumerable<T> / LINQ provides lazy, pull-driven pipelines.

// Lazy infinite sequence via iterator
IEnumerable<int> NaturalNumbers()
{
    int n = 0;
    while (true) yield return n++;   // infinite — only produces values on demand
}

// Pipeline: nothing computed until ToList() forces it
var first10Evens = NaturalNumbers()
    .Where(n => n % 2 == 0)
    .Take(10)
    .ToList();   // [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

// Lazy<T> defers a single value computation until .Value is accessed
var expensive = new Lazy<int>(() => { /* heavy work */ return 42; });
int result = expensive.Value;   // computed here, once; cached afterwards
```

### F\#

```fsharp
// F# is eager by default.
// Seq<'a> (IEnumerable) provides lazy sequences; lazy keyword defers a value.

// Lazy infinite sequence
let naturals = Seq.initInfinite id   // 0, 1, 2, 3, …

// Pipeline: evaluated pull-by-pull
let first10Evens =
    naturals
    |> Seq.filter (fun n -> n % 2 = 0)
    |> Seq.take 10
    |> Seq.toList    // [0; 2; 4; 6; 8; 10; 12; 14; 16; 18]

// Deferred single value — computed once on first access
let expensive = lazy (printfn "computing!"; 42)
let v = expensive.Value   // "computing!" printed here
let v2 = expensive.Value  // no print — cached
```

### Ruby

```ruby
# Ruby is eager by default.
# Enumerator::Lazy provides a lazy pipeline.

# Infinite sequence
naturals = Enumerator.new { |y| n = 0; loop { y << n; n += 1 } }

# Lazy pipeline — nothing evaluated until .to_a forces it
first_10_evens = naturals
  .lazy
  .select { |n| n.even? }
  .first(10)
# => [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

# Ruby also has short-circuit && and || as built-in operators
puts true  || (1/0)   # => true  (right side never evaluated)
puts false && (1/0)   # => false (right side never evaluated)
```

### C++

```cpp
#include <ranges>
#include <vector>

// C++ is eager by default.
// C++20 ranges provide composable lazy views.

// Lazy infinite range (0, 1, 2, …)
auto naturals = std::views::iota(0);

// Lazy pipeline — materialized only by the range-for or to_vector
auto pipeline = naturals
    | std::views::filter([](int n) { return n % 2 == 0; })
    | std::views::take(10);

std::vector<int> result(pipeline.begin(), pipeline.end());
// {0, 2, 4, 6, 8, 10, 12, 14, 16, 18}

// Short-circuit: && and || are short-circuit operators in C++ (always)
bool ok = false && (1 / 0);   // right side never evaluated
```

### JavaScript

```js
// JavaScript is eager by default.
// Generators provide lazy, pull-driven sequences.

function* naturals() {
  let n = 0;
  while (true) yield n++; // infinite — only runs when pulled
}

function* lazyFilter(iterable, pred) {
  for (const x of iterable) if (pred(x)) yield x;
}

function* lazyTake(iterable, n) {
  let count = 0;
  for (const x of iterable) {
    if (count++ >= n) return;
    yield x;
  }
}

const first10Evens = [
  ...lazyTake(
    lazyFilter(naturals(), (n) => n % 2 === 0),
    10,
  ),
];
// [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
// see: itertools, lazy-collections npm packages
```

### Python

```python
from itertools import count, islice

# Python is eager by default.
# Generators provide lazy sequences; generator expressions are lazy pipelines.

# Lazy infinite sequence
def naturals():
    n = 0
    while True:
        yield n
        n += 1

# Lazy pipeline — no elements computed until islice forces them
evens = (n for n in naturals() if n % 2 == 0)
first_10_evens = list(islice(evens, 10))
# [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

# Python short-circuits 'and' / 'or' — right side not evaluated if not needed
result = False and (1 / 0)   # no ZeroDivisionError
```

### Haskell

```hs
-- Haskell is lazy by default — every value is a thunk until forced.

-- Infinite list of natural numbers — defined in terms of itself
nats :: [Int]
nats = [0..]   -- equivalent to 0 : 1 : 2 : 3 : …

-- Only 10 elements are ever computed
first10Evens :: [Int]
first10Evens = take 10 (filter even nats)
-- [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

-- Short-circuit falls out of ordinary function definitions
myAnd :: Bool -> Bool -> Bool
myAnd True  y = y      -- second argument evaluated only if first is True
myAnd False _ = False  -- '_' never touched

-- Strict evaluation can be forced with seq or BangPatterns when needed
sumStrict :: [Int] -> Int
sumStrict = foldl' (+) 0   -- foldl' (with apostrophe) forces accumulator eagerly
```

### Rust

```rust
// Rust is eager by default.
// Iterators are lazy; they do no work until consumed by collect(), for, etc.

// Lazy infinite iterator
let naturals = 0u64..;   // Range — lazy by nature

// Lazy pipeline
let first_10_evens: Vec<u64> = naturals
    .filter(|n| n % 2 == 0)
    .take(10)
    .collect();   // forces exactly 10 elements
// [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

// Defer a value with std::cell::OnceCell / once_cell::sync::Lazy
use std::sync::OnceLock;
static EXPENSIVE: OnceLock<u64> = OnceLock::new();
let v = EXPENSIVE.get_or_init(|| { /* heavy work */ 42 });
// computed once on first call; cached thereafter
```

### Go

```go
package main

// Go is eager by default; there is no built-in lazy evaluation.
// Lazy sequences are modelled with goroutines and channels, or closures.

// Lazy infinite sequence via channel + goroutine
func naturals() <-chan int {
    ch := make(chan int)
    go func() {
        for n := 0; ; n++ {
            ch <- n   // produces on demand; blocks until receiver pulls
        }
    }()
    return ch
}

func take(n int, ch <-chan int) []int {
    result := make([]int, n)
    for i := range result {
        result[i] = <-ch
    }
    return result
}

func main() {
    gen := naturals()
    // Consume only what is needed; generator blocks otherwise
    first5 := take(5, gen)
    _ = first5 // [0 1 2 3 4]
    // see: github.com/samber/lo for functional collection utilities
}
```
