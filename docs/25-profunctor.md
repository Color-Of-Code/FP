# 25. Profunctor

> Mathematical background: [Natural Transformation](../ct/natural-transformation.md) — natural
> transformations between profunctors underpin the profunctor optics encoding |
> [Yoneda Lemma](../ct/yoneda.md) — `forall p. Profunctor p => p a b -> p s t` is Yoneda over the
> profunctor argument | [Ends & Coends](../ct/ends-coends.md) — profunctor composition is a coend;
> optics are ends over the `Profunctor` constraint
>
> **In plain terms:** A profunctor is a two-ended adapter: you can independently transform what goes
> _in_ (contramap the input) and what comes _out_ (map the output) — the mathematical backbone for
> composable lenses and optics.

A **profunctor** is a type constructor `P` with two type parameters `A` and `B` that is
**contravariant in `A`** and **covariant in `B`**. The single operation is `dimap`:

```text
dimap :: (A' → A)   -- pre-map (contravariant, "input" side)
       → (B  → B')  -- post-map (covariant, "output" side)
       → P A  B
       → P A' B'
```

The archetypal profunctor is the plain function type `A → B`: given `f :: A' → A` and `g :: B → B'`,
`dimap f g h = g ∘ h ∘ f`.

![profunctor motivation](25-profunctor/profunctor-motivation.svg)

## Laws

```text
dimap id id      = id                          -- identity
dimap (f . g) (h . i) = dimap g h . dimap f i -- composition
```

## Why profunctors matter for optics

The **Van Laarhoven** lens encoding uses `Functor` to unify `get` and `set`. The **profunctor
optics** encoding goes further: every optic kind — Lens, Prism, Traversal, Iso — is a **natural
transformation between profunctors**, distinguished only by a typeclass constraint on `P`:

```text
type Optic c s t a b = ∀ P. c P ⇒ P a b → P s t

type Iso        s t a b = Optic Profunctor  s t a b  -- no constraint
type Lens       s t a b = Optic Strong      s t a b  -- P has first/second
type Prism      s t a b = Optic Choice      s t a b  -- P has left'/right'
type Traversal  s t a b = Optic Traversing  s t a b
```

Composition is plain function composition `(.)` regardless of optic kind. Because the type
determines which `P`s are allowed, composing a `Lens` with a `Prism` automatically yields a
`Traversal` — the most general type that satisfies both constraints.

![profunctor](25-profunctor/profunctor.svg)

## Typeclass hierarchy

```text
Profunctor            dimap :: (a' → a) → (b → b') → P a b → P a' b'
  ├── Strong          first'  :: P a b → P (a, c) (b, c)     ← Lens
  ├── Choice          left'   :: P a b → P (Either a c) (Either b c)  ← Prism
  ├── Closed          closed  :: P a b → P (x → a) (x → b)  ← Grate
  └── Traversing      wander  :: (∀ f. Applicative f ⇒ (a → f b) → s → f t) → P a b → P s t
```

`Strong` and `Choice` correspond to products (pair) and coproducts (Either) respectively — directly
mirroring the ADT structure from [07. Algebraic Data Types](./07-adt.md).

## Examples

### C\#

```csharp
// Profunctor encoded as a generic interface in C#
// Full HKTs aren't available, so we simulate with two type parameters

public interface IProfunctor<TIn, TOut>
{
    IProfunctor<TIn2, TOut2> Dimap<TIn2, TOut2>(
        Func<TIn2, TIn>  preMap,
        Func<TOut, TOut2> postMap);
}

// The canonical profunctor: the function arrow A → B
public sealed class Fn<TIn, TOut> : IProfunctor<TIn, TOut>
{
    private readonly Func<TIn, TOut> _f;
    public Fn(Func<TIn, TOut> f) => _f = f;
    public TOut Apply(TIn x)     => _f(x);

    public IProfunctor<TIn2, TOut2> Dimap<TIn2, TOut2>(
        Func<TIn2, TIn>   preMap,
        Func<TOut, TOut2> postMap) =>
        new Fn<TIn2, TOut2>(x => postMap(_f(preMap(x))));
}

// Example: adapt an int→string formatter to work on double
Fn<int, string> intFmt   = new(n => $"#{n}");
var doubleFmt = intFmt.Dimap<double, string>(
    preMap:  d => (int)d,
    postMap: s => s);   // double → "#42" via (double→int→string)
Console.WriteLine(((Fn<double, string>)doubleFmt).Apply(42.9)); // "#42"
```

