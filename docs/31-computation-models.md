# 31. Computation Models and λ-Calculus

> Mathematical background: [Lambda Calculus](../ct/lambda-calculus.md) — β/η-reduction,
> Church-Turing thesis, SKI, System F

Every programming language embodies a **model of computation** — a precise description of what it
means to compute. Functional programming is grounded in the **λ-calculus** (Church, 1936), not the
Turing machine. That choice has consequences: computation is substitution, not mutation; equational
reasoning is the default; and types are sets of proofs.

![computation models](diagrams/computation-models.svg)

## Three families of computation models

![computation models motivation](diagrams/computation-models-motivation.svg)

| Family         | Key models                                                           | FP connection                                               |
| -------------- | -------------------------------------------------------------------- | ----------------------------------------------------------- |
| **Sequential** | Turing machine, FSM, pushdown automaton, RAM                         | Imperative languages compile to a RAM model                 |
| **Functional** | λ-calculus, combinatory logic (SKI), μ-recursive functions, System F | Every FP language _is_ a typed λ-calculus variant           |
| **Concurrent** | Actor model, CSP/π-calculus, Petri nets, process algebras            | Effect systems and concurrency primitives sit _on top_ of λ |

All three families are **equally expressive** (Church-Turing thesis): anything computable in one can
be computed in any other. They differ in what is _primitive_: mutation vs substitution vs message
passing.

## β-reduction = computation = equational reasoning

In the λ-calculus, computation is a sequence of **β-reduction** steps:

$$(\lambda x.\, e_1)\; e_2 \;\longrightarrow_\beta\; e_1[e_2 / x]$$

"Evaluate a function call" _is_ "substitute the argument for the parameter". Because substitution
has no side effects, **every expression is equal to its fully-reduced form** — this is exactly what
[3. Equational Reasoning](./03-equational-reasoning.md) exploits.

**η-equivalence** says two functions are equal if they agree on all inputs:
$f \equiv_\eta g \iff \forall x,\; f\,x = g\,x$. This underlies the validity of point-free
definitions and is why **referential transparency** holds.

## Church numerals — numbers from pure functions

A natural number $n$ is encoded as a **higher-order function** that applies its argument $n$ times:

$$
\mathbf{0} = \lambda f.\lambda x.\, x \qquad
\mathbf{1} = \lambda f.\lambda x.\, f\,x \qquad
\mathbf{n} = \lambda f.\lambda x.\, \underbrace{f\,(f\,(\cdots f}_{n}\,x\cdots))
$$

Arithmetic follows from function composition:

$$
\mathrm{succ}\; n = \lambda f.\lambda x.\, f\,(n\,f\,x) \qquad
\mathrm{add}\; m\; n = \lambda f.\lambda x.\, m\,f\,(n\,f\,x) \qquad
\mathrm{mul}\; m\; n = \lambda f.\, m\,(n\,f)
$$

Church numerals show that **data can be encoded as behaviour** — a pattern that reappears in
[23. Tagless Final](./23-tagless-final.md) and [9. Type Classes](./09-type-classes.md).

## SKI combinators — point-free at the foundation

Every closed λ-term (no free variables) can be mechanically translated into three combinators:

$$I = \lambda x.\, x \qquad K = \lambda x.\lambda y.\, x \qquad S = \lambda x.\lambda y.\lambda z.\, x\,z\,(y\,z)$$

`SK` alone is Turing-complete; `I = SKK`. Combinatory logic is the formal basis of **point-free
style** — writing pipelines without naming intermediate arguments. In FP: `I` = `id`, `K` = `const`,
`S` ≈ the `Applicative` instance of functions (`(<*>) = \f g x -> f x (g x)`). See
[4. Composition](./04-composition.md).

## The Y and Z combinators — recursion from λ alone

The pure λ-calculus has no built-in `letrec`. Recursion emerges from the **fixed-point property**:

