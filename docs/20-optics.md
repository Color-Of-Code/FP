# 20. Lens / Optics

**Optics** are composable, first-class tools for **focusing on a part of a data structure** — to
read it, update it, or fold over it — without breaking immutability or scattering field-access logic
across the codebase.

![optics hierarchy](diagrams/optics.svg)

A **lens** is the most common optic: it focuses on exactly one field inside a product type and
provides a `get` (read the field) and a `set`/`over` (return a new structure with the field
changed). Because lenses are values, they **compose** with function composition `(.)` — the
fundamental operation from [04. Composition](./04-composition.md) — making deep updates as readable
as shallow ones.

## Optic hierarchy

| Optic                                          | Focuses on                   | Can get? | Can set? | Can fold? | Typeclass constraint |
| ---------------------------------------------- | ---------------------------- | :------: | :------: | :-------: | -------------------- |
| **[Iso](optics/iso.md)**                       | isomorphic pair              |    ✓     |    ✓     |     ✓     | –                    |
| **[Lens](optics/lens.md)**                     | exactly one field            |    ✓     |    ✓     |     ✓     | –                    |
| **[Prism](optics/prism.md)**                   | one constructor (sum)        | partial  |    ✓     |     ✓     | –                    |
| **[Traversal](optics/traversal.md)**           | zero or more targets         |   fold   |    ✓     |     ✓     | `Traversable`        |
| **[Fold](optics/fold.md)**                     | zero or more, read-only      |   fold   |    ✗     |     ✓     | `Foldable`           |
| **[Getter / Setter](optics/getter-setter.md)** | one (Getter) or any (Setter) |  ✓ / ✗   |  ✗ / ✓   |     ✗     | –                    |

Every row is a **restriction** of the one above it. Lens ⊆ Traversal ⊆ Fold; Prism ⊆ Traversal. This
means any function that accepts a `Traversal` works with a `Lens` or a `Prism`.

## Core operations

For a `Lens s a` focusing on field `a` inside structure `s`:

| Operation         | Type                 | Description                                                    |
| ----------------- | -------------------- | -------------------------------------------------------------- |
| `view lens s`     | `s -> a`             | Read the focused value                                         |
| `set lens v s`    | `a -> s -> s`        | Replace the focused value; return new `s`                      |
| `over lens f s`   | `(a -> a) -> s -> s` | Apply a function to the focused value                          |
| `lens1 . lens2`   | `Lens s b`           | Compose: focus through `lens1` then `lens2`                    |
| `review prism v`  | `a -> s`             | Construct an `s` from a sum constructor value                  |
| `preview prism s` | `s -> Maybe a`       | Try to extract from a sum type; `Nothing` if wrong constructor |

## The van Laarhoven representation

In Haskell (and libraries that follow this encoding), a lens is a higher-ranked function:

```text
type Lens s t a b = forall f. Functor f => (a -> f b) -> s -> f t
-- Simplified (monomorphic, read + update same type):
type Lens' s a    = forall f. Functor f => (a -> f a) -> s -> s
```

This single type unifies `get` and `set`: by choosing `f = Identity` you get `set`/`over`; by
choosing `f = Const r` you get `view`. Composition is plain function composition `(.)`.

## Motivation

Updating a deeply nested immutable record without optics requires constructing every intermediate
layer by hand — the "record update pyramid".

```text
-- Without lenses: update city in deeply nested address
updateCity city person =
    person
      { address = (address person)
          { location = (location (address person))
              { city = city } } }
-- Three layers of record spread syntax for a single leaf field.
-- Adding one more level of nesting doubles the boilerplate.
```

```text
-- With lenses: compose the path; use `set` or `over`
updateCity city = set (address . location . city_) city
-- Composition depth is irrelevant; the update reads left-to-right.
-- The same lens path can be reused for `view`, `over`, and `preview`.
```

![optics motivation](diagrams/optics-motivation.svg)

## Examples

All examples use the same domain: a `Person` containing an `Address` containing a `City`. The task
is to:

1. **Read** the city name
2. **Update** the city name (produce a new `Person`)
3. **Compose** two lenses to do both in one path

### C\#

C# has no built-in lens library. The pattern is expressed as a plain record + `with` expressions (C#
9+). A minimal `Lens<S,A>` record captures get/set and composes them.

