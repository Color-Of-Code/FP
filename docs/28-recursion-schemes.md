# 28. Recursion Schemes

> Mathematical background: [F-Algebra](../ct/f-algebra.md) — initial algebras, fixed points, and
> catamorphisms
>
> **In plain terms:** Recursion schemes are to recursive data structures what `fold` is to lists:
> you supply the per-node logic and the scheme handles all the traversal boilerplate.

**Recursion schemes** are higher-order functions that encapsulate common patterns of recursion over
recursive data structures. Rather than writing explicit recursive functions, you provide an
**algebra** (what to do at each node) and let the scheme handle the traversal.

This is the generalisation of [16. Fold](./16-fold.md) from lists to arbitrary recursive types, and
directly builds on [7. Algebraic Data Types](./07-adt.md) and [13. Functor](./13-functor.md).

![recursion schemes](28-recursion-schemes/recursion-schemes.svg)

## The key insight: separate shape from recursion

The trick is to define a **base functor** `F` — the _shape_ of one level of your data type, with a
type parameter `R` standing in for the recursive positions — and then recover the recursive type via
a **fixed-point** `Fix F`.

```text
-- Recursive type defined directly (shape and recursion entangled)
data Expr = Lit Int | Add Expr Expr | Mul Expr Expr

-- Step 1: extract the shape into a base functor (R = recursive position)
data ExprF R = LitF Int | AddF R R | MulF R R
-- ExprF is a plain Functor — fmap applies a function to every R inside it.

-- Step 2: recover the recursive type via Fix
type Expr = Fix ExprF           -- Expr = ExprF (ExprF (ExprF ...))
newtype Fix f = Fix { unFix :: f (Fix f) }
```

Once you have the base functor and its `Functor` instance, you get `cata`, `ana`, `hylo` and the
rest for free.

## Operations

| Scheme        | Name          | Direction           | Type                                        |
| ------------- | ------------- | ------------------- | ------------------------------------------- |
| `cata alg`    | Catamorphism  | tear-down (fold)    | `(F a -> a) -> Fix F -> a`                  |
| `ana coalg`   | Anamorphism   | build-up (unfold)   | `(a -> F a) -> a -> Fix F`                  |
| `hylo alg co` | Hylomorphism  | unfold then fold    | `(F b -> b) -> (a -> F a) -> a -> b`        |
| `para alg`    | Paramorphism  | fold + original     | `(F (Fix F, a) -> a) -> Fix F -> a`         |
| `apo coalg`   | Apomorphism   | unfold + early exit | `(a -> F (Either (Fix F) a)) -> a -> Fix F` |
| `histo alg`   | Histomorphism | fold + history      | `(F (Cofree F a) -> a) -> Fix F -> a`       |
| `futu coalg`  | Futumorphism  | unfold + look-ahead | `(a -> F (Free F a)) -> a -> Fix F`         |

`cata`, `ana`, and `hylo` cover the vast majority of practical use cases.

## How `cata` works

```text
cata :: Functor f => (f a -> a) -> Fix f -> a
cata alg = alg . fmap (cata alg) . unFix
--                 ^
--         recurse on all children first, then apply alg once at the current node
```

`alg` (the **algebra**) is a plain function `F a -> a` — it never recurses. `cata` provides all the
traversal. Adding a new transformation over a type means writing a new algebra, not a new recursive
function.

## Hylomorphism fusion

`hylo` is `cata` composed with `ana`, but it never materialises the intermediate `Fix F`:

```text
hylo alg coalg = cata alg . ana coalg   -- semantically
               = alg . fmap (hylo alg coalg) . coalg  -- fused (no Fix allocation)
```

Classic example: **factorial** — `ana` unfolds `n` into `[n, n-1, ..., 1]`, `cata` multiplies. The
list is never built.

## Laws