### F\#

```fsharp
// Profunctor in F# — modelled as a record (simulated typeclass)
type Profunctor<'p, 'a, 'b> = {
    Dimap: ('a2 -> 'a) -> ('b -> 'b2) -> 'p -> 'p
}

// The function arrow is the canonical profunctor
// dimap f g h = g << h << f
let fnProfunctor<'a, 'b, 'a2, 'b2>
    (f: 'a2 -> 'a) (g: 'b -> 'b2) (h: 'a -> 'b) : ('a2 -> 'b2) =
    g << h << f

// Lens via Strong (first' :: P a b → P (a * c) (b * c))
// In F# this is idiomatic as a plain function
let first' (f: 'a -> 'b) (x: 'a * 'c) : 'b * 'c =
    let (a, c) = x in (f a, c)

// dimap on pairs: adapt a lens to work on a larger structure
let dimapPair (pre: 's -> 'a) (post: 'b -> 't) (lens: 'a -> 'b) : 's -> 't =
    post << lens << pre
```

### Ruby

```ruby
# Profunctor in Ruby — module with dimap
module Profunctor
  # dimap: (A' → A), (B → B'), P A B → P A' B'
  def dimap(pre, post)
    raise NotImplementedError
  end
end

# Function arrow as a profunctor
class Fn
  include Profunctor

  def initialize(&f) = (@f = f)
  def call(x)        = @f.call(x)

  def dimap(pre, post)
    Fn.new { |x| post.call(@f.call(pre.call(x))) }
  end
end

# Example
int_fmt   = Fn.new { |n| "##{n}" }
dbl_fmt   = int_fmt.dimap(->(d) { d.to_i }, ->(s) { s })
puts dbl_fmt.call(42.9)  # "#42"
```

### C++

```cpp
// Profunctor as a template adapter in C++
// The function arrow (std::function) is the canonical instance

#include <functional>
#include <string>
#include <iostream>

// Wrap std::function as a profunctor-capable type
template <typename A, typename B>
struct Fn {
    std::function<B(A)> f;

    B operator()(A x) const { return f(x); }

    // dimap: (A2→A) → (B→B2) → Fn<A,B> → Fn<A2,B2>
    template <typename A2, typename B2>
    Fn<A2, B2> dimap(std::function<A(A2)> pre,
                     std::function<B2(B)> post) const {
        auto inner = f;
        return Fn<A2, B2>{ [inner, pre, post](A2 x) { return post(inner(pre(x))); } };
    }
};

// Strong (Lens): lift through a pair
template <typename A, typename B, typename C>
Fn<std::pair<A,C>, std::pair<B,C>> first_(Fn<A,B> p) {
    return { [p](std::pair<A,C> ac) -> std::pair<B,C> {
        return { p(ac.first), ac.second };
    }};
}

int main() {
    Fn<int, std::string> fmt{ [](int n) { return "#" + std::to_string(n); } };
    auto dbl_fmt = fmt.dimap<double, std::string>(
        [](double d) { return static_cast<int>(d); },
        [](std::string s) { return s; }
    );
    std::cout << dbl_fmt(42.9) << '\n';  // "#42"
}
```

### JavaScript

```javascript
// Profunctor in JavaScript — a class with dimap
class Fn {
  constructor(f) {
    this._f = f;
  }
  run(x) {
    return this._f(x);
  }

  // dimap :: (A' → A) → (B → B') → Fn<A,B> → Fn<A',B'>
  dimap(pre, post) {
    const inner = this._f;
    return new Fn((x) => post(inner(pre(x))));
  }

  // Strong: first :: Fn a b → Fn [a, c] [b, c]
  first() {
    const inner = this._f;
    return new Fn(([a, c]) => [inner(a), c]);
  }

  // Choice: left :: Fn a b → Fn (Either a c) (Either b c)
  // (Either represented as { tag: 'Left'|'Right', value })
  left() {
    const inner = this._f;
    return new Fn((e) =>
      e.tag === "Left" ? { tag: "Left", value: inner(e.value) } : { tag: "Right", value: e.value },
    );
  }
}

// Lens = Strong profunctor optic
const _fst = new Fn(([a]) => a); // focus on first element of pair
const lens = _fst.first(); // lift to pair-aware version
console.log(lens.run([42, "hello"])); // [42, 'hello'] — identity through first

// dimap example: adapt int-formatter to handle doubles
const intFmt = new Fn((n) => `#${n}`);
const dblFmt = intFmt.dimap(
  (d) => Math.trunc(d),
  (s) => s,
);
console.log(dblFmt.run(42.9)); // "#42"
```

### Python

```python
from __future__ import annotations
from typing import TypeVar, Generic, Callable