$$Y = \lambda f.\,(\lambda x.\, f\,(x\,x))\,(\lambda x.\, f\,(x\,x)) \qquad Y\,f =_\beta f\,(Y\,f)$$

`Y` works under **lazy evaluation**. For **strict** (call-by-value) languages, use the **Z
combinator** (η-expanded to delay evaluation):

$$Z = \lambda f.\,(\lambda x.\, f\,(\lambda v.\, x\,x\,v))\,(\lambda x.\, f\,(\lambda v.\, x\,x\,v))$$

`Z f n` evaluates `f` with a self-referencing thunk; each recursive call forces the thunk.

## Examples

### C\#

```csharp
// Church numerals as Func<Func<T,T>, Func<T,T>>
using System;

// Church numeral type alias: CN<T> = Func<Func<T,T>, Func<T,T>>
// zero f x = x
Func<Func<int,int>, Func<int,int>> zero = f => x => x;
Func<Func<int,int>, Func<int,int>> one  = f => x => f(x);
Func<Func<int,int>, Func<int,int>> two  = f => x => f(f(x));

// succ n f x = f (n f x)
Func<Func<Func<int,int>, Func<int,int>>,
     Func<Func<int,int>, Func<int,int>>> succ = n => f => x => f(n(f)(x));

// To int: apply (+1) starting from 0
int ToInt(Func<Func<int,int>, Func<int,int>> n) => n(x => x + 1)(0);
Console.WriteLine(ToInt(succ(succ(zero)))); // 2

// SKI
Func<T,T>                         I<T>(T x) => x;
Func<T, Func<U, T>>               K<T,U>(T x) => _ => x;
Func<T,U> S<T,U,V>(Func<T, Func<V,U>> x, Func<T,V> y, T z) => x(z)(y(z));

// Z combinator (strict fixed-point) for factorial
delegate Func<int,int> SelfApply(SelfApply self);
Func<int,int> Z(Func<Func<int,int>, Func<int,int>> f) {
    SelfApply loop = self => f(v => self(self)(v));
    return loop(loop);
}
var fact = Z(rec => n => n <= 1 ? 1 : n * rec(n - 1));
Console.WriteLine(fact(5)); // 120
```

### F\#

```fsharp
// Church numerals — curried functions
// type Church<'a> = ('a -> 'a) -> 'a -> 'a
let zero : ('a -> 'a) -> 'a -> 'a = fun _ x -> x
let one  : ('a -> 'a) -> 'a -> 'a = fun f x -> f x
let succ n = fun f x -> f (n f x)
let add  m n = fun f x -> m f (n f x)
let mul  m n = fun f -> m (n f)

let toInt n = n ((+) 1) 0
printfn "%d" (toInt (succ (succ (succ zero)))) // 3

// SKI as functions
let I x = x
let K x _ = x
let S x y z = x z (y z)

// Z combinator — strict fixed point
let Z f =
    let loop (self : 'a -> 'b) = f (fun v -> self self v)
    loop loop

let fact = Z (fun rec' n -> if n <= 1 then 1 else n * rec' (n - 1))
printfn "%d" (fact 5) // 120
```

### Ruby

```ruby
# Church numerals as lambdas
zero = ->(f) { ->(x) { x } }
one  = ->(f) { ->(x) { f.(x) } }
succ = ->(n) { ->(f) { ->(x) { f.(n.(f).(x)) } } }
add  = ->(m) { ->(n) { ->(f) { ->(x) { m.(f).(n.(f).(x)) } } } }
mul  = ->(m) { ->(n) { ->(f) { m.(n.(f)) } } }

to_i = ->(n) { n.(->(x) { x + 1 }).(0) }

two = succ.(succ.(zero))
puts to_i.(add.(two).(two))  # 4

# SKI
i = ->(x) { x }
k = ->(x) { ->(_) { x } }
s = ->(x) { ->(y) { ->(z) { x.(z).(y.(z)) } } }

# Z combinator (strict — works in Ruby since & is eager)
z = ->(f) {
  loop = ->(self) { f.(->(v) { self.(self).(v) }) }
  loop.(loop)
}

fact = z.(->(rec) { ->(n) { n <= 1 ? 1 : n * rec.(n - 1) } })
puts fact.(6)  # 720
```

