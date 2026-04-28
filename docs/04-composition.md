# 4. Composition

> Mathematical background: [Category](../ct/category.md) — objects, morphisms, composition laws
>
> **In plain terms:** Composing functions is like piping shell commands — `ls | grep ".md" | wc -l`
> chains three tools end-to-end; function composition does the same thing in code.

Given two functions `f :: a ⟶ b` and `g :: b ⟶ c`, their **composition** `h = g∘f :: a ⟶ c` is a new
function that applies `f` first and then `g`.

![composition](04-composition/composition.svg)

This is the central mechanism of functional programming: building complex behaviour by combining
small, pure functions.

## Motivation

Without composition, combining functions requires writing new glue functions or nesting calls
manually. Each combination is a one-off; the pieces cannot be assembled generically.

```text
-- Without composition: each combination is written by hand
function validate_and_format(x):
    validated = validate(x)
    trimmed   = trim(validated)
    return format(trimmed)

function validate_and_trim(x):
    validated = validate(x)
    return trim(validated)
-- Every new combination requires a new function.
-- Nesting grows inward: format(trim(validate(x)))
```

```text
-- With composition: functions are assembled like building blocks
validate_and_format = format ∘ trim ∘ validate
validate_and_trim   = trim   ∘ validate

-- The same pieces, rearranged freely without extra code.
-- Pipelines read left-to-right with |> operator:
result = x |> validate |> trim |> format
```

![composition motivation](04-composition/composition-motivation.svg)

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

### Rust

```rust
// Rust has no built-in compose operator; write it as a generic function.
fn compose<A, B, C, F, G>(f: F, g: G) -> impl Fn(A) -> C
where
    F: Fn(A) -> B,
    G: Fn(B) -> C,
{
    move |x| g(f(x))
}

let add1 = |x: i32| x + 1;
let double = |x: i32| x * 2;

let h = compose(add1, double); // double(add1(x))
h(3); // 8

// Iterator chaining is idiomatic composition for data pipelines.
let result: Vec<i32> = vec![1, 2, 3]
    .into_iter()
    .map(|x| x + 1)
    .map(|x| x * 2)
    .collect(); // [4, 6, 8]
```

### Go

```go
// Go 1.18+: generic compose via type parameters.
func Compose[A, B, C any](f func(A) B, g func(B) C) func(A) C {
	return func(x A) C { return g(f(x)) }
}

add1 := func(x int) int { return x + 1 }
double := func(x int) int { return x * 2 }

h := Compose(add1, double)
h(3) // 8
```