A  = TypeVar("A")
B  = TypeVar("B")
A2 = TypeVar("A2")
B2 = TypeVar("B2")
C  = TypeVar("C")

class Fn(Generic[A, B]):
    """The function arrow — the canonical profunctor."""

    def __init__(self, f: Callable[[A], B]) -> None:
        self._f = f

    def run(self, x: A) -> B:
        return self._f(x)

    def dimap(self, pre: Callable[[A2], A], post: Callable[[B], B2]) -> "Fn[A2, B2]":
        """dimap pre post h = post . h . pre"""
        inner = self._f
        return Fn(lambda x: post(inner(pre(x))))

    def first(self) -> "Fn[tuple[A, C], tuple[B, C]]":
        """Strong: lift to work on the first element of a pair."""
        inner = self._f
        return Fn(lambda ac: (inner(ac[0]), ac[1]))

    def left(self):
        """Choice: lift to work on the Left branch of Either."""
        inner = self._f
        def go(either):
            tag, val = either
            return ("Left", inner(val)) if tag == "Left" else ("Right", val)
        return Fn(go)

# Example: profunctor optic for the first element of a tuple
get_fst: Fn[tuple[int, str], int] = Fn(lambda t: t[0])
double_fst = get_fst.dimap(
    pre=lambda t: t,             # identity on input side
    post=lambda n: n * 2         # double the result
)
print(double_fst.run((21, "x")))  # 42

# Strong: adapt to operate on pairs
lift_to_pair = get_fst.first()
print(lift_to_pair.run((10, "y")))  # (10, "y") — passes second component through
```

### Haskell

```haskell
-- Profunctor lives in the `profunctors` package
-- cabal install profunctors

import Data.Profunctor        (Profunctor(..), Strong(..), Choice(..))
import Data.Profunctor.Types  (Star(..), Costar(..))

-- The function arrow (->) is the canonical profunctor instance:
-- dimap f g h = g . h . f

-- Profunctor optics encoding (from the `optics` / `lens` libraries)
--
-- type Optic  c s t a b = forall p. c p => p a b -> p s t
-- type Iso'     s   a   = forall p. Profunctor p   => p a a -> p s s
-- type Lens'    s   a   = forall p. Strong p       => p a a -> p s s
-- type Prism'   s   a   = forall p. Choice p       => p a a -> p s s

