# List Monad

The **List monad** models **non-deterministic** computations — ones that may produce zero, one, or
many results simultaneously.

![list monad](list/list.svg)

![bind type signature](list/list-ibd.svg)

![bind implementation](list/list-bind.svg)

![pure implementation](list/list-pure.svg)

## Type

```text
List<a>  -- zero or more possible values of type a
```

## How bind works

`bind` = `flatMap` / `concatMap`: apply `f` to **every element** of the list, then **flatten** all
the resulting lists into a single flat list.

```text
bind [a1, a2, a3] f  =  f(a1) ++ f(a2) ++ f(a3)
```

| Input           | bind behaviour                                     |
| --------------- | -------------------------------------------------- |
| non-empty list  | apply `f` to each element, concatenate all results |
| empty list `[]` | return `[]` immediately — no elements to process   |

## Intuition: all possible branches

Think of each element as a "possible world". `bind` explores all branches of each world in parallel
and collects every outcome.

## Key use cases

- Generating all combinations / permutations
- Search problems (explore all possibilities)
- Parsing alternatives (a token may match multiple rules)
- Backtracking algorithms

## Motivation

Without the List monad, exploring all combinations requires one nested loop per dimension. Adding
another dimension means adding another loop and another append — the nesting grows with the problem.

```text
-- Without List monad: nested loops, manual collection
function cartesian(xs, ys, zs):
    results = []
    for x in xs:
        for y in ys:
            for z in zs:
                results.append((x, y, z))
    return results
-- Every new dimension adds a loop and a nesting level.
```

```text
-- With List monad: bind (flatMap) composes dimensions uniformly
cartesian(xs, ys, zs) =
    xs >>= x ->
    ys >>= y ->
    zs >>= z ->
    pure (x, y, z)
-- Adding a dimension is one more >>= line, not a new loop level.
```

![list motivation](list/list-motivation.svg)

## Examples

### C\#

```csharp
// Expand each number to itself and its negative
var result = new[] { 1, 2, 3 }
    .SelectMany(x => new[] { x, -x });
// [1, -1, 2, -2, 3, -3]

// Cartesian product
var pairs = new[] { 1, 2 }
    .SelectMany(x => new[] { 'a', 'b' }.Select(y => (x, y)));
// [(1,'a'), (1,'b'), (2,'a'), (2,'b')]
```

### F\#

F# `List.collect` is `flatMap` / `concatMap`. Sequence expressions with `yield!` give a clean
alternative syntax.

```fsharp
// Expand each x to [x; -x]
let result = [1; 2; 3] |> List.collect (fun x -> [x; -x])
// [1; -1; 2; -2; 3; -3]

// Cartesian product using sequence expression
let pairs = [
    for x in [1; 2] do
    for y in ['a'; 'b'] do
    yield (x, y)
]
// [(1,'a'); (1,'b'); (2,'a'); (2,'b')]
```

### Ruby

```ruby
# Array#flat_map is bind for the List monad
result = [1, 2, 3].flat_map { |x| [x, -x] }
# [1, -1, 2, -2, 3, -3]

# Cartesian product
pairs = [1, 2].flat_map { |x| ['a', 'b'].map { |y| [x, y] } }
# [[1, "a"], [1, "b"], [2, "a"], [2, "b"]]
```

### C++

```cpp
#include <vector>

// bind for List monad: flat_map
auto flat_map = [](const std::vector<int>& xs, auto f) {
    std::vector<int> result;
    for (int x : xs)
        for (int y : f(x))
            result.push_back(y);
    return result;
};

auto result = flat_map({1, 2, 3}, [](int x) {
    return std::vector{x, -x};
});
// {1, -1, 2, -2, 3, -3}
```

### JavaScript

```js
// Expand each x to [x, x*10]
const result = [1, 2].flatMap((x) => [x, x * 10]); // [1, 10, 2, 20]

// Cartesian product
const pairs = [1, 2].flatMap((x) => ["a", "b"].map((y) => [x, y]));
// [[1,"a"],[1,"b"],[2,"a"],[2,"b"]]
```

### Python

```py
from itertools import chain

# Expand each x to [x, x*10]
result = list(chain.from_iterable([x, x * 10] for x in [1, 2]))
# [1, 10, 2, 20]

# Cartesian product via bind
bind = lambda xs, f: list(chain.from_iterable(f(x) for x in xs))
pairs = bind([1, 2], lambda x: bind(["a", "b"], lambda y: [(x, y)]))
# [(1,"a"), (1,"b"), (2,"a"), (2,"b")]
```

### Haskell

```hs
-- List monad bind is concatMap
result :: [Int]
result = [1, 2, 3] >>= \x -> [x, -x]
-- [1,-1, 2,-2, 3,-3]

-- Cartesian product using do-notation
pairs :: [(Int, Char)]
pairs = do
    x <- [1, 2]
    y <- ['a', 'b']
    return (x, y)
-- [(1,'a'),(1,'b'),(2,'a'),(2,'b')]
```

### Rust

```rust
// Vec + flat_map (= bind) for non-determinism.

// Expand each element to multiple values
let result: Vec<i32> = vec![1, 2, 3]
    .into_iter()
    .flat_map(|x| vec![x, -x])
    .collect(); // [1, -1, 2, -2, 3, -3]

// Cartesian product: bind [1,2] then bind [10,20]
let pairs: Vec<(i32, i32)> = vec![1, 2]
    .into_iter()
    .flat_map(|x| vec![10, 20].into_iter().map(move |y| (x, y)))
    .collect(); // [(1,10),(1,20),(2,10),(2,20)]

// Guard: keep only even numbers (filter = bind with conditional return)
let evens: Vec<i32> = vec![1, 2, 3, 4, 5, 6]
    .into_iter()
    .flat_map(|x| if x % 2 == 0 { vec![x] } else { vec![] })
    .collect(); // [2, 4, 6]
```

### Go

```go
// FlatMap (bind) for slices.
func FlatMap[A, B any](xs []A, f func(A) []B) []B {
	var result []B
	for _, x := range xs {
		result = append(result, f(x)...)
	}
	return result
}

// Expand each element
result := FlatMap([]int{1, 2, 3}, func(x int) []int { return []int{x, -x} })
// [1 -1 2 -2 3 -3]

// Cartesian product
pairs := FlatMap([]int{1, 2}, func(x int) [][2]int {
	return FlatMap([]int{10, 20}, func(y int) [][2]int { return [][2]int{{x, y}} })
})
// [[1 10] [1 20] [2 10] [2 20]]

// Guard / filter via FlatMap
evens := FlatMap([]int{1, 2, 3, 4, 5, 6}, func(x int) []int {
	if x%2 == 0 { return []int{x} }
	return nil
})
// [2 4 6]
```
