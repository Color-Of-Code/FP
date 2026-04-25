# 10. Semigroup & Monoid

**Semigroup** and **Monoid** capture the idea of **combining values** of the same type in an
associative way. They are among the simplest and most widely useful abstractions in FP.

![semigroup and monoid](diagrams/semigroup-monoid.svg)

## Semigroup

A **semigroup** is a type `a` with an associative binary operation:

```text
(<>) :: a → a → a          -- "append" or "combine"

-- Law: associativity
(x <> y) <> z = x <> (y <> z)
```

The law guarantees that order of grouping does not matter, only the order of elements. This makes
parallel reduction safe: split the work arbitrarily, combine the results.

## Monoid

A **monoid** extends a semigroup with an **identity element** `mempty`:

```text
mempty :: a

-- Laws:
mempty <> x = x            -- left identity
x <> mempty = x            -- right identity
```

`mempty` is a neutral value: combining it with anything leaves that thing unchanged.

## Common instances

| Type                                | `(<>)`                             | `mempty`  |
| ----------------------------------- | ---------------------------------- | --------- |
| `String`                            | concatenation                      | `""`      |
| `List<a>`                           | concatenation                      | `[]`      |
| `Sum Int`                           | `+`                                | `0`       |
| `Product Int`                       | `*`                                | `1`       |
| `Any Bool`                          | `\|\|`                             | `False`   |
| `All Bool`                          | `&&`                               | `True`    |
| `Maybe<a>` (where `a` is Semigroup) | `Just a <> Just b = Just (a <> b)` | `Nothing` |

The same underlying type can be a monoid in more than one way (e.g. `Int` under both `+` and `*`).
Newtypes like `Sum` and `Product` select the intended instance.

## Connection to Fold

`mconcat` collapses a list of monoidal values in one pass — it is exactly `fold` specialised to a
monoid:

```text
mconcat :: [a] → a
mconcat = foldr (<>) mempty
```

Any type that is a Monoid can be used directly as the accumulator of a [Fold](./13-fold.md).

## Motivation

Without a shared "combine" abstraction, every function that aggregates values must know the specific
type it is working with. Adding a new type means writing new aggregation code, even when the
combination logic is structurally identical.

```text
-- Without monoid: three separate concat functions, same structure each time
function concat_strings(xs): result = "";  for x in xs: result = result + x;  return result
function concat_lists(xs):   result = [];  for x in xs: result = result + x;  return result
function sum_ints(xs):       result = 0;   for x in xs: result = result + x;  return result
-- New type = new function, even though all three loops are identical.
```

```text
-- With monoid: one function works for any monoid
mconcat xs = foldr (<>) mempty xs

mconcat ["hello", " ", "world"]  -- "hello world"   (String monoid)
mconcat [[1,2], [3], [4,5]]      -- [1,2,3,4,5]     (List monoid)
mconcat (map Sum [1,2,3,4,5])    -- Sum 15           (Sum Int monoid)
-- New type becomes usable by passing a Monoid instance, not by rewriting code.
```

![semigroup monoid motivation](diagrams/semigroup-monoid-motivation.svg)

## Examples

### C\#

```csharp
// C# has no Semigroup/Monoid typeclass, but the pattern is expressible.

// String — built-in concatenation is the monoid operation
string hello = "Hello, " + "world";   // "Hello, world"
string empty = string.Empty;           // identity

// List — LINQ Concat
var combined = new[] { 1, 2 }.Concat(new[] { 3, 4 }).ToArray(); // [1,2,3,4]

// Generic mconcat for strings
string Mconcat(IEnumerable<string> xs) => xs.Aggregate(string.Empty, (a, b) => a + b);

Mconcat(["Hello", ", ", "world"]); // "Hello, world"

// Sum monoid
int sum = new[] { 1, 2, 3, 4, 5 }.Aggregate(0, (acc, x) => acc + x); // 15
```

### F\#

```fsharp
// F# has no Monoid typeclass, but the pattern is idiomatic via Seq.fold.

// String
"Hello, " + "world"             // "Hello, world"
List.fold (+) "" ["Hello"; ", "; "world"]   // "Hello, world"

// List
[1; 2] @ [3; 4]                  // [1; 2; 3; 4]
List.fold (@) [] [[1;2]; [3]; [4;5]]        // [1;2;3;4;5]

// Sum
List.fold (+) 0 [1; 2; 3; 4; 5]  // 15

// Product
List.fold (*) 1 [1; 2; 3; 4; 5]  // 120
```

### Ruby

```ruby
# Ruby has no Monoid typeclass; the pattern is idiomatic via inject/reduce.

# String
["Hello", ", ", "world"].inject("", :+)   # "Hello, world"

# Array
[[1, 2], [3], [4, 5]].inject([], :+)      # [1, 2, 3, 4, 5]

# Sum
[1, 2, 3, 4, 5].inject(0, :+)             # 15

# Product
[1, 2, 3, 4, 5].inject(1, :*)             # 120
```

### C++

