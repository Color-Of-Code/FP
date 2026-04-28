# Iso

An **Iso** (isomorphism) is an optic that captures a **lossless, reversible conversion** between two
types. You can `view` (convert `s → a`), `review` (convert `a → s`), and both directions compose
freely with every other optic.

Because an Iso is strictly stronger than a Lens (and a Prism), it can be used anywhere either is
accepted.

![iso](iso/iso.svg)

## Type

```text
Iso s a
-- s = the "source" type
-- a = the "target" type (isomorphic to s)

view   :: Iso s a -> s -> a   -- convert in one direction
review :: Iso s a -> a -> s   -- convert in the other direction
over   :: Iso s a -> (a -> a) -> s -> s  -- transform in the target view, then convert back

-- van Laarhoven / profunctor encoding (Haskell):
type Iso' s a = forall p f. (Profunctor p, Functor f) => p a (f a) -> p s (f s)
-- An Iso carries both a "to" and a "from" in its type.
-- It is a valid Lens, Prism, and Traversal simultaneously.
```

## Laws

| Law           | Expression                | Meaning                          |
| ------------- | ------------------------- | -------------------------------- |
| Left inverse  | `view i (review i a) = a` | `review` then `view` is identity |
| Right inverse | `review i (view i s) = s` | `view` then `review` is identity |

Both directions are total and lossless. If either direction loses information the type is not an Iso
— it may be a Prism or a Getter instead.

## Key use cases

- Converting between equivalent representations (`String` ↔ `[Char]`, `newtype` ↔ wrapped type)
- Normalising a value before operating on it and denormalising after (e.g. degrees ↔ radians)
- Swapping tuple fields: `swapped :: Iso (a, b) (b, a)`
- Lifting a transformation through a newtype wrapper without manual wrapping/unwrapping

## Motivation

Without an Iso, every function that needs a different representation must manually call the
conversion in both directions, interleaving conversion with logic.

```text
-- Without iso: manual back-and-forth conversion everywhere
processEmail email =
    let lower = toLower (unEmail email)     -- unwrap, convert
        ...
    in Email lower                          -- re-wrap
-- Every use site knows about the newtype internals.
-- Two-way conversion is repeated and unstructured.
```

```text
-- With iso: the conversion is a first-class value
_Email :: Iso' Email String   -- Email ↔ String

processEmail = over _Email toLower        -- convert to String, apply, convert back
-- The newtype internals are hidden; the transformation reads as plain String -> String.
-- Compose with other optics: _Email . each :: Traversal' Email Char
```

![iso motivation](iso/iso-motivation.svg)

## Examples

### C\#

```csharp
// Iso<S,A>: pair of total, inverse functions
record Iso<S, A>(Func<S, A> View, Func<A, S> Review)
{
    public S Over(Func<A, A> f, S s) => Review(f(View(s)));
}

record Email(string Value);

var _email = new Iso<Email, string>(e => e.Value, s => new Email(s));

var email     = new Email("Alice@Example.Com");
var lower     = _email.Over(s => s.ToLowerInvariant(), email);
// lower.Value == "alice@example.com"

// Roundtrip laws:
var s = new Email("test@example.com");
var a = _email.View(s);
// _email.Review(a) == s          (right inverse)
// _email.View(_email.Review(a)) == a   (left inverse)

// Compose: wrap the string-level Iso with a length getter
var lengthGetter = _email.View;
var len = lengthGetter(email).Length;  // 19
```

### F\#

```fsharp
type Iso<'s, 'a> = { View: 's -> 'a; Review: 'a -> 's }

let over (i: Iso<'s,'a>) f s = i.Review (f (i.View s))

type Email = Email of string

let _email : Iso<Email, string> = {
    View   = fun (Email s) -> s
    Review = fun s -> Email s
}

let email  = Email "Alice@Example.Com"
let lower  = over _email (fun s -> s.ToLowerInvariant()) email
// lower = Email "alice@example.com"

// Laws:
// _email.Review (_email.View email) = email   ✓
// _email.View (_email.Review "x")   = "x"     ✓

// Using FSharpPlus or Aether:
// let emailIso_ = (fun (Email s) -> s), Email
// Optic.get (Iso.ofPair emailIso_) email
```

### Ruby

```ruby
Iso = Struct.new(:view, :review) do
  def over(f, s)
    review.call(f.call(view.call(s)))
  end
end

Email = Struct.new(:value)

_email = Iso.new(->(e) { e.value }, ->(s) { Email.new(s) })

email = Email.new('Alice@Example.Com')
lower = _email.over(->(s) { s.downcase }, email)
# lower.value == "alice@example.com"

# Laws:
# _email.review.call(_email.view.call(email)) == email  ✓
```

### C++

```cpp
#include <functional>
#include <string>
#include <algorithm>

template <typename S, typename A>
struct Iso {
    std::function<A(const S&)> view;
    std::function<S(A)> review;

    S over(std::function<A(A)> f, const S& s) const {
        return review(f(view(s)));
    }
};

struct Email { std::string value; };

Iso<Email, std::string> _email{
    [](const Email& e) { return e.value; },
    [](std::string s)  { return Email{std::move(s)}; }
};

Email email{"Alice@Example.Com"};
auto lower = _email.over([](std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), ::tolower);
    return s;
}, email);
// lower.value == "alice@example.com"
```