### C++

```cpp
#include <functional>
#include <iostream>

// Church numerals — polymorphic via auto (C++20 generic lambdas)
// Church<int>: std::function<std::function<int(int)>(std::function<int(int)>)>
using F = std::function<int(int)>;
using Church = std::function<F(F)>;

Church zero = [](F) { return [](int x) { return x; }; };
Church one  = [](F f) { return [f](int x) { return f(x); }; };

auto succ(Church n) -> Church {
    return [n](F f) { return [n, f](int x) { return f(n(f)(x)); }; };
}
auto add(Church m, Church n) -> Church {
    return [m, n](F f) { return [m, n, f](int x) { return m(f)(n(f)(x)); }; };
}

int to_int(Church n) { return n([](int x) { return x + 1; })(0); }

// SKI
auto I = [](auto x) { return x; };
auto K = [](auto x) { return [x](auto) { return x; }; };
auto S = [](auto x) { return [x](auto y) { return [x,y](auto z) { return x(z)(y(z)); }; }; };

// Z combinator for factorial (strict)
using Rec = std::function<int(int)>;
using Step = std::function<Rec(Rec)>;

Rec Z(Step f) {
    std::function<Rec(std::function<Rec(std::function<Rec(Rec)>)>)> loop;
    loop = [&f](auto self) -> Rec {
        return f([self](int v) { return self(self)(v); });
    };
    return loop(loop);
}

int main() {
    auto three = succ(succ(succ(zero)));
    std::cout << to_int(add(three, three)) << "\n";  // 6

    Rec fact = Z([](Rec rec) -> Rec {
        return [rec](int n) { return n <= 1 ? 1 : n * rec(n - 1); };
    });
    std::cout << fact(5) << "\n";  // 120
}
```

### JavaScript

```javascript
// Church numerals
const zero = (f) => (x) => x;
const one = (f) => (x) => f(x);
const succ = (n) => (f) => (x) => f(n(f)(x));
const add = (m) => (n) => (f) => (x) => m(f)(n(f)(x));
const mul = (m) => (n) => (f) => m(n(f));

const toInt = (n) => n((x) => x + 1)(0);

const two = succ(succ(zero));
const four = add(two)(two);
console.log(toInt(four)); // 4
console.log(toInt(mul(two)(two))); // 4

// SKI combinators
const I = (x) => x;
const K = (x) => (_) => x;
const S = (x) => (y) => (z) => x(z)(y(z));

// verify I = S K K
const I2 = S(K)(K);
console.log(I2(42) === I(42)); // true

// Z combinator — strict (works in JS which is call-by-value)
const Z = (f) => ((x) => f((v) => x(x)(v)))((x) => f((v) => x(x)(v)));

const fact = Z((rec) => (n) => (n <= 1 ? 1 : n * rec(n - 1)));
console.log(fact(7)); // 5040
```

### Python

```python
from typing import TypeVar, Callable

A = TypeVar("A")

# Church numerals
zero = lambda f: lambda x: x
one  = lambda f: lambda x: f(x)
succ = lambda n: (lambda f: lambda x: f(n(f)(x)))
add  = lambda m: lambda n: (lambda f: lambda x: m(f)(n(f)(x)))
mul  = lambda m: lambda n: (lambda f: m(n(f)))

to_int = lambda n: n(lambda x: x + 1)(0)

two  = succ(succ(zero))
five = succ(succ(succ(two)))
print(to_int(add(two)(five)))  # 7
print(to_int(mul(two)(two)))   # 4

# SKI combinators
I = lambda x: x
K = lambda x: lambda _: x
S = lambda x: lambda y: lambda z: x(z)(y(z))

# Z combinator (strict fixed-point; works since Python is call-by-value)
Z = lambda f: (lambda x: f(lambda v: x(x)(v)))(lambda x: f(lambda v: x(x)(v)))

fact = Z(lambda rec: lambda n: 1 if n <= 1 else n * rec(n - 1))
print(fact(8))  # 40320
```