| Law                | Expression                                                |
| ------------------ | --------------------------------------------------------- |
| Reflection (cata)  | `cata Fix = id`                                           |
| Fusion (cata)      | `f . cata alg = cata alg'` when `f . alg = alg' . fmap f` |
| Reflection (ana)   | `ana unFix = id`                                          |
| Hylo decomposition | `hylo alg coalg = cata alg . ana coalg`                   |

## Motivation

Without recursion schemes, every function over a recursive type repeats the same traversal skeleton
— case-match on each constructor, recurse on children, combine results. The traversal and the
transformation are entangled.

```text
-- Without recursion schemes: three functions, three identical traversal skeletons
eval :: Expr -> Int
eval (Lit n)   = n
eval (Add l r) = eval l + eval r    -- traversal repeated here
eval (Mul l r) = eval l * eval r    -- and here

pp :: Expr -> String
pp (Lit n)   = show n
pp (Add l r) = "(" ++ pp l ++ " + " ++ pp r ++ ")"  -- traversal again
pp (Mul l r) = "(" ++ pp l ++ " * " ++ pp r ++ ")"

countNodes :: Expr -> Int
countNodes (Lit _)   = 1
countNodes (Add l r) = 1 + countNodes l + countNodes r  -- traversal again
countNodes (Mul l r) = 1 + countNodes l + countNodes r
-- Adding a new constructor (e.g. Neg) requires touching all three functions.
```

```text
-- With cata: one traversal function; algebras are plain data-mapping functions
evalAlg  :: ExprF Int    -> Int;    evalAlg  = ...  -- no recursion
ppAlg    :: ExprF String -> String; ppAlg    = ...  -- no recursion
countAlg :: ExprF Int    -> Int;    countAlg = ...  -- no recursion

eval       = cata evalAlg
pp         = cata ppAlg
countNodes = cata countAlg
-- Adding Neg: add one case to ExprF, update fmap; all algebras stay unchanged.
```

![recursion schemes motivation](28-recursion-schemes/recursion-schemes-motivation.svg)

## Examples

All examples define `ExprF` (the base functor), implement `cata`, and show two algebras (`eval` +
`pp`). The **factorial via hylomorphism** demonstrates `hylo` with `ListF`.

### C\#

```csharp
// Base functor: ExprF<R> where R replaces the recursive positions
abstract record ExprF<R>;
record LitF<R>(int N) : ExprF<R>;
record AddF<R>(R Left, R Right) : ExprF<R>;
record MulF<R>(R Left, R Right) : ExprF<R>;

// fmap: apply f to every R inside ExprF<A>, producing ExprF<B>
static ExprF<B> FMap<A, B>(ExprF<A> e, Func<A, B> f) => e switch {
    LitF<A>(var n)        => new LitF<B>(n),
    AddF<A>(var l, var r) => new AddF<B>(f(l), f(r)),
    MulF<A>(var l, var r) => new MulF<B>(f(l), f(r)),
    _                     => throw new InvalidOperationException()
};

// Expr = Fix(ExprF) — wrap ExprF<Expr> to break the infinite type
record Expr(ExprF<Expr> Shape);

// Smart constructors
static Expr Lit(int n)          => new(new LitF<Expr>(n));
static Expr Add(Expr l, Expr r) => new(new AddF<Expr>(l, r));
static Expr Mul(Expr l, Expr r) => new(new MulF<Expr>(l, r));

// cata: the only explicit recursion in the codebase
static T Cata<T>(Func<ExprF<T>, T> alg, Expr e) =>
    alg(FMap<Expr, T>(e.Shape, child => Cata(alg, child)));

// Algebras — plain functions, no recursion
static int EvalAlg(ExprF<int> e) => e switch {
    LitF<int>(var n)        => n,
    AddF<int>(var l, var r) => l + r,
    MulF<int>(var l, var r) => l * r,
    _                       => throw new InvalidOperationException()
};

static string PpAlg(ExprF<string> e) => e switch {
    LitF<string>(var n)        => n.ToString(),
    AddF<string>(var l, var r) => $"({l} + {r})",
    MulF<string>(var l, var r) => $"({l} * {r})",
    _                          => throw new InvalidOperationException()
};

var expr   = Mul(Add(Lit(2), Lit(3)), Lit(4));
var result = Cata<int>(EvalAlg, expr);     // 20
var pretty = Cata<string>(PpAlg, expr);   // "((2 + 3) * 4)"

// ---- Factorial via hylomorphism ----
abstract record ListF<R>;
record NilF<R> : ListF<R>;
record ConsF<R>(int N, R Tail) : ListF<R>;

static ListF<B> FMapList<A, B>(ListF<A> l, Func<A, B> f) => l switch {
    NilF<A>               => new NilF<B>(),
    ConsF<A>(var n, var t) => new ConsF<B>(n, f(t)),
    _                      => throw new InvalidOperationException()
};

static B Hylo<A, B>(Func<ListF<B>, B> alg, Func<A, ListF<A>> coalg, A seed) =>
    alg(FMapList<A, B>(coalg(seed), s => Hylo(alg, coalg, s)));

static ListF<int> RangeCoalg(int n) =>
    n == 0 ? new NilF<int>() : new ConsF<int>(n, n - 1);

static int ProductAlg(ListF<int> l) => l switch {
    NilF<int>                 => 1,
    ConsF<int>(var n, var acc) => n * acc,
    _                          => throw new InvalidOperationException()
};

int Factorial(int n) => Hylo<int, int>(ProductAlg, RangeCoalg, n);
// Factorial(5) == 120
```

