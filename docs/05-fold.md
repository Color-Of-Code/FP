# 5. Fold

**Fold** (also called _reduce_) is the fundamental higher-order function that collapses a collection
into a single value by repeatedly applying a combining function `f :: b ⟶ a ⟶ b` with an initial
accumulator.

`fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ List<a> ⟶ b`

![fold](../basics/fold.svg)

`map`, `filter`, `sum`, `product`, `length` and many other operations can all be expressed as a
fold.

| Operation | Combining function                            | Init |
| --------- | --------------------------------------------- | ---- |
| sum       | `(acc, x) ⟶ acc + x`                          | `0`  |
| product   | `(acc, x) ⟶ acc × x`                          | `1`  |
| length    | `(acc, _) ⟶ acc + 1`                          | `0`  |
| map g     | `(acc, x) ⟶ acc ++ [g(x)]`                    | `[]` |
| filter p  | `(acc, x) ⟶ if p(x) then acc ++ [x] else acc` | `[]` |

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