### Haskell

```haskell
-- Haskell is lazy, so the Y combinator works directly (no Z needed)
-- Church numerals require RankNTypes for the polymorphic type

{-# LANGUAGE RankNTypes #-}

-- Church numeral type: applying f exactly n times
newtype Church = Church { runChurch :: forall a. (a -> a) -> a -> a }

zero, one :: Church
zero = Church (\_ x -> x)
one  = Church (\f x -> f x)

succ' :: Church -> Church
succ' (Church n) = Church (\f x -> f (n f x))

add', mul' :: Church -> Church -> Church
add' (Church m) (Church n) = Church (\f x -> m f (n f x))
mul' (Church m) (Church n) = Church (\f   -> m (n f))

toInt :: Church -> Int
toInt (Church n) = n (+1) 0

-- SKI
i :: a -> a
i = id

k :: a -> b -> a
k = const

s :: (a -> b -> c) -> (a -> b) -> a -> c
s x y z = x z (y z)   -- same as (<*>) for ((->) a)

-- Y combinator — works in lazy Haskell
fix :: (a -> a) -> a
fix f = let x = f x in x   -- or: f (fix f)

fact :: Int -> Int
fact = fix (\rec n -> if n <= 1 then 1 else n * rec (n - 1))

-- In practice, use GHC's Data.Function.fix
-- import Data.Function (fix)
```

### Rust

```rust
// Rust is strict + has no GC, so Y combinator needs Box<dyn Fn>
// Church numerals require a trait object or concrete Church type

// Church numeral as a function that applies f n times to x
// We use a macro-free version with concrete i32 for simplicity
fn church_to_int<F>(n: impl Fn(F) -> F, zero_val: F) -> F
where F: Copy
{
    // Hmm — we need a different approach for arbitrary n
    // Instead, represent Church numerals as Fn(fn(i32)->i32) -> fn(i32)->i32
    todo!()  // see below
}

// Practical representation: Church<i32> = Box<dyn Fn(Box<dyn Fn(i32)->i32>) -> Box<dyn Fn(i32)->i32>>
type Step = Box<dyn Fn(i32) -> i32>;
type Church = Box<dyn Fn(Step) -> Step>;

fn zero() -> Church { Box::new(|_f| Box::new(|x| x)) }
fn succ(n: Church) -> Church {
    Box::new(move |f: Step| {
        let nf = n(Box::new(|x| f(x)));   // n f
        Box::new(move |x| f(nf(x)))        // f (n f x)  — simplified
    })
}
fn to_int(n: Church) -> i32 { n(Box::new(|x| x + 1))(0) }

// SKI as generic closures
fn i_comb<T>(x: T) -> T { x }
fn k_comb<T: Clone, U>(x: T) -> impl Fn(U) -> T { move |_| x.clone() }

// Z combinator (strict fixed-point) for factorial
// Uses Rc<dyn Fn> to allow the self-referential closure
use std::rc::Rc;
type RFn = Rc<dyn Fn(i32) -> i32>;

fn z_fact() -> RFn {
    fn z(f: Rc<dyn Fn(RFn) -> RFn>) -> RFn {
        let f2 = f.clone();
        Rc::new(move |v| f.clone()(Rc::new(move |w| z(f2.clone())(w)))(v))
    }
    z(Rc::new(|rec: RFn| {
        Rc::new(move |n: i32| if n <= 1 { 1 } else { n * rec(n - 1) })
    }))
}

fn main() {
    let fact = z_fact();
    println!("{}", fact(6)); // 720
}
```

