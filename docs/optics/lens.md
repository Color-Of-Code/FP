# Lens

A **Lens** is an optic that focuses on **exactly one field inside a product type** (a record or
tuple). It provides a `get` to read the field and a `set`/`over` to return a new structure with the
field replaced — without mutating the original.

![lens](lens/lens.svg)

## Type

```text
Lens s a
-- s = the whole structure ("source")
-- a = the focused field ("focus")

get  :: Lens s a -> s -> a
set  :: Lens s a -> a -> s -> s
over :: Lens s a -> (a -> a) -> s -> s

-- van Laarhoven encoding (Haskell):
type Lens' s a = forall f. Functor f => (a -> f a) -> s -> s
-- Choosing f = Identity  gives set/over.
-- Choosing f = Const r   gives get (view).
-- Composition is plain function composition (.):
-- address . city  :: Lens' Person City
```

## Laws

| Law    | Expression                        | Meaning                                     |
| ------ | --------------------------------- | ------------------------------------------- |
| GetSet | `set l (get l s) s = s`           | Setting back what you got is a no-op        |
| SetGet | `get l (set l a s) = a`           | After setting, you get what you set         |
| SetSet | `set l b (set l a s) = set l b s` | Two consecutive sets — only the last counts |

A well-behaved lens satisfies all three. Violating them produces surprising behaviour when lenses
are composed or used in optic combinators.

## Key use cases

- Reading or updating a single field of a deeply nested immutable record
- Building a reusable path that can be passed to `view`, `set`, `over`, `preview`
- Composing with other optics (`Prism`, `Traversal`) to reach deeper targets
- Providing a first-class handle to a field (e.g. for configuration, serialisation)

## Motivation

Without lenses, every deep update requires reconstructing every intermediate layer by hand. The
boilerplate grows linearly with nesting depth and must be repeated for each transformation.

```text
-- Without lens: manual record spread at every level
updateCity city person =
    person { address = (address person) { city = city } }

-- Adding one level of nesting doubles the spread expressions.
-- Every caller that needs the same path writes the same boilerplate.
```

```text
-- With lens: define the path once; all operations use it
addressL = Lens { get = .address, set = \a p -> p { address = a } }
cityL    = Lens { get = .city,    set = \c a -> a { city    = c } }

personCityL = compose addressL cityL   -- Lens Person City

get   personCityL alice           -- read
set   personCityL "Berlin" alice  -- write
over  personCityL toUpper alice   -- modify
-- The same lens works for view, set, over, and composes with Traversal/Prism.
```

![lens motivation](lens/lens-motivation.svg)

## Examples

### C\#

```csharp
// Minimal Lens<S,A>: pair of get/set functions that compose
record Lens<S, A>(Func<S, A> Get, Func<A, S, S> Set)
{
    public S Over(Func<A, A> f, S s) => Set(f(Get(s)), s);

    public Lens<S, B> Then<B>(Lens<A, B> inner) =>
        new(s => inner.Get(Get(s)),
            (b, s) => Set(inner.Set(b, Get(s)), s));
}

record City(string Name);
record Address(City City);
record Person(string Name, Address Address);

var addressL = new Lens<Person, Address>(p => p.Address, (a, p) => p with { Address = a });
var cityL    = new Lens<Address, City>(a => a.City,       (c, a) => a with { City = c });
var personCityL = addressL.Then(cityL);

var alice = new Person("Alice", new Address(new City("Paris")));
var city  = personCityL.Get(alice).Name;                     // "Paris"
var moved = personCityL.Set(new City("Berlin"), alice);
// moved.Address.City.Name == "Berlin"

// Law checks:
// GetSet: personCityL.Set(personCityL.Get(alice), alice) == alice  ✓
// SetGet: personCityL.Get(personCityL.Set(new City("Berlin"), alice)).Name == "Berlin"  ✓
```

### F\#

```fsharp
type Lens<'s, 'a> = { Get: 's -> 'a; Set: 'a -> 's -> 's }

let compose (outer: Lens<'s,'a>) (inner: Lens<'a,'b>) : Lens<'s,'b> = {
    Get = fun s   -> inner.Get (outer.Get s)
    Set = fun b s -> outer.Set (inner.Set b (outer.Get s)) s
}

let over (l: Lens<'s,'a>) f s = l.Set (f (l.Get s)) s

type City    = { Name: string }
type Address = { City: City }
type Person  = { Name: string; Address: Address }

let addressL = { Get = fun p -> p.Address;  Set = fun a p -> { p with Address = a } }
let cityL    = { Get = fun a -> a.City;     Set = fun c a -> { a with City = c } }
let personCityL = compose addressL cityL

let alice = { Name = "Alice"; Address = { City = { Name = "Paris" } } }

let city  = personCityL.Get alice                               // "Paris"
let moved = personCityL.Set { Name = "Berlin" } alice
// moved.Address.City.Name = "Berlin"

// Using Aether:
// open Aether
// let city_  = Person.address_ >-> Address.city_ >-> City.name_
// let city   = Optic.get city_ alice
// let moved  = Optic.set city_ "Berlin" alice
```

