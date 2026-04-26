# 14. Fold

**Fold** (also called _reduce_) is the fundamental higher-order function that collapses a collection
into a single value by repeatedly applying a combining function `f :: b ⟶ a ⟶ b` with an initial
accumulator.

`fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ List<a> ⟶ b`

![fold](diagrams/fold.svg)

`map`, `filter`, `sum`, `product`, `length` and many other operations can all be expressed as a
fold.

| Operation | Combining function                            | Init |
| --------- | --------------------------------------------- | ---- |
| sum       | `(acc, x) ⟶ acc + x`                          | `0`  |
| product   | `(acc, x) ⟶ acc × x`                          | `1`  |
| length    | `(acc, _) ⟶ acc + 1`                          | `0`  |
| map g     | `(acc, x) ⟶ acc ++ [g(x)]`                    | `[]` |
| filter p  | `(acc, x) ⟶ if p(x) then acc ++ [x] else acc` | `[]` |

## Motivation

Without fold, every aggregation over a list is a separate recursive function that duplicates the
same traversal skeleton. The only thing that differs between them is the combining step, yet each
must be written in full.

```text
-- Without fold: every aggregation is a hand-written recursive loop
function sum(xs):
    acc = 0
    for x in xs: acc = acc + x
    return acc

function product(xs):
    acc = 1
    for x in xs: acc = acc * x
    return acc

function length(xs):
    acc = 0
    for x in xs: acc = acc + 1
    return acc
-- Three functions; identical structure; three places to fix if the loop changes.
```

```text
-- With fold: the traversal is written once; only the combining step changes
sum     xs = fold (+) 0    xs
product xs = fold (*) 1    xs
length  xs = fold (\acc _ -> acc + 1) 0 xs
-- New aggregation = one line.  The loop is never rewritten.
```

![fold motivation](diagrams/fold-motivation.svg)

## Examples

### C\#

```csharp
// sum
new[] { 1, 2, 3 }.Aggregate(0, (acc, x) => acc + x); // 6
```

### F\#

```fsharp
// sum
List.fold (fun acc x -> acc + x) 0 [1; 2; 3]  // 6

// or with the built-in operator section
List.fold (+) 0 [1; 2; 3]  // 6
```

### Ruby

```ruby
# sum
[1, 2, 3].reduce(0) { |acc, x| acc + x } # 6
```

### C++

```c++
#include <numeric>
// sum
std::accumulate(v.begin(), v.end(), 0, [](int acc, int x){ return acc + x; }); // 6
```

### JavaScript

```js
// sum
[1, 2, 3].reduce((acc, x) => acc + x, 0); // 6
```

### Python

```py
from functools import reduce
# sum
reduce(lambda acc, x: acc + x, [1, 2, 3], 0)  # 6
```

### Haskell

```hs
-- sum
foldl (+) 0 [1, 2, 3]  -- 6
```

### Rust

```rust
// Iterator::fold is the built-in fold
let sum     = vec![1, 2, 3, 4, 5].iter().fold(0, |acc, x| acc + x); // 15
let product = vec![1, 2, 3, 4, 5].iter().fold(1, |acc, x| acc * x); // 120
let length  = vec![1, 2, 3].iter().fold(0, |acc, _| acc + 1);        // 3

// map expressed as fold
let doubled: Vec<i32> = vec![1, 2, 3]
    .iter()
    .fold(vec![], |mut acc, &x| { acc.push(x * 2); acc }); // [2, 4, 6]

// Idiomatic shortcuts
let sum2: i32 = vec![1, 2, 3, 4, 5].iter().sum();     // 15
let prod: i32 = vec![1, 2, 3, 4, 5].iter().product(); // 120
```

### Go

```go
// Go has no built-in fold; a generic version uses Go 1.18+ type parameters.
func Fold[A, B any](xs []A, init B, f func(B, A) B) B {
	acc := init
	for _, x := range xs {
		acc = f(acc, x)
	}
	return acc
}

sum    := Fold([]int{1, 2, 3, 4, 5}, 0, func(acc, x int) int { return acc + x }) // 15
product := Fold([]int{1, 2, 3, 4, 5}, 1, func(acc, x int) int { return acc * x }) // 120
length  := Fold([]int{1, 2, 3}, 0, func(acc int, _ int) int { return acc + 1 })   // 3

// map expressed as fold
func MapFold[A, B any](xs []A, f func(A) B) []B {
	return Fold(xs, []B{}, func(acc []B, x A) []B { return append(acc, f(x)) })
}
MapFold([]int{1, 2, 3}, func(x int) int { return x * 2 }) // [2, 4, 6]
```
