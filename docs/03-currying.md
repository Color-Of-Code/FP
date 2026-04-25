# 3. Partial Application & Currying

Both techniques build on the idea that functions are first-class values and can be produced as
results.

![currying and partial application](diagrams/function2.svg)

## Partial application

**Partial application** fixes one (or more, but not all) arguments of a multi-argument function,
producing a new function of lower arity.

Given `f2 :: (a, b) ⟶ c`:

- Fix `a` → yields `f1a :: b ⟶ c`
- Fix `b` → yields `f1b :: a ⟶ c`

## Currying

**Currying** transforms a function of multiple arguments into a chain of single-argument functions.

`curry f2 :: a ⟶ (b ⟶ c)`

Applying it to `a` returns a function `b ⟶ c` — you can then apply that to `b` to get `c`. Every
curried function is partially applicable by simply not supplying all arguments.

## Examples

### C\#

```csharp
// Partial application via closure
Func<int, int, int> add = (a, b) => a + b;
Func<int, int> add5 = b => add(5, b);

add5(3); // 8
```

### F\#

All F# functions are curried by default, just like Haskell.

```fsharp
let add a b = a + b

let add5 = add 5   // partial application — no special syntax needed

add5 3  // 8
```

### Ruby

```ruby
add = ->(a, b) { a + b }
add5 = add.curry.(5)

add5.(3) # 8
```

### C++

```c++
#include <functional>

auto add = [](int a, int b) { return a + b; };
auto add5 = [&add](int b) { return add(5, b); };

add5(3); // 8
```

### JavaScript

```js
// Curry manually
const add = (a) => (b) => a + b;
const add5 = add(5);

add5(3); // 8
```

### Python

```py
from functools import partial

def add(a, b):
    return a + b

add5 = partial(add, 5)
add5(3)  # 8
```

### Haskell

All functions in Haskell are curried by default.

```hs
add :: Int -> Int -> Int
add a b = a + b

add5 :: Int -> Int
add5 = add 5

add5 3  -- 8
```