### F\#

```fsharp
// Base functor: type parameter 'R stands in for the recursive positions
type ExprF<'R> =
    | LitF of int
    | AddF of 'R * 'R
    | MulF of 'R * 'R

// fmap for ExprF<'R>
let fmapExprF f = function
    | LitF n        -> LitF n
    | AddF(l, r)    -> AddF(f l, f r)
    | MulF(l, r)    -> MulF(f l, f r)

// Expr = Fix(ExprF) — wrapper to avoid infinite type
type Expr = Expr of ExprF<Expr>

// cata: the only explicit recursion
let rec cata alg (Expr shape) =
    alg (fmapExprF (cata alg) shape)

// Smart constructors
let lit n   = Expr(LitF n)
let add l r = Expr(AddF(l, r))
let mul l r = Expr(MulF(l, r))

// Algebras — plain functions, no recursion
let evalAlg = function
    | LitF n        -> n
    | AddF(l, r)    -> l + r
    | MulF(l, r)    -> l * r

let ppAlg = function
    | LitF n        -> string n
    | AddF(l, r)    -> sprintf "(%s + %s)" l r
    | MulF(l, r)    -> sprintf "(%s * %s)" l r

let eval = cata evalAlg
let pp   = cata ppAlg

let expr = mul (add (lit 2) (lit 3)) (lit 4)
// eval expr = 20
// pp   expr = "((2 + 3) * 4)"

// ---- Factorial via hylomorphism ----
type ListF<'A, 'R> = NilF | ConsF of 'A * 'R

let fmapListF f = function
    | NilF          -> NilF
    | ConsF(a, r)   -> ConsF(a, f r)

// hylo: unfold then fold; never materialises the intermediate structure
let rec hylo alg coalg seed =
    alg (fmapListF (hylo alg coalg) (coalg seed))

let rangeCoalg n  = if n = 0 then NilF else ConsF(n, n - 1)
let productAlg    = function NilF -> 1 | ConsF(n, acc) -> n * acc

let factorial n = hylo productAlg rangeCoalg n
// factorial 5 = 120

// With the `recursion-schemes` NuGet / `Myriad` for F#, cata/ana/hylo are
// generated automatically from the base functor definition.
```

### Ruby