### Go

```go
// Go: type-erased Church numerals using func(any) any
// (Go lacks the higher-kinded types needed for a typed Church numeral)

package main

import "fmt"

// Church numeral: a function that applies f n times to x
type Church func(f func(any) any) func(any) any

var zero Church = func(f func(any) any) func(any) any {
    return func(x any) any { return x }
}

func succ(n Church) Church {
    return func(f func(any) any) func(any) any {
        return func(x any) any { return f(n(f)(x)) }
    }
}

func add(m, n Church) Church {
    return func(f func(any) any) func(any) any {
        return func(x any) any { return m(f)(n(f)(x)) }
    }
}

func toInt(n Church) int {
    result := n(func(x any) any { return x.(int) + 1 })(0)
    return result.(int)
}

// SKI combinators
var I = func(x any) any { return x }
var K = func(x any) any { return func(_ any) any { return x } }
var S = func(x any) any {
    return func(y any) any {
        return func(z any) any {
            fx := x.(func(any) any)(z)
            yz := y.(func(any) any)(z)
            return fx.(func(any) any)(yz)
        }
    }
}

// Z combinator (strict fixed-point) for factorial
type SelfFn func(SelfFn) func(int) int

func Z(f func(func(int) int) func(int) int) func(int) int {
    loop := func(self SelfFn) func(int) int {
        return f(func(v int) int { return self(self)(v) })
    }
    return loop(loop)
}

func main() {
    two   := succ(succ(zero))
    three := succ(two)
    fmt.Println(toInt(add(two, three)))   // 5

    fact := Z(func(rec func(int) int) func(int) int {
        return func(n int) int {
            if n <= 1 { return 1 }
            return n * rec(n-1)
        }
    })
    fmt.Println(fact(5)) // 120
}
```

## Key points

| Concept              | Description                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------ |
| λ-calculus           | The computation model behind FP: syntax = variable, abstraction, application               |
| β-reduction          | $(\lambda x.\,e_1)\,e_2 \to e_1[e_2/x]$ — the fundamental computation step                 |
| η-equivalence        | $f \equiv \lambda x.\,f\,x$ — extensional equality; basis of point-free style              |
| Church-Turing thesis | λ-calculus, Turing machines, and μ-recursive functions compute the same class of functions |
| Church numerals      | Natural numbers as iteration count: $\mathbf{n} = \lambda f.\lambda x.\, f^n(x)$           |
| SKI combinators      | Turing-complete point-free basis; `I=id`, `K=const`, `S≈(<*>)`                             |
| Y combinator         | $Y\,f = f\,(Y\,f)$ — fixed point; recursion without naming; works under lazy evaluation    |
| Z combinator         | Strict variant of Y; needed in call-by-value languages                                     |
| System F             | Polymorphic λ-calculus; formal basis of `forall` types and parametricity                   |
| Normal order         | Outermost-first reduction = lazy evaluation                                                |
| Applicative order    | Innermost-first reduction = strict evaluation                                              |

## See also

- [ct/lambda-calculus.md](../ct/lambda-calculus.md) — formal definition, Church-Rosser theorem,
  System F, and the full SKI translation
- [3. Equational Reasoning](./03-equational-reasoning.md) — β-reduction makes every call site
  replaceable by its result
- [4. Composition](./04-composition.md) — `(.)` is the S combinator instantiated; point-free is SKI
- [5. Higher-Order Functions](./05-higher-order-functions.md) — higher-order functions _are_
  λ-abstractions
- [10. Lazy Evaluation](./10-lazy-evaluation.md) — call-by-need is normal-order reduction with
  memoisation
- [23. Tagless Final](./23-tagless-final.md) — Church encoding at the type-class level
- [29. Codata and Coinduction](./29-codata.md) — greatest fixed points; corecursion = coinductive
  analogue of Y