### Ruby

```ruby
Lens = Struct.new(:get, :set) do
  def then(inner)
    Lens.new(
      ->(s)    { inner.get.call(get.call(s)) },
      ->(b, s) { set.call(inner.set.call(b, get.call(s)), s) }
    )
  end

  def over(f, s)
    set.call(f.call(get.call(s)), s)
  end
end

City    = Struct.new(:name)
Address = Struct.new(:city)
Person  = Struct.new(:name, :address)

address_l = Lens.new(->(p)    { p.address },
                     ->(a, p) { Person.new(p.name, a) })
city_l    = Lens.new(->(a)    { a.city },
                     ->(c, a) { Address.new(c) })
person_city_l = address_l.then(city_l)

alice = Person.new('Alice', Address.new(City.new('Paris')))
city  = person_city_l.get.call(alice).name                  # "Paris"
moved = person_city_l.set.call(City.new('Berlin'), alice)
# moved.address.city.name == "Berlin"
```

### C++

```cpp
#include <functional>
#include <string>

template <typename S, typename A>
struct Lens {
    std::function<A(const S&)> get;
    std::function<S(A, const S&)> set;

    S over(std::function<A(A)> f, const S& s) const {
        return set(f(get(s)), s);
    }

    template <typename B>
    Lens<S, B> then(const Lens<A, B>& inner) const {
        return {
            [*this, inner](const S& s) { return inner.get(get(s)); },
            [*this, inner](B b, const S& s) {
                return set(inner.set(std::move(b), get(s)), s);
            }
        };
    }
};

struct City    { std::string name; };
struct Address { City city; };
struct Person  { std::string name; Address address; };

Lens<Person, Address> addressL{
    [](const Person& p)               { return p.address; },
    [](Address a, const Person& p)    { return Person{p.name, std::move(a)}; }
};
Lens<Address, City> cityL{
    [](const Address& a)              { return a.city; },
    [](City c, const Address&)        { return Address{std::move(c)}; }
};
auto personCityL = addressL.then(cityL);

Person alice{"Alice", {{"Paris"}}};
auto city  = personCityL.get(alice).name;                      // "Paris"
auto moved = personCityL.set(City{"Berlin"}, alice);
// moved.address.city.name == "Berlin"
```

### JavaScript

```js
const Lens = (get, set) => ({
  get,
  set,
  over: (f, s) => set(f(get(s)), s),
  then: (inner) =>
    Lens(
      (s) => inner.get(get(s)),
      (b, s) => set(inner.set(b, get(s)), s),
    ),
});

const addressL = Lens(
  (p) => p.address,
  (a, p) => ({ ...p, address: a }),
);
const cityL = Lens(
  (a) => a.city,
  (c, a) => ({ ...a, city: c }),
);
const personCityL = addressL.then(cityL);

const alice = { name: "Alice", address: { city: { name: "Paris" } } };
const city = personCityL.get(alice).name; // "Paris"
const moved = personCityL.set({ name: "Berlin" }, alice);
// moved.address.city.name === "Berlin"

// With monocle-ts:
// import * as L from 'monocle-ts/Lens'
// const personCity = pipe(L.id<Person>(), L.prop('address'), L.prop('city'))
```

### Python

```python
from dataclasses import dataclass, replace

@dataclass(frozen=True)
class City:    name: str
@dataclass(frozen=True)
class Address: city: City
@dataclass(frozen=True)
class Person:  name: str; address: Address

class Lens:
    def __init__(self, get, set_):
        self._get = get; self._set = set_

    def get(self, s):       return self._get(s)
    def set(self, a, s):    return self._set(a, s)
    def over(self, f, s):   return self.set(f(self.get(s)), s)

    def then(self, inner):
        return Lens(
            lambda s:    inner.get(self.get(s)),
            lambda b, s: self.set(inner.set(b, self.get(s)), s),
        )

address_l     = Lens(lambda p: p.address,  lambda a, p: replace(p, address=a))
city_l        = Lens(lambda a: a.city,     lambda c, a: replace(a, city=c))
person_city_l = address_l.then(city_l)

alice = Person("Alice", Address(City("Paris")))
city  = person_city_l.get(alice).name                          # "Paris"
moved = person_city_l.set(City("Berlin"), alice)
# moved.address.city.name == "Berlin"

# With the `lenses` package:
# from lenses import lens
# moved = lens(alice).address.city.name.set("Berlin")
```