```ruby
# Expr as tagged hashes — the base functor tag identifies the shape
def lit_f(n)    = { tag: :lit, n: n }
def add_f(l, r) = { tag: :add, l: l, r: r }
def mul_f(l, r) = { tag: :mul, l: l, r: r }

# fmap: apply f to every R (recursive child) inside ExprF
def fmap_expr(e, &f)
  case e[:tag]
  when :lit then lit_f(e[:n])
  when :add then add_f(f.call(e[:l]), f.call(e[:r]))
  when :mul then mul_f(f.call(e[:l]), f.call(e[:r]))
  end
end

# cata: the only explicit recursion
def cata(alg)
  go = ->(e) { alg.call(fmap_expr(e) { |child| go.call(child) }) }
  go
end

# Algebras — plain lambdas, no recursion
eval_alg = ->(e) {
  case e[:tag]
  when :lit then e[:n]
  when :add then e[:l] + e[:r]
  when :mul then e[:l] * e[:r]
  end
}

pp_alg = ->(e) {
  case e[:tag]
  when :lit then e[:n].to_s
  when :add then "(#{e[:l]} + #{e[:r]})"
  when :mul then "(#{e[:l]} * #{e[:r]})"
  end
}

expr   = mul_f(add_f(lit_f(2), lit_f(3)), lit_f(4))
result = cata(eval_alg).call(expr)  # 20
pretty = cata(pp_alg).call(expr)    # "((2 + 3) * 4)"

# ---- Factorial via hylomorphism ----
def nil_list         = { tag: :nil }
def cons_list(n, r)  = { tag: :cons, n: n, r: r }

def fmap_list(l, &f)
  case l[:tag]
  when :nil  then nil_list
  when :cons then cons_list(l[:n], f.call(l[:r]))
  end
end

def hylo(alg, coalg)
  go = ->(seed) { alg.call(fmap_list(coalg.call(seed)) { |s| go.call(s) }) }
  go
end

range_coalg = ->(n) { n.zero? ? nil_list : cons_list(n, n - 1) }
product_alg = ->(l) { l[:tag] == :nil ? 1 : l[:n] * l[:r] }
factorial   = hylo(product_alg, range_coalg)
# factorial.call(5) == 120
```

### C++

