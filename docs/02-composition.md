# 2. Composition

Given two functions `f :: a ⟶ b` and `g :: b ⟶ c`, their **composition** `h = g∘f :: a ⟶ c` is a new
function that applies `f` first and then `g`.

![composition](../basics/composition.svg)

This is the central mechanism of functional programming: building complex behaviour by combining
small, pure functions.

## Examples

### C\#

```csharp
static Func<Ta, Tc> Compose<Ta, Tb, Tc>(
    Func<Tb, Tc> g,
    Func<Ta, Tb> f
) {
    return x => g(f(x));
}

// use:
var h = Compose(g, f);
```

### F\#

F# has the built-in `>>` (forward composition) and `<<` (backward composition) operators.

```fsharp
// >> applies left function first, then right
let h = f >> g

// Equivalent manual definition
let compose g f x = g (f x)
let h = compose g f
```

### Ruby

```ruby
# Patch Proc and add * operator
class Proc
    def *(f)
        lambda { |*args| self[f[*args]] }
    end
end

# use:
h = g * f
```

### C++

```c++
#include <functional>

template <typename A, typename B, typename C>
std::function<C(A)> compose(
    std::function<C(B)> g,
    std::function<B(A)> f
) {
    return [g, f](A x) { return g(f(x)); };
}

// use:
auto h = compose(g, f);
```

### JavaScript

```js
const compose = (g, f) => (x) => g(f(x));

// use:
const h = compose(g, f);
```

### Python

```py
def compose(g, f):
    return lambda x: g(f(x))

# use:
h = compose(g, f)
```

### Haskell

Composition is built in as the `.` operator.

```hs
h = g . f
```