```csharp
record City(string Name);
record Address(City City);
record Person(string FirstName, Address Address);

// Minimal Lens<S,A>: get and set as a composed pair
record Lens<S, A>(Func<S, A> Get, Func<A, S, S> Set)
{
    public Lens<S, B> Compose<B>(Lens<A, B> inner) =>
        new(s => inner.Get(Get(s)),
            (b, s) => Set(inner.Set(b, Get(s)), s));

    public S Over(Func<A, A> f, S s) => Set(f(Get(s)), s);
}

// Define lenses for each field
var addressLens = new Lens<Person, Address>(
    p => p.Address,
    (a, p) => p with { Address = a });

var cityLens = new Lens<Address, City>(
    a => a.City,
    (c, a) => a with { City = c });

// Compose: person -> address -> city
var personCityLens = addressLens.Compose(cityLens);

var alice = new Person("Alice", new Address(new City("Paris")));

var cityName = personCityLens.Get(alice).Name;                         // "Paris"
var moved    = personCityLens.Over(c => c with { Name = "Berlin" }, alice);
// moved.Address.City.Name == "Berlin"
```

### F\#

F# has a mature optics ecosystem via [`Aether`](https://xyncro.tech/aether/) or
[`FSharpPlus`](https://fsprojects.github.io/FSharpPlus/). The hand-rolled example below shows the
pattern without a library.

```fsharp
type City    = { Name: string }
type Address = { City: City }
type Person  = { FirstName: string; Address: Address }

// Lens as a pair of functions
type Lens<'s, 'a> = { Get: 's -> 'a; Set: 'a -> 's -> 's }

let compose (outer: Lens<'s,'a>) (inner: Lens<'a,'b>) : Lens<'s,'b> = {
    Get = fun s   -> inner.Get (outer.Get s)
    Set = fun b s -> outer.Set (inner.Set b (outer.Get s)) s
}

let over (lens: Lens<'s,'a>) f s = lens.Set (f (lens.Get s)) s

// Field lenses
let addressLens : Lens<Person, Address> = {
    Get = fun p   -> p.Address
    Set = fun a p -> { p with Address = a }
}

let cityLens : Lens<Address, City> = {
    Get = fun a   -> a.City
    Set = fun c a -> { a with City = c }
}

let personCityLens = compose addressLens cityLens

let alice = { FirstName = "Alice"; Address = { City = { Name = "Paris" } } }

let cityName = personCityLens.Get alice                               // "Paris"
let moved    = over personCityLens (fun c -> { c with Name = "Berlin" }) alice
// moved.Address.City.Name = "Berlin"

// Using Aether (idiomatic F#):
// open Aether
// let addressL_ = Person.Address_ >-> Address.City_ >-> City.Name_
// let cityName = Optic.get addressL_ alice
// let moved    = Optic.set addressL_ "Berlin" alice
```

### Ruby

```ruby
# Ruby: Lens as a plain struct with compose and over helpers.

Lens = Struct.new(:get, :set) do
  def compose(inner)
    Lens.new(
      ->(s)    { inner.get.call(get.call(s)) },
      ->(b, s) { set.call(inner.set.call(b, get.call(s)), s) }
    )
  end

  def over(f, s)
    set.call(f.call(get.call(s)), s)
  end
end

# Immutable value objects via frozen structs
City    = Struct.new(:name)
Address = Struct.new(:city)
Person  = Struct.new(:first_name, :address)

address_lens = Lens.new(
  ->(p)    { p.address },
  ->(a, p) { Person.new(p.first_name, a) }
)

city_lens = Lens.new(
  ->(a)    { a.city },
  ->(c, a) { Address.new(c) }
)

person_city_lens = address_lens.compose(city_lens)

alice     = Person.new('Alice', Address.new(City.new('Paris')))
city_name = person_city_lens.get.call(alice).name               # "Paris"
moved     = person_city_lens.over(->(c) { City.new('Berlin') }, alice)
# moved.address.city.name == "Berlin"
```

### C++

```cpp
#include <functional>
#include <string>

// Immutable structs (copied on update)
struct City    { std::string name; };
struct Address { City city; };
struct Person  { std::string first_name; Address address; };

// Lens<S,A>: get + set composed as a pair of lambdas
template <typename S, typename A>
struct Lens {
    std::function<A(const S&)> get;
    std::function<S(A, const S&)> set;

    template <typename B>
    Lens<S, B> compose(const Lens<A, B>& inner) const {
        return {
            [*this, inner](const S& s) { return inner.get(get(s)); },
            [*this, inner](B b, const S& s) {
                return set(inner.set(std::move(b), get(s)), s);
            }
        };
    }

    S over(std::function<A(A)> f, const S& s) const {
        return set(f(get(s)), s);
    }
};

Lens<Person, Address> addressLens{
    [](const Person& p) { return p.address; },
    [](Address a, const Person& p) { return Person{p.first_name, std::move(a)}; }
};

Lens<Address, City> cityLens{
    [](const Address& a) { return a.city; },
    [](City c, const Address& a) { return Address{std::move(c)}; }
};

auto personCityLens = addressLens.compose(cityLens);

Person alice{"Alice", {{"Paris"}}};
auto cityName = personCityLens.get(alice).name;                       // "Paris"
auto moved    = personCityLens.over([](City c) { c.name = "Berlin"; return c; }, alice);
// moved.address.city.name == "Berlin"
```

### JavaScript

```js
// Lens as a plain object with get/set functions; compose chains them.

const Lens = (get, set) => ({
  get,
  set,
  over: (f, s) => set(f(get(s)), s),
  compose: (inner) =>
    Lens(
      (s) => inner.get(get(s)),
      (b, s) => set(inner.set(b, get(s)), s),
    ),
});

// Immutable updates via spread
const addressLens = Lens(
  (p) => p.address,
  (a, p) => ({ ...p, address: a }),
);

const cityLens = Lens(
  (a) => a.city,
  (c, a) => ({ ...a, city: c }),
);

const personCityLens = addressLens.compose(cityLens);

const alice = { firstName: "Alice", address: { city: { name: "Paris" } } };
const cityName = personCityLens.get(alice).name; // "Paris"
const moved = personCityLens.over((c) => ({ ...c, name: "Berlin" }), alice);
// moved.address.city.name === "Berlin"

// With the `monocle-ts` library (idiomatic TypeScript/JS):
// import * as L from 'monocle-ts/Lens'
// const personCity = pipe(L.id<Person>(), L.prop('address'), L.prop('city'))
// const cityName   = pipe(alice, L.get(personCity))
// const moved      = pipe(alice, L.modify(personCity)(c => ({...c, name: 'Berlin'})))
```

### Python

```python
from dataclasses import dataclass, replace
from typing import TypeVar, Generic, Callable

S = TypeVar('S')
A = TypeVar('A')
B = TypeVar('B')

@dataclass(frozen=True)
class City:
    name: str

@dataclass(frozen=True)
class Address:
    city: City

@dataclass(frozen=True)
class Person:
    first_name: str
    address: Address

class Lens(Generic[S, A]):
    def __init__(self, get: Callable, set_: Callable):
        self._get = get
        self._set = set_

    def get(self, s: S) -> A:
        return self._get(s)

    def set(self, a: A, s: S) -> S:
        return self._set(a, s)

    def over(self, f: Callable, s: S) -> S:
        return self.set(f(self.get(s)), s)

    def compose(self, inner: 'Lens[A, B]') -> 'Lens[S, B]':
        return Lens(
            lambda s:    inner.get(self.get(s)),
            lambda b, s: self.set(inner.set(b, self.get(s)), s),
        )

address_lens = Lens(lambda p: p.address,
                    lambda a, p: replace(p, address=a))

city_lens    = Lens(lambda a: a.city,
                    lambda c, a: replace(a, city=c))

person_city_lens = address_lens.compose(city_lens)

alice     = Person("Alice", Address(City("Paris")))
city_name = person_city_lens.get(alice).name                     # "Paris"
moved     = person_city_lens.over(lambda c: replace(c, name="Berlin"), alice)
# moved.address.city.name == "Berlin"

# With `lenses` package (idiomatic Python):
# from lenses import lens
# city_name = lens(alice).address.city.name.get()
# moved     = lens(alice).address.city.name.set("Berlin")
```

### Haskell

Haskell has the mature [`lens`](https://hackage.haskell.org/package/lens) and
[`optics`](https://hackage.haskell.org/package/optics) libraries. The van Laarhoven encoding allows
plain `(.)` to compose any optics.

```hs
{-# LANGUAGE TemplateHaskell #-}
import Control.Lens

data City    = City    { _cityName    :: String } deriving Show
data Address = Address { _addressCity :: City   } deriving Show
data Person  = Person  { _firstName   :: String
                       , _address     :: Address } deriving Show

-- Template Haskell generates lenses named `cityName`, `addressCity`, `address`
makeLenses ''City
makeLenses ''Address
makeLenses ''Person

alice :: Person
alice = Person "Alice" (Address (City "Paris"))

-- view: read through a composed path
cityName :: String
cityName = alice ^. address . addressCity . cityName  -- "Paris"

-- set: deep update; returns a new Person
moved :: Person
moved = alice & address . addressCity . cityName .~ "Berlin"

-- over: apply a function to the focused value
upcased :: Person
upcased = alice & address . addressCity . cityName %~ map Data.Char.toUpper
-- "PARIS"

-- Prism: focus on a sum type constructor
data Shape = Circle Double | Rect Double Double

_Circle :: Prism' Shape Double
_Circle = prism' Circle (\case Circle r -> Just r; _ -> Nothing)

-- preview returns Nothing when the wrong constructor
preview _Circle (Rect 3 4) -- Nothing
preview _Circle (Circle 5) -- Just 5.0

-- Traversal: update all elements of a nested list
nested :: [[Int]]
nested = [[1,2],[3,4]]

-- Use `traverse . traverse` to reach every Int
doubled :: [[Int]]
doubled = nested & traverse . traverse %~ (* 2)
-- [[2,4],[6,8]]
```

### Rust

```rust
// Rust has no built-in optic library comparable to Haskell's `lens`.
// The common crates are `lens-rs` and `lenses`.
// Idiomatic Rust uses plain methods + struct update syntax for simple cases,
// and getter/setter pairs for encapsulated types.

#[derive(Debug, Clone)]
struct City    { name: String }
#[derive(Debug, Clone)]
struct Address { city: City }
#[derive(Debug, Clone)]
struct Person  { first_name: String, address: Address }

// Manual lens methods — idiomatic and zero-cost
impl Person {
    fn city_name(&self) -> &str { &self.address.city.name }

    fn set_city_name(mut self, name: impl Into<String>) -> Self {
        self.address.city.name = name.into();
        self
    }

    fn over_city_name(self, f: impl FnOnce(String) -> String) -> Self {
        let new_name = f(self.address.city.name.clone());
        self.set_city_name(new_name)
    }
}

let alice = Person {
    first_name: "Alice".into(),
    address: Address { city: City { name: "Paris".into() } },
};

let city_name = alice.city_name();                                    // "Paris"
let moved     = alice.clone().set_city_name("Berlin");
// moved.address.city.name == "Berlin"
let upcased   = alice.over_city_name(|s| s.to_uppercase());
// upcased.address.city.name == "PARIS"

// With `lens-rs` crate (macro-generated):
// use lens_rs::*;
// #[derive(Lens)] struct Person { #[optic] address: Address, ... }
// let city_name = alice.view(optics!(address.city.name));
// let moved     = alice.set(optics!(address.city.name), "Berlin".into());
```

### Go

```go
// Go has no optics library. The standard approach uses accessor methods
// and returns new values (functional style) or modifies in place (pointer style).
// For deep updates, functional constructors are clearest.

import "strings"

type City    struct{ Name string }
type Address struct{ City City }
type Person  struct{ FirstName string; Address Address }

// Functional update: return a new Person with the city name changed
func (p Person) WithCityName(name string) Person {
	p.Address.City.Name = name
	return p
}

func (p Person) CityName() string {
	return p.Address.City.Name
}

func (p Person) OverCityName(f func(string) string) Person {
	return p.WithCityName(f(p.CityName()))
}

alice    := Person{FirstName: "Alice", Address: Address{City: City{Name: "Paris"}}}
cityName := alice.CityName()                          // "Paris"
moved    := alice.WithCityName("Berlin")
// moved.Address.City.Name == "Berlin"
upcased  := alice.OverCityName(strings.ToUpper)
// upcased.Address.City.Name == "PARIS"

// Generic Lens value (mirrors the algebraic definition)
type Lens[S, A any] struct {
	Get  func(S) A
	Set  func(A, S) S
}

func Over[S, A any](l Lens[S, A], f func(A) A, s S) S {
	return l.Set(f(l.Get(s)), s)
}

func Compose[S, A, B any](outer Lens[S, A], inner Lens[A, B]) Lens[S, B] {
	return Lens[S, B]{
		Get: func(s S) B { return inner.Get(outer.Get(s)) },
		Set: func(b B, s S) S { return outer.Set(inner.Set(b, outer.Get(s)), s) },
	}
}
```

## Optics catalogue

Each optic has a dedicated page with type, laws, motivation, and code examples in all nine
languages.

| Optic                                      | Summary                                           |
| ------------------------------------------ | ------------------------------------------------- |
| [Iso](optics/iso.md)                       | Lossless, reversible conversion between two types |
| [Lens](optics/lens.md)                     | Focus on exactly one field of a product type      |
| [Prism](optics/prism.md)                   | Focus on one constructor of a sum type            |
| [Traversal](optics/traversal.md)           | Focus on zero or more elements; read and write    |
| [Fold](optics/fold.md)                     | Focus on zero or more elements; read only         |
| [Getter / Setter](optics/getter-setter.md) | Read-only (derived values) and write-only optics  |