```cpp
#include <functional>
#include <memory>
#include <string>
#include <variant>

// Base functor: ExprF<R> with R standing in for recursive positions
template <typename R> struct LitF { int n; };
template <typename R> struct AddF { R l, r; };
template <typename R> struct MulF { R l, r; };
template <typename R>
using ExprF = std::variant<LitF<R>, AddF<R>, MulF<R>>;

// fmap: apply f to every R inside ExprF<A>, producing ExprF<B>
template <typename A, typename B>
ExprF<B> fmap_expr(const ExprF<A>& e, std::function<B(A)> f) {
    return std::visit([&](const auto& v) -> ExprF<B> {
        using T = std::decay_t<decltype(v)>;
        if constexpr      (std::is_same_v<T, LitF<A>>) return LitF<B>{v.n};
        else if constexpr (std::is_same_v<T, AddF<A>>) return AddF<B>{f(v.l), f(v.r)};
        else                                            return MulF<B>{f(v.l), f(v.r)};
    }, e);
}

// Expr = Fix(ExprF) — shared_ptr to handle the recursive type
struct Expr;
using ExprRef = std::shared_ptr<Expr>;
struct Expr { ExprF<ExprRef> shape; };

ExprRef lit(int n)                   { return std::make_shared<Expr>(Expr{LitF<ExprRef>{n}}); }
ExprRef add(ExprRef l, ExprRef r)    { return std::make_shared<Expr>(Expr{AddF<ExprRef>{l, r}}); }
ExprRef mul_e(ExprRef l, ExprRef r)  { return std::make_shared<Expr>(Expr{MulF<ExprRef>{l, r}}); }

// cata: the only explicit recursion
template <typename A>
A cata(std::function<A(ExprF<A>)> alg, ExprRef e) {
    return alg(fmap_expr<ExprRef, A>(e->shape, [&](ExprRef c) { return cata<A>(alg, c); }));
}

// Algebras — plain lambdas, no recursion
std::function<int(ExprF<int>)> eval_alg = [](const ExprF<int>& e) -> int {
    return std::visit([](const auto& v) -> int {
        using T = std::decay_t<decltype(v)>;
        if constexpr      (std::is_same_v<T, LitF<int>>) return v.n;
        else if constexpr (std::is_same_v<T, AddF<int>>) return v.l + v.r;
        else                                              return v.l * v.r;
    }, e);
};

std::function<std::string(ExprF<std::string>)> pp_alg =
    [](const ExprF<std::string>& e) -> std::string {
        return std::visit([](const auto& v) -> std::string {
            using T = std::decay_t<decltype(v)>;
            if constexpr      (std::is_same_v<T, LitF<std::string>>)
                return std::to_string(v.n);
            else if constexpr (std::is_same_v<T, AddF<std::string>>)
                return "(" + v.l + " + " + v.r + ")";
            else
                return "(" + v.l + " * " + v.r + ")";
        }, e);
    };

auto expr   = mul_e(add(lit(2), lit(3)), lit(4));
int    res  = cata<int>(eval_alg, expr);          // 20
auto   pp   = cata<std::string>(pp_alg, expr);    // "((2 + 3) * 4)"

// ---- Factorial via hylomorphism (specialised for ListF) ----
template <typename R>
struct ListF { bool is_nil; int n; R tail; };

template <typename A, typename B>
ListF<B> fmap_list(ListF<A> l, std::function<B(A)> f) {
    if (l.is_nil) return {true, 0, B{}};
    return {false, l.n, f(l.tail)};
}

template <typename A, typename B>
B hylo(std::function<B(ListF<B>)> alg, std::function<ListF<A>(A)> coalg, A seed) {
    return alg(fmap_list<A, B>(coalg(seed), [&](A s) { return hylo<A, B>(alg, coalg, s); }));
}

std::function<ListF<int>(int)>  range_coalg = [](int n) -> ListF<int> {
    return n == 0 ? ListF<int>{true, 0, 0} : ListF<int>{false, n, n - 1};
};
std::function<int(ListF<int>)>  product_alg = [](ListF<int> l) -> int {
    return l.is_nil ? 1 : l.n * l.tail;
};

int factorial(int n) { return hylo<int, int>(product_alg, range_coalg, n); }
// factorial(5) == 120
```

### JavaScript

```js
// Base functor: ExprF as tagged objects (R = the child position)
const litF = (n) => ({ tag: "Lit", n });
const addF = (l, r) => ({ tag: "Add", l, r });
const mulF = (l, r) => ({ tag: "Mul", l, r });

// fmap: apply f to every R in ExprF(R), producing ExprF(A)
const fmapExpr = (e, f) => {
  switch (e.tag) {
    case "Lit":
      return litF(e.n);
    case "Add":
      return addF(f(e.l), f(e.r));
    case "Mul":
      return mulF(f(e.l), f(e.r));
  }
};

// In JS, Expr = ExprF<Expr> directly (no wrapper needed — JS is untyped)
// cata: apply alg bottom-up; the only explicit recursion
const cata = (alg) => (e) => alg(fmapExpr(e, cata(alg)));

// Algebras — plain functions, no recursion
const evalAlg = (e) => (e.tag === "Lit" ? e.n : e.tag === "Add" ? e.l + e.r : e.l * e.r);

const ppAlg = (e) =>
  e.tag === "Lit" ? String(e.n) : e.tag === "Add" ? `(${e.l} + ${e.r})` : `(${e.l} * ${e.r})`;

const expr = mulF(addF(litF(2), litF(3)), litF(4));
const result = cata(evalAlg)(expr); // 20
const pretty = cata(ppAlg)(expr); // "((2 + 3) * 4)"

// ---- Factorial via hylomorphism ----
const nilF = { tag: "Nil" };
const consF = (n, r) => ({ tag: "Cons", n, r });
const fmapList = (l, f) => (l.tag === "Nil" ? nilF : consF(l.n, f(l.r)));

const hylo = (alg, coalg) => (seed) => alg(fmapList(coalg(seed), hylo(alg, coalg)));

const rangeCoalg = (n) => (n === 0 ? nilF : consF(n, n - 1));
const productAlg = (l) => (l.tag === "Nil" ? 1 : l.n * l.r);
const factorial = hylo(productAlg, rangeCoalg);
// factorial(5) === 120
```