### JavaScript

```js
const Iso = (view, review) => ({
  view,
  review,
  over: (f, s) => review(f(view(s))),
});

// Email as a plain wrapper object
const mkEmail = (value) => ({ tag: "email", value });
const _email = Iso(
  (e) => e.value,
  (s) => mkEmail(s),
);

const email = mkEmail("Alice@Example.Com");
const lower = _email.over((s) => s.toLowerCase(), email);
// lower.value === "alice@example.com"

// Compose: an Iso from degrees to radians
const _radians = Iso(
  (deg) => (deg * Math.PI) / 180,
  (rad) => (rad * 180) / Math.PI,
);
const halfPi = _radians.view(90); // Math.PI / 2
```

### Python

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Email:
    value: str

class Iso:
    def __init__(self, view, review):
        self._view   = view
        self._review = review

    def view(self, s):     return self._view(s)
    def review(self, a):   return self._review(a)
    def over(self, f, s):  return self.review(f(self.view(s)))

_email = Iso(lambda e: e.value, lambda s: Email(s))

email = Email("Alice@Example.Com")
lower = _email.over(str.lower, email)
# lower.value == "alice@example.com"

# Laws:
# _email.review(_email.view(email)) == email  ✓
# _email.view(_email.review("x"))   == "x"    ✓

# Degrees <-> radians Iso
import math
_radians = Iso(lambda d: d * math.pi / 180, lambda r: r * 180 / math.pi)
half_pi = _radians.view(90)  # math.pi / 2
```

### Haskell

```hs
import Control.Lens

-- Iso using the `iso` smart constructor from the lens library
-- iso :: (s -> a) -> (a -> s) -> Iso' s a
newtype Email = Email { unEmail :: String } deriving Show

_email :: Iso' Email String
_email = iso unEmail Email

email :: Email
email = Email "Alice@Example.Com"

-- view / (^.) goes in the forward direction
lower :: Email
lower = over _email (map toLower) email
-- Email {unEmail = "alice@example.com"}

-- review goes in the reverse direction
constructed :: Email
constructed = review _email "user@example.com"
-- Email {unEmail = "user@example.com"}

-- Compose with other optics:
-- _email . each :: Traversal' Email Char
chars :: [Char]
chars = toListOf (_email . each) email

-- Standard Isos in lens:
-- swapped   :: Iso' (a, b) (b, a)
-- flipped   :: Iso' (a -> b -> c) (b -> a -> c)
-- from      :: Iso' s a -> Iso' a s  (reverse an Iso)

pair :: (Int, String)
pair = (42, "hello")
swappedPair :: (String, Int)
swappedPair = view swapped pair   -- ("hello", 42)
```

### Rust

```rust
// Rust: Iso as a pair of inverse functions (closures).
// Newtypes are the natural Iso use case.

struct Email(String);

struct Iso<S, A> {
    view:   Box<dyn Fn(S) -> A>,
    review: Box<dyn Fn(A) -> S>,
}

impl<S, A> Iso<S, A> {
    fn over(&self, f: impl Fn(A) -> A, s: S) -> S {
        (self.review)(f((self.view)(s)))
    }
}

let email_iso: Iso<Email, String> = Iso {
    view:   Box::new(|e: Email| e.0),
    review: Box::new(|s: String| Email(s)),
};

let email = Email("Alice@Example.Com".into());
let lower = email_iso.over(|s| s.to_lowercase(), email);
// lower.0 == "alice@example.com"

// Newtype wrapping/unwrapping is the most common Iso use case in Rust.
// For degrees <-> radians:
let deg_to_rad: Iso<f64, f64> = Iso {
    view:   Box::new(|d| d * std::f64::consts::PI / 180.0),
    review: Box::new(|r| r * 180.0 / std::f64::consts::PI),
};
let half_pi = (deg_to_rad.view)(90.0_f64);   // std::f64::consts::FRAC_PI_2
```

### Go

```go
import (
	"strings"
	"math"
)

// Email newtype
type Email struct{ Value string }

// Iso[S,A]: total, inverse pair of functions
type Iso[S, A any] struct {
	View   func(S) A
	Review func(A) S
}

func (i Iso[S, A]) Over(f func(A) A, s S) S {
	return i.Review(f(i.View(s)))
}

emailIso := Iso[Email, string]{
	View:   func(e Email) string  { return e.Value },
	Review: func(s string) Email  { return Email{s} },
}

email := Email{"Alice@Example.Com"}
lower := emailIso.Over(strings.ToLower, email)
// lower.Value == "alice@example.com"

// Laws:
// emailIso.Review(emailIso.View(email)) == email  ✓
// emailIso.View(emailIso.Review("x"))   == "x"    ✓

// Degrees <-> radians
degToRad := Iso[float64, float64]{
	View:   func(d float64) float64 { return d * math.Pi / 180 },
	Review: func(r float64) float64 { return r * 180 / math.Pi },
}
halfPi := degToRad.View(90) // math.Pi / 2
```
