# 5. Functor

A **functor** `F` is a type constructor that wraps values and supports **`fmap`**, which lifts a
plain function `f :: a ⟶ b` to work inside the wrapper: `fmap f :: Fa ⟶ Fb`.

![functor](diagrams/functor.svg)

This means you can reuse any ordinary function over any functor without rewriting it — the functor
handles the "opening and closing" of the wrapper.

## Laws

A lawful functor must satisfy:

- **Identity**: `fmap id = id`
- **Composition**: `fmap (g∘f) = fmap g ∘ fmap f`

## Common functors

| Functor       | What `fmap f` does                                              |
| ------------- | --------------------------------------------------------------- |
| `List<a>`     | applies `f` to every element                                    |
| `Maybe<a>`    | applies `f` if `Just a`, passes `Nothing` through               |
| `(a, String)` | applies `f` to the first element, leaves the `String` unchanged |

## Motivation

Without `fmap`, the same mapping logic must be re-implemented for every container type separately.
Adding a new container means writing yet another variant; there is no shared abstraction.

```text
-- Without functor: a separate mapping function per container
function map_list(f, xs):  return [f(x) for x in xs]
function map_maybe(f, mx): return if mx == null then null else f(mx)
function map_tree(f, t):   return Tree(f(t.value), map_tree(f, t.left), map_tree(f, t.right))
-- To double values, you call a different function depending on the container:
map_list(double, [1,2,3])   -- list
map_maybe(double, Just 5)   -- maybe
map_tree(double, myTree)    -- tree
-- New container = new map_* function.
```

```text
-- With functor: fmap works on any container that is a functor
fmap double [1, 2, 3]    -- List functor
fmap double (Just 5)     -- Maybe functor
fmap double myTree       -- Tree functor
-- One function name, any functor.  Laws guarantee consistent behaviour.
```

![functor motivation](diagrams/functor-motivation.svg)

## Examples

### C\#

```csharp
// List functor — Select is fmap
new[] { 1, 2, 3 }.Select(x => x * 2); // [2, 4, 6]

// Maybe functor — nullable
int? value = 5;
int? result = value.HasValue ? value * 2 : null; // 10
```

### F\#

```fsharp
// List functor — List.map is fmap
List.map ((*) 2) [1; 2; 3]  // [2; 4; 6]

// Option functor — Option.map is fmap
Option.map ((*) 2) (Some 5)  // Some 10
Option.map ((*) 2) None      // None
```

### Ruby

```ruby
# List functor
[1, 2, 3].map { |x| x * 2 }  # [2, 4, 6]
```

### C++

```cpp
// std::vector as a functor — std::transform is fmap
#include <algorithm>
#include <vector>

std::vector<int> xs = {1, 2, 3};
std::vector<int> result;
std::transform(xs.begin(), xs.end(), std::back_inserter(result),
               [](int x) { return x * 2; });
// result = {2, 4, 6}

// std::optional as a functor (C++23)
std::optional<int> value = 5;
auto mapped = value.transform([](int x) { return x * 2; });
// std::optional{10}
```

### JavaScript

```js
// List functor
[1, 2, 3].map((x) => x * 2); // [2, 4, 6]
```

### Python

```py
# List functor
list(map(lambda x: x * 2, [1, 2, 3]))  # [2, 4, 6]
```

### Haskell

```hs
-- List functor
fmap (*2) [1, 2, 3]        -- [2, 4, 6]

-- Maybe functor
fmap (*2) (Just 5)         -- Just 10
fmap (*2) Nothing          -- Nothing
```