```cpp
#include <numeric>
#include <string>
#include <vector>

// String monoid
std::vector<std::string> words = {"Hello", ", ", "world"};
std::string result = std::accumulate(words.begin(), words.end(), std::string{});
// "Hello, world"

// Sum monoid
std::vector<int> nums = {1, 2, 3, 4, 5};
int sum = std::accumulate(nums.begin(), nums.end(), 0);    // 15

// Product monoid
int product = std::accumulate(nums.begin(), nums.end(), 1,
                              std::multiplies<int>());     // 120

// List (vector) monoid
std::vector<int> a = {1, 2}, b = {3, 4};
a.insert(a.end(), b.begin(), b.end());   // [1, 2, 3, 4]
```

### JavaScript

```js
// String monoid
["Hello", ", ", "world"].reduce((acc, x) => acc + x, ""); // "Hello, world"

// Array monoid
[[1, 2], [3], [4, 5]].reduce((acc, x) => acc.concat(x), []); // [1,2,3,4,5]

// Sum monoid
[1, 2, 3, 4, 5].reduce((acc, x) => acc + x, 0); // 15

// Product monoid
[1, 2, 3, 4, 5].reduce((acc, x) => acc * x, 1); // 120

// Generic mconcat (requires explicit append + empty)
const mconcat = (append, empty) => (xs) => xs.reduce(append, empty);

const sumConcat = mconcat((a, b) => a + b, 0);
sumConcat([1, 2, 3, 4, 5]); // 15
```

### Python

```py
from functools import reduce

# String monoid
result = reduce(lambda a, b: a + b, ["Hello", ", ", "world"], "")  # "Hello, world"

# List monoid
combined = reduce(lambda a, b: a + b, [[1, 2], [3], [4, 5]], [])   # [1,2,3,4,5]

# Sum monoid
total = reduce(lambda a, b: a + b, [1, 2, 3, 4, 5], 0)  # 15

# Product monoid
import math
product = math.prod([1, 2, 3, 4, 5])  # 120

# Generic mconcat
def mconcat(append, empty, xs):
    return reduce(append, xs, empty)

mconcat(lambda a, b: a + b, 0, [1, 2, 3, 4, 5])  # 15
```

### Haskell

```hs
-- Haskell: Semigroup and Monoid are built-in typeclasses.

-- (<>) is the semigroup operation; mempty is the monoid identity
"Hello" <> ", " <> "world"          -- "Hello, world"
[1, 2] <> [3, 4]                    -- [1, 2, 3, 4]

-- mconcat collapses a list of monoidal values
mconcat ["Hello", ", ", "world"]    -- "Hello, world"
mconcat [[1, 2], [3], [4, 5]]       -- [1, 2, 3, 4, 5]

-- Newtype wrappers select different instances for the same type
import Data.Monoid (Sum(..), Product(..), Any(..), All(..))

getSum     (mconcat (map Sum     [1, 2, 3, 4, 5]))  -- 15
getProduct (mconcat (map Product [1, 2, 3, 4, 5]))  -- 120
getAny     (mconcat (map Any     [False, True, False])) -- True
getAll     (mconcat (map All     [True, True, True]))   -- True

-- Maybe lifts any Semigroup into a Monoid
Just "hello" <> Just " world"   -- Just "hello world"
Just "hello" <> Nothing         -- Just "hello"
Nothing      <> Just "world"    -- Just "world"
```

### Rust

```rust
// Rust: String and Vec implement + / extend; iterators provide sum/product.

// String monoid
let hello = "Hello, ".to_string() + "world"; // "Hello, world"
let empty = String::new();                    // identity

// Vec monoid via iterator chain
let combined: Vec<i32> = [1, 2].iter().chain([3, 4].iter()).copied().collect();
// [1, 2, 3, 4]

// Sum and Product monoids
let sum: i32     = [1, 2, 3, 4, 5].iter().sum();     // 15
let product: i32 = [1, 2, 3, 4, 5].iter().product(); // 120

// String mconcat via collect
let concat: String = ["Hello", ", ", "world"].into_iter().collect();
// "Hello, world"

// Custom Semigroup / Monoid traits
trait Semigroup { fn combine(self, other: Self) -> Self; }
trait Monoid: Semigroup { fn empty() -> Self; }

impl Semigroup for i32 { fn combine(self, other: i32) -> i32 { self + other } }
impl Monoid    for i32 { fn empty() -> i32 { 0 } }

fn mconcat<A: Monoid>(xs: Vec<A>) -> A {
    xs.into_iter().fold(A::empty(), Semigroup::combine)
}
mconcat(vec![1i32, 2, 3, 4, 5]); // 15
```

### Go

```go
import "strings"

// String monoid
result := strings.Join([]string{"Hello", ", ", "world"}, "") // "Hello, world"

// Slice monoid via append
combined := append([]int{1, 2}, []int{3, 4}...) // [1 2 3 4]

// Generic fold (Go 1.18+) serves as mconcat
func Fold[A any](xs []A, init A, f func(A, A) A) A {
	acc := init
	for _, x := range xs {
		acc = f(acc, x)
	}
	return acc
}

sum     := Fold([]int{1, 2, 3, 4, 5}, 0, func(a, b int) int { return a + b }) // 15
product := Fold([]int{1, 2, 3, 4, 5}, 1, func(a, b int) int { return a * b }) // 120
concat  := Fold([]string{"Hello", ", ", "world"}, "",
	func(a, b string) string { return a + b }) // "Hello, world"
```