### Python

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

R = TypeVar("R")

# Base functor: each case has R standing in for the recursive position
@dataclass
class LitF:
    n: int

@dataclass
class AddF(Generic[R]):
    l: R
    r: R

@dataclass
class MulF(Generic[R]):
    l: R
    r: R

# fmap: apply f to every R inside ExprF(R)
def fmap_expr(e, f):
    match e:
        case LitF(n=n):      return LitF(n=n)
        case AddF(l=l, r=r): return AddF(l=f(l), r=f(r))
        case MulF(l=l, r=r): return MulF(l=f(l), r=f(r))

# In Python ExprF is also Expr (duck-typed); cata is the only explicit recursion
def cata(alg):
    def go(e):
        return alg(fmap_expr(e, go))
    return go

# Algebras — plain functions, no recursion
def eval_alg(e):
    match e:
        case LitF(n=n):      return n
        case AddF(l=l, r=r): return l + r
        case MulF(l=l, r=r): return l * r

def pp_alg(e):
    match e:
        case LitF(n=n):      return str(n)
        case AddF(l=l, r=r): return f"({l} + {r})"
        case MulF(l=l, r=r): return f"({l} * {r})"

expr   = MulF(AddF(LitF(2), LitF(3)), LitF(4))
result = cata(eval_alg)(expr)   # 20
pretty = cata(pp_alg)(expr)     # "((2 + 3) * 4)"

# ---- Factorial via hylomorphism ----
@dataclass
class NilF:
    pass

@dataclass
class ConsF(Generic[R]):
    n: int
    r: R

def fmap_list(l, f):
    match l:
        case NilF():          return NilF()
        case ConsF(n=n, r=r): return ConsF(n=n, r=f(r))

def hylo(alg, coalg):
    def go(seed):
        return alg(fmap_list(coalg(seed), go))
    return go

