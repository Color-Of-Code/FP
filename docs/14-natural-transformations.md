# 14. Natural Transformations

> Mathematical background: [Natural Transformation](../ct/natural-transformation.md) — morphisms
> between functors

A **natural transformation** `α` between two functors `F` and `G` is a family of functions — one per
type `a` — that converts `F a` into `G a` **without inspecting or depending on `a`**.

```text
α :: ∀ a. F a → G a
```

![natural transformations](diagrams/natural-transformations.svg)

The defining constraint is the **naturality square**: for every function `f :: a → b`,

```text
α_b ∘ fmap_F f  =  fmap_G f ∘ α_a
```

_Transform first then map_ gives the same result as _map first then transform_.

## Why parametricity makes this free

In languages with parametric polymorphism (Haskell, Rust generics, Java/C# generics with no casts),
the naturality square is **automatically satisfied** by any function with the type `∀ a. F a → G a`.
The type alone forbids peeking at `a`, so the transformation cannot choose different behaviour based
on the element type — and that is exactly what the square demands.

This is the **free theorem** (Wadler 1989): parametricity gives you the naturality law for free.

![natural transformations motivation](diagrams/natural-transformations-motivation.svg)

## Common examples

| Transformation | Type                 | What it does                       |
| -------------- | -------------------- | ---------------------------------- |
| `safeHead`     | `[a] → Maybe a`      | List → Maybe; empty list → Nothing |
| `maybeToList`  | `Maybe a → [a]`      | Maybe → List; Nothing → `[]`       |
| `listToMaybe`  | `[a] → Maybe a`      | Same as `safeHead`                 |
| `return`       | `a → M a`            | Id → M; `pure` in every monad      |
| `forgetOption` | `Option<A> → Seq<A>` | Same pattern in OO generics        |

## Relation to other abstractions

- A **monad's** `return` and `join` are natural transformations (`Id → M` and `MM → M`).
- **Optics** (Lens, Prism) can be encoded as natural transformations between profunctors.
- **Free monads** are built from the idea that any natural transformation `F → G` lifts to a monad
  morphism `Free F → G`, making NTs the "change of interpreter" operation.

## Examples

### C\#

```csharp
// Natural transformation: IEnumerable<T> → T? (List → Maybe)
// Parametric — works for any T without inspecting T
static T? SafeFirst<T>(IEnumerable<T> xs) where T : struct =>
    xs.Any() ? xs.First() : null;

// Naturality holds: mapping before or after gives the same result
IEnumerable<int> nums = new[] { 1, 2, 3 };
Func<int, string> show = x => x.ToString();

// fmap(show) then SafeFirst  ==  SafeFirst then fmap(show)
string? a = SafeFirst(nums.Select(show));           // "1"
string? b = SafeFirst(nums).Select(show).FirstOrDefault(); // also "1"

// Maybe → List (always natural)
static IEnumerable<T> MaybeToList<T>(T? mx) where T : struct =>
    mx.HasValue ? new[] { mx.Value } : Array.Empty<T>();
```

### F\#

```fsharp
// Natural transformation: list → option (safeHead)
let safeHead (xs: 'a list) : 'a option =
    List.tryHead xs

// Naturality square (holds by parametricity)
let f = fun (x: int) -> x * 2

let lhs = safeHead (List.map f [1; 2; 3])       // Some 2
let rhs = Option.map f (safeHead [1; 2; 3])     // Some 2
// lhs = rhs always

// Option → list
let optionToList (mx: 'a option) : 'a list =
    match mx with
    | None   -> []
    | Some x -> [x]
```

### Ruby

```ruby
# Natural transformation: Array → first element (Array → Maybe modelled as nil-able)
def safe_first(xs)
  xs.first  # nil for empty — Ruby's built-in Maybe
end

# Naturality: map-then-transform == transform-then-map
f = ->(x) { x * 2 }
xs = [1, 2, 3]

lhs = safe_first(xs.map(&f))          # 2
rhs = xs.first&.then(&f)              # 2  (using Ruby's &. safe navigation)
# lhs == rhs

# Array → first (safe_head is a natural transformation for any element type)
```

### C++

```cpp
#include <optional>
#include <vector>
#include <algorithm>

// Natural transformation: vector<T> → optional<T>
template <typename T>
std::optional<T> safe_head(const std::vector<T>& xs) {
    if (xs.empty()) return std::nullopt;
    return xs.front();
}

// Naturality: map first then transform == transform then map
// (holds by the parametric type — T is never inspected)
std::vector<int> xs = {1, 2, 3};
auto f = [](int x) { return x * 2; };

// fmap f then safe_head
std::vector<int> mapped;
std::transform(xs.begin(), xs.end(), std::back_inserter(mapped), f);
auto lhs = safe_head(mapped);   // optional{2}

// safe_head then fmap f
auto rhs_opt = safe_head(xs);
auto rhs = rhs_opt ? std::optional<int>(f(*rhs_opt)) : std::nullopt;  // optional{2}

// lhs == rhs
```

### JavaScript

```javascript
// Natural transformation: Array → Maybe (modelled as null | value)
const safeHead = (xs) => xs.length > 0 ? xs[0] : null;

// Naturality square — holds for any f by parametricity
const f = (x) => x * 2;
const xs = [1, 2, 3];

const lhs = safeHead(xs.map(f));          // 2
const rhs = safeHead(xs) != null ? f(safeHead(xs)) : null; // 2
// lhs === rhs

// Array → Maybe (using a proper Option library like fp-ts)
import { fromNullable } from 'fp-ts/Option';
import { pipe }         from 'fp-ts/function';
import * as A           from 'fp-ts/Array';
import * as O           from 'fp-ts/Option';

const listToOption = <A>(xs: A[]): O.Option<A> =>
    xs.length > 0 ? O.some(xs[0]) : O.none;

// This is a natural transformation: ∀ A. Array<A> → Option<A>
```

### Python

```python
from __future__ import annotations
from typing import TypeVar, Generic, Sequence
from dataclasses import dataclass

A = TypeVar("A")

# Natural transformation: list → Optional (safeHead)
def safe_head(xs: list[A]) -> A | None:
    return xs[0] if xs else None

# Naturality square holds by parametricity
f = lambda x: x * 2
xs = [1, 2, 3]

lhs = safe_head([f(x) for x in xs])          # 2
rhs = f(safe_head(xs)) if safe_head(xs) is not None else None  # 2
assert lhs == rhs

# Optional → list
def option_to_list(mx: A | None) -> list[A]:
    return [mx] if mx is not None else []

# These two functions form a natural transformation pair
```

### Haskell

```haskell
-- Natural transformations are just parametrically polymorphic functions

-- safeHead :: [a] -> Maybe a  — a classic NT
safeHead :: [a] -> Maybe a
safeHead []    = Nothing
safeHead (x:_) = Just x

-- maybeToList :: Maybe a -> [a]  — the other direction
maybeToList :: Maybe a -> [a]
maybeToList Nothing  = []
maybeToList (Just x) = [x]

-- Naturality holds by parametricity (free theorem):
-- fmap f . safeHead  ==  safeHead . fmap f
-- No proof needed — the type guarantees it.

-- More examples of NTs (all by parametricity)
listToMaybe    :: [a] -> Maybe a     -- from Data.Maybe
maybeToList    :: Maybe a -> [a]
concat         :: [[a]] -> [a]       -- join for []
sequenceA      :: (Applicative f, Traversable t) => t (f a) -> f (t a)

-- monad's return is a NT from Identity to M
-- monad's join is a NT from M∘M to M
```

### Rust

```rust
// Natural transformation in Rust: generic function over a type parameter
// Rust's parametric generics give the free theorem automatically

fn safe_head<T>(xs: &[T]) -> Option<&T> {
    xs.first()
}

// Naturality: map-then-transform == transform-then-map (holds by types alone)
fn vec_to_option<T: Clone>(xs: Vec<T>) -> Option<T> {
    xs.into_iter().next()
}

fn option_to_vec<T>(ox: Option<T>) -> Vec<T> {
    ox.into_iter().collect()
}

// Example
let nums = vec![1i32, 2, 3];
let f = |x: &i32| x * 2;

// fmap f then safe_head
let lhs: Option<i32> = safe_head(&nums.iter().map(f).collect::<Vec<_>>()).copied();

// safe_head then fmap f
let rhs: Option<i32> = safe_head(&nums).map(f);

assert_eq!(lhs, rhs); // naturality square holds
```

### Go

```go
package main

// Natural transformation: []T → *T  (List → Maybe)
// Generic since Go 1.18
func SafeHead[T any](xs []T) *T {
    if len(xs) == 0 {
        return nil
    }
    return &xs[0]
}

// Option → list
func OptionToSlice[T any](x *T) []T {
    if x == nil {
        return nil
    }
    return []T{*x}
}

// Naturality square — holds by parametricity
// map-then-safeHead  ==  safeHead-then-map
func Map[A, B any](xs []A, f func(A) B) []B {
    out := make([]B, len(xs))
    for i, x := range xs {
        out[i] = f(x)
    }
    return out
}

func main() {
    xs := []int{1, 2, 3}
    f := func(x int) int { return x * 2 }

    lhs := SafeHead(Map(xs, f))    // pointer to 2
    tmp := SafeHead(xs)
    var rhs *int
    if tmp != nil {
        v := f(*tmp)
        rhs = &v
    }
    // *lhs == *rhs  (both 2)
    _ = lhs
    _ = rhs
}
```

## Key points

| Concept                | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| Natural transformation | `∀ a. F a → G a` — converts between functors without touching `a` |
| Naturality square      | `α ∘ fmap_F f = fmap_G f ∘ α` — commuting condition               |
| Free theorem           | Parametricity guarantees the naturality square in typed languages |
| Monad connection       | `return` and `join` are natural transformations                   |
| Optics connection      | Profunctor optics are encoded as NTs between profunctors          |

## See also

- [13. Functor](./13-functor.md) — the structures NTs transform between
- [19. Monad](./19-monad.md) — `return` and `join` are natural transformations
- [../ct/natural-transformation.md](../ct/natural-transformation.md) — categorical formulation and
  the full naturality square proof