-- Build a Lens using Strong (first')
-- lens :: (s -> a) -> (s -> b -> t) -> Lens s t a b
myLens :: Strong p => (s -> a) -> (s -> b -> t) -> p a b -> p s t
myLens get set pab =
    dimap (\s -> (get s, s))
          (\(b, s) -> set s b)
          (first' pab)

-- Build a Prism using Choice (left')
-- prism :: (b -> t) -> (s -> Either t a) -> Prism s t a b
myPrism :: Choice p => (b -> t) -> (s -> Either t a) -> p a b -> p s t
myPrism build match pab =
    dimap match (either id id) (right' pab)

-- Composing optics: function composition gives the right type automatically
-- _1 . _head :: Lens' [(a, x)] a   (lens then lens = lens)
-- _head . _Just :: Traversal' [Maybe a] a  (lens + prism = traversal)

-- Star: wraps a → f b so a profunctor and applicative go together
-- Traversal uses Star (Applicative f => Star f a b)
```

### Rust

```rust
// Profunctor in Rust via a trait
// Full HKTs require workarounds; we use associated types and HRTB

trait Profunctor<A, B> {
    type Output<A2, B2>;

    fn dimap<A2, B2, Pre, Post>(self, pre: Pre, post: Post) -> Self::Output<A2, B2>
    where
        Pre:  Fn(A2) -> A,
        Post: Fn(B)  -> B2;
}

// Fn<A, B> wraps a function pointer / closure
struct MyFn<A, B>(Box<dyn Fn(A) -> B>);

impl<A: 'static, B: 'static> MyFn<A, B> {
    fn new(f: impl Fn(A) -> B + 'static) -> Self {
        MyFn(Box::new(f))
    }

    fn run(&self, x: A) -> B {
        (self.0)(x)
    }

    // dimap: (A2→A) → (B→B2) → MyFn<A,B> → MyFn<A2,B2>
    fn dimap<A2: 'static, B2: 'static>(
        self,
        pre:  impl Fn(A2) -> A  + 'static,
        post: impl Fn(B)  -> B2 + 'static,
    ) -> MyFn<A2, B2> {
        let inner = self.0;
        MyFn::new(move |x| post(inner(pre(x))))
    }

    // Strong: first — lift to work on the first element of a pair
    fn first<C: 'static>(self) -> MyFn<(A, C), (B, C)>
    where
        A: Clone,
    {
        let inner = self.0;
        MyFn::new(move |(a, c)| (inner(a), c))
    }
}

fn main() {
    let fmt = MyFn::new(|n: i32| format!("#{n}"));

    // dimap: adapt to accept f64
    let dbl_fmt = fmt.dimap(|d: f64| d as i32, |s: String| s);
    println!("{}", dbl_fmt.run(42.9)); // "#42"
}
```

### Go

```go
// Profunctor in Go via generics (Go 1.18+)
// Full HKTs are not available; we encode as concrete function-wrapper types

package main

import "fmt"

// Fn[A, B] wraps a function A → B — the canonical profunctor
type Fn[A, B any] struct {
    f func(A) B
}

func NewFn[A, B any](f func(A) B) Fn[A, B] { return Fn[A, B]{f} }
func (fn Fn[A, B]) Run(x A) B              { return fn.f(x) }

// dimap :: (A2→A) → (B→B2) → Fn[A,B] → Fn[A2,B2]
func Dimap[A, B, A2, B2 any](
    fn   Fn[A, B],
    pre  func(A2) A,
    post func(B) B2,
) Fn[A2, B2] {
    return NewFn(func(x A2) B2 { return post(fn.Run(pre(x))) })
}

// Strong: First[A,B,C] lifts Fn[A,B] to Fn[[A,C],[B,C]]
func First[A, B, C any](fn Fn[A, B]) Fn[[2]any, [2]any] {
    return NewFn(func(ac [2]any) [2]any {
        return [2]any{fn.Run(ac[0].(A)), ac[1]}
    })
}

func main() {
    intFmt := NewFn(func(n int) string { return fmt.Sprintf("#%d", n) })

    // dimap: adapt to accept float64
    dblFmt := Dimap(intFmt,
        func(d float64) int    { return int(d) },
        func(s string)  string { return s },
    )
    fmt.Println(dblFmt.Run(42.9)) // "#42"
}
```

## Key points

| Concept           | Description                                                                      |
| ----------------- | -------------------------------------------------------------------------------- |
| Profunctor        | `P A B` — contravariant in `A`, covariant in `B`; `dimap` maps both sides        |
| `dimap`           | Pre-compose on input, post-compose on output; generalises `fmap` and `contramap` |
| `Strong`          | Adds `first'`/`second'` — lifts through product types → gives **Lens**           |
| `Choice`          | Adds `left'`/`right'` — lifts through sum types → gives **Prism**                |
| `Traversing`      | Adds `wander` — lifts through traversals → gives **Traversal**                   |
| Optic unification | `type Optic c s t a b = ∀ P. c P ⇒ P a b → P s t` — one type, many optics        |
| Composition       | Plain function composition `(.)` for all optic kinds — no special combinators    |

## See also

- [13. Functor](./13-functor.md) — `fmap` is the covariant half; profunctor generalises to two sides
- [14. Natural Transformations](./14-natural-transformations.md) — profunctor optics _are_ natural
  transformations between profunctors
- [27. Lens / Optics](./27-optics.md) — Van Laarhoven and profunctor encodings side-by-side