range_coalg = lambda n: NilF() if n == 0 else ConsF(n=n, r=n - 1)
product_alg = lambda l: 1 if isinstance(l, NilF) else l.n * l.r
factorial   = hylo(product_alg, range_coalg)
# factorial(5) == 120
```

### Haskell

```hs
{-# LANGUAGE DeriveFunctor #-}
import Data.Functor.Foldable (Fix(..), cata, ana, hylo)
-- or from the `recursion-schemes` package (cata/ana/hylo already defined)

-- Base functor: R replaces every recursive position
data ExprF r = LitF Int | AddF r r | MulF r r
    deriving (Functor, Show)   -- deriving Functor gives us fmap for free

-- Expr = Fix ExprF; smart constructors
type Expr = Fix ExprF
lit :: Int -> Expr;      lit n   = Fix (LitF n)
add :: Expr -> Expr -> Expr; add l r = Fix (AddF l r)
mul :: Expr -> Expr -> Expr; mul l r = Fix (MulF l r)

-- Algebras: plain functions — no recursion
evalAlg :: ExprF Int -> Int
evalAlg (LitF n)   = n
evalAlg (AddF l r) = l + r
evalAlg (MulF l r) = l * r

ppAlg :: ExprF String -> String
ppAlg (LitF n)   = show n
ppAlg (AddF l r) = "(" ++ l ++ " + " ++ r ++ ")"
ppAlg (MulF l r) = "(" ++ l ++ " * " ++ r ++ ")"

eval :: Expr -> Int;    eval = cata evalAlg
pp   :: Expr -> String; pp   = cata ppAlg

expr :: Expr
expr = mul (add (lit 2) (lit 3)) (lit 4)
-- eval expr = 20
-- pp   expr = "((2 + 3) * 4)"

-- ---- Factorial via hylomorphism ----
-- ListF: base functor for lists; R = the tail
data ListF a r = NilF | ConsF a r deriving Functor

-- rangeCoalg: n -> [n, n-1, ..., 1]  (coalgebra = unfold step)
rangeCoalg :: Int -> ListF Int Int
rangeCoalg 0 = NilF
rangeCoalg n = ConsF n (n - 1)

-- productAlg: multiply all elements  (algebra = fold step)
productAlg :: ListF Int Int -> Int
productAlg NilF        = 1
productAlg (ConsF n r) = n * r

-- hylo: fused unfold + fold; the intermediate list is never built
factorial :: Int -> Int
factorial = hylo productAlg rangeCoalg
-- factorial 5 = 120

-- ---- Paramorphism (bonus): fold with access to the original subtree ----
-- `para` gives the algebra both the recursed value AND the original Fix node
sizePara :: ExprF (Expr, Int) -> Int
sizePara (LitF _)            = 1
sizePara (AddF (_, sl) (_, sr)) = 1 + sl + sr
sizePara (MulF (_, sl) (_, sr)) = 1 + sl + sr

-- import Data.Functor.Foldable (para)
-- para sizePara expr == 5  (4 nodes in (2+3)*4)
```

### Rust

```rust
// Base functor: ExprF<R> where R is the recursive position
enum ExprF<R> {
    Lit(i32),
    Add(R, R),
    Mul(R, R),
}

impl<R> ExprF<R> {
    // fmap: apply f to every R, producing ExprF<B>
    fn map<B>(self, mut f: impl FnMut(R) -> B) -> ExprF<B> {
        match self {
            ExprF::Lit(n)    => ExprF::Lit(n),
            ExprF::Add(l, r) => ExprF::Add(f(l), f(r)),
            ExprF::Mul(l, r) => ExprF::Mul(f(l), f(r)),
        }
    }
}

// Expr = Fix(ExprF): Box<ExprF<Expr>> to handle the recursive type
struct Expr(Box<ExprF<Expr>>);

fn lit(n: i32) -> Expr          { Expr(Box::new(ExprF::Lit(n))) }
fn add(l: Expr, r: Expr) -> Expr { Expr(Box::new(ExprF::Add(l, r))) }
fn mul(l: Expr, r: Expr) -> Expr { Expr(Box::new(ExprF::Mul(l, r))) }

// cata: the only explicit recursion
fn cata<A>(alg: &dyn Fn(ExprF<A>) -> A, e: Expr) -> A {
    alg((*e.0).map(|child| cata(alg, child)))
}

// Algebras — plain closures, no recursion
let eval_alg = |e: ExprF<i32>| match e {
    ExprF::Lit(n)    => n,
    ExprF::Add(l, r) => l + r,
    ExprF::Mul(l, r) => l * r,
};

let pp_alg = |e: ExprF<String>| match e {
    ExprF::Lit(n)    => n.to_string(),
    ExprF::Add(l, r) => format!("({l} + {r})"),
    ExprF::Mul(l, r) => format!("({l} * {r})"),
};

let e1 = mul(add(lit(2), lit(3)), lit(4));
let e2 = mul(add(lit(2), lit(3)), lit(4)); // Expr is not Clone; rebuild for second cata
let result = cata(&eval_alg, e1); // 20
let pretty = cata(&pp_alg,   e2); // "((2 + 3) * 4)"

// ---- Factorial via hylomorphism ----
enum ListF<R> { Nil, Cons(i32, R) }

impl<R> ListF<R> {
    fn map<B>(self, f: impl FnOnce(R) -> B) -> ListF<B> {
        match self {
            ListF::Nil        => ListF::Nil,
            ListF::Cons(n, r) => ListF::Cons(n, f(r)),
        }
    }
}

fn hylo<A, B>(
    alg:   &dyn Fn(ListF<B>) -> B,
    coalg: &dyn Fn(A) -> ListF<A>,
    seed:  A,
) -> B {
    alg(coalg(seed).map(|s| hylo(alg, coalg, s)))
}

let range_coalg = |n: i32| if n == 0 { ListF::Nil } else { ListF::Cons(n, n - 1) };
let product_alg = |l: ListF<i32>| match l {
    ListF::Nil        => 1_i32,
    ListF::Cons(n, r) => n * r,
};

// factorial(5) == 120
let result = hylo(&product_alg, &range_coalg, 5i32);

// For production use, the `recursion-schemes` crate provides cata/ana/hylo
// generated via proc macros over any #[derive(Recursive)] enum.
```

### Go

```go
import "fmt"

// Go: represent ExprF as an interface + concrete structs.
// The algebra is a struct of functions — one per constructor.

type Expr interface{ exprNode() }

type ExprLit struct{ N int }
type ExprAdd struct{ L, R Expr }
type ExprMul struct{ L, R Expr }

func (ExprLit) exprNode() {}
func (ExprAdd) exprNode() {}
func (ExprMul) exprNode() {}

// ExprAlgebra[A] bundles all cases of the algebra (= ExprF[A] -> A)
type ExprAlgebra[A any] struct {
	OnLit func(int) A
	OnAdd func(A, A) A
	OnMul func(A, A) A
}

// Cata: apply algebra bottom-up; encapsulates all recursion
func Cata[A any](alg ExprAlgebra[A], e Expr) A {
	switch v := e.(type) {
	case ExprLit:
		return alg.OnLit(v.N)
	case ExprAdd:
		return alg.OnAdd(Cata(alg, v.L), Cata(alg, v.R))
	case ExprMul:
		return alg.OnMul(Cata(alg, v.L), Cata(alg, v.R))
	}
	panic("unreachable")
}

// Algebras — plain struct values, no recursion
var evalAlg = ExprAlgebra[int]{
	OnLit: func(n int) int       { return n },
	OnAdd: func(l, r int) int    { return l + r },
	OnMul: func(l, r int) int    { return l * r },
}

var ppAlg = ExprAlgebra[string]{
	OnLit: func(n int) string          { return fmt.Sprintf("%d", n) },
	OnAdd: func(l, r string) string    { return fmt.Sprintf("(%s + %s)", l, r) },
	OnMul: func(l, r string) string    { return fmt.Sprintf("(%s * %s)", l, r) },
}

expr   := ExprMul{ExprAdd{ExprLit{2}, ExprLit{3}}, ExprLit{4}}
result := Cata(evalAlg, expr) // 20
pretty := Cata(ppAlg,   expr) // "((2 + 3) * 4)"

// ---- Factorial via hylomorphism ----
type ListF[R any] struct {
	IsNil bool
	N     int
	Tail  R
}

func Hylo[A, B any](
	alg   func(ListF[B]) B,
	coalg func(A) ListF[A],
	seed  A,
) B {
	shape := coalg(seed)
	if shape.IsNil {
		return alg(ListF[B]{IsNil: true})
	}
	return alg(ListF[B]{IsNil: false, N: shape.N,
		Tail: Hylo(alg, coalg, shape.Tail)})
}

rangeCoalg := func(n int) ListF[int] {
	if n == 0 {
		return ListF[int]{IsNil: true}
	}
	return ListF[int]{IsNil: false, N: n, Tail: n - 1}
}

productAlg := func(l ListF[int]) int {
	if l.IsNil {
		return 1
	}
	return l.N * l.Tail
}

factorial := func(n int) int { return Hylo(productAlg, rangeCoalg, n) }
// factorial(5) == 120
```