### Haskell

```hs
{-# LANGUAGE TemplateHaskell #-}
import Control.Lens

data City    = City    { _cityName    :: String } deriving Show
data Address = Address { _addressCity :: City   } deriving Show
data Person  = Person  { _personName  :: String
                       , _address     :: Address } deriving Show

makeLenses ''City
makeLenses ''Address
makeLenses ''Person

alice :: Person
alice = Person "Alice" (Address (City "Paris"))

-- view / (^.) reads the focused field
city :: String
city = alice ^. address . addressCity . cityName   -- "Paris"

-- (.~) sets the focused field; (&) is flip ($)
moved :: Person
moved = alice & address . addressCity . cityName .~ "Berlin"

-- (%~) applies a function to the focused field
upcased :: Person
upcased = alice & address . addressCity . cityName %~ map toUpper
-- "PARIS"

-- Laws hold by construction for makeLenses-generated lenses:
-- view l (set l v s) == v           (SetGet)
-- set l (view l s) s == s           (GetSet)
-- set l v2 (set l v1 s) == set l v2 s  (SetSet)
```

### Rust

```rust
#[derive(Debug, Clone)]
struct City    { name: String }
#[derive(Debug, Clone)]
struct Address { city: City }
#[derive(Debug, Clone)]
struct Person  { name: String, address: Address }

// Functional Lens<S,A> as a struct of closures (heap-allocated for generality)
struct Lens<S, A> {
    get: Box<dyn Fn(&S) -> A>,
    set: Box<dyn Fn(A, S) -> S>,
}

impl<S: Clone, A> Lens<S, A> {
    fn over(&self, f: impl Fn(A) -> A, s: S) -> S {
        (self.set)(f((self.get)(&s)), s)
    }
}

fn compose<S: Clone + 'static, A: Clone + 'static, B: Clone + 'static>(
    outer: Lens<S, A>,
    inner: Lens<A, B>,
) -> Lens<S, B> {
    Lens {
        get: Box::new(move |s| (inner.get)(&(outer.get)(s))),
        set: Box::new(move |b, s| {
            let a = (outer.get)(&s);
            (outer.set)((inner.set)(b, a), s)
        }),
    }
}

let address_l: Lens<Person, Address> = Lens {
    get: Box::new(|p| p.address.clone()),
    set: Box::new(|a, mut p| { p.address = a; p }),
};
let city_l: Lens<Address, City> = Lens {
    get: Box::new(|a| a.city.clone()),
    set: Box::new(|c, mut a| { a.city = c; a }),
};
let person_city_l = compose(address_l, city_l);

let alice = Person { name: "Alice".into(), address: Address { city: City { name: "Paris".into() } } };
let city  = (person_city_l.get)(&alice).name.clone();            // "Paris"
let moved = (person_city_l.set)(City { name: "Berlin".into() }, alice.clone());
// moved.address.city.name == "Berlin"

// With `lens-rs`:
// #[derive(Lens)] struct Person { #[optic] address: Address, ... }
// let city = alice.view(optics!(address.city.name));
```

### Go

```go
import "strings"

type City    struct{ Name string }
type Address struct{ City City }
type Person  struct{ Name string; Address Address }

// Lens[S,A]: typed pair of get/set
type Lens[S, A any] struct {
	Get func(S) A
	Set func(A, S) S
}

func (l Lens[S, A]) Over(f func(A) A, s S) S {
	return l.Set(f(l.Get(s)), s)
}

func Compose[S, A, B any](outer Lens[S, A], inner Lens[A, B]) Lens[S, B] {
	return Lens[S, B]{
		Get: func(s S) B { return inner.Get(outer.Get(s)) },
		Set: func(b B, s S) S { return outer.Set(inner.Set(b, outer.Get(s)), s) },
	}
}

addressL := Lens[Person, Address]{
	Get: func(p Person) Address  { return p.Address },
	Set: func(a Address, p Person) Person { p.Address = a; return p },
}
cityL := Lens[Address, City]{
	Get: func(a Address) City     { return a.City },
	Set: func(c City, a Address) Address { a.City = c; return a },
}
personCityL := Compose(addressL, cityL)

alice    := Person{Name: "Alice", Address: Address{City: City{Name: "Paris"}}}
city     := personCityL.Get(alice).Name                        // "Paris"
moved    := personCityL.Set(City{Name: "Berlin"}, alice)
upcased  := personCityL.Over(func(c City) City {
	c.Name = strings.ToUpper(c.Name); return c
}, alice)
// upcased.Address.City.Name == "PARIS"
```
