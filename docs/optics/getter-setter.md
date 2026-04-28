# Getter and Setter

**Getter** and **Setter** are the two degenerate optics at the opposite ends of the hierarchy:

- A **Getter** can only _read_ a single focused value. It has no `set` or `over`. Every `Lens` is
  also a valid Getter, but a Getter may focus on derived or computed values (no corresponding `set`
  exists).
- A **Setter** can only _write_ or _modify_ focused values. It has no `get`. Every `Traversal` is
  also a valid Setter, but a Setter may target external mutable state where reading back is not
  meaningful.

![getter setter](getter-setter/getter-setter.svg)

## Types

```text
-- Getter: read a single value (no set)
Getter s a
to :: (s -> a) -> Getter s a   -- lift any function into a Getter

view     :: Getter s a -> s -> a
(^.)     :: s -> Getter s a -> a   -- Haskell operator form

-- van Laarhoven encoding:
type Getter s a = forall f. (Contravariant f, Functor f) => (a -> f a) -> s -> f s

-- Setter: write/modify (no get)
Setter s a
sets  :: ((a -> a) -> s -> s) -> Setter s a   -- lift a mapping function into a Setter

over  :: Setter s a -> (a -> a) -> s -> s
set   :: Setter s a -> a -> s -> s
(.~)  :: Setter s a -> a -> s -> s   -- Haskell operator form
(%~)  :: Setter s a -> (a -> a) -> s -> s

-- van Laarhoven encoding:
type Setter s a = forall f. Settable f => (a -> f a) -> s -> f s
```

## Laws

### Getter

A Getter has no set operation and therefore no laws beyond what the underlying function satisfies.
Any `s -> a` function can be promoted to a Getter with `to`.

### Setter

| Law         | Expression                                | Meaning                                   |
| ----------- | ----------------------------------------- | ----------------------------------------- |
| Identity    | `over st id = id`                         | Mapping identity is a no-op               |
| Composition | `over st f . over st g = over st (f . g)` | Two `over` passes equal one composed pass |

(The SetSet law from Lens does not apply: a Setter may have multiple targets.)

## Key use cases

**Getter**:

- Exposing a _derived_ or _computed_ field (`fullName = to (\p -> p.first ++ " " ++ p.last)`)
- Sharing a read path between multiple use sites without exposing a setter
- Bridging non-lens code: `to length`, `to show`, `to fst`

**Setter**:

- Modifying all targets of a traversal without needing to read them back
- Applying a bulk transformation to an external collection (mutation friendly)
- Side-effecting writers that do not return the modified structure

## Motivation

```text
-- Without Getter: derived fields are computed inline at every use site
putStrLn (firstName p ++ " " ++ lastName p)
logAge (currentYear - birthYear p)
-- The "how to read fullName" and "how to read age" logic is scattered.
```

```text
-- With Getter: the derived read is a first-class optic
fullNameG = to (\p -> firstName p ++ " " ++ lastName p)
ageG      = to (\p -> currentYear - birthYear p)

view fullNameG person   -- "Alice Smith"
view ageG      person   -- 30
-- Composable: fullNameG . each :: Getter Person Char
```

```text
-- Without Setter: bulk modification requires explicit recursion or map
prices' = map (+ tax) (map (* 1.1) prices)
-- Two passes; not composable with an enclosing Lens path.
```

```text
-- With Setter:
-- pricesS = sets (map)  (lift list's map into a Setter)
-- over (mapped . price) (* 1.1) orders   -- single-pass, composable
```

![getter setter motivation](getter-setter/getter-setter-motivation.svg)

## Examples

### C\#

```csharp
// Getter<S,A>: a read-only wrapper around Func<S,A>
record Getter<S, A>(Func<S, A> View);

// Setter<S,A>: a write-only wrapper around a mapping function
record Setter<S, A>(Func<Func<A, A>, S, S> Over)
{
    public S Set(A value, S s) => Over(_ => value, s);
}

record Person(string First, string Last, int BirthYear);

// Derived Getter: full name
var fullNameG = new Getter<Person, string>(p => $"{p.First} {p.Last}");

var alice = new Person("Alice", "Smith", 1994);
var name  = fullNameG.View(alice);                             // "Alice Smith"

// Setter over every character in a list
record NameList(IReadOnlyList<string> Names);

var namesSetter = new Setter<NameList, string>(
    f => nl => new NameList(nl.Names.Select(f).ToList()));

var names   = new NameList(new[] { "alice", "bob" });
var capped  = namesSetter.Over(s => char.ToUpper(s[0]) + s[1..], names);
// capped.Names == ["Alice", "Bob"]
```

### F\#

```fsharp
// Getter as a plain function alias; Setter as a mapping-function alias.

type Getter<'s, 'a> = 's -> 'a
type Setter<'s, 'a> = ('a -> 'a) -> 's -> 's

let view (g: Getter<'s,'a>) s = g s
let over (st: Setter<'s,'a>) f s = st f s
let set  (st: Setter<'s,'a>) v s = st (fun _ -> v) s

type Person = { First: string; Last: string; BirthYear: int }

// Derived Getter: not settable (no corresponding set makes sense)
let fullNameG : Getter<Person, string> =
    fun p -> sprintf "%s %s" p.First p.Last

let alice = { First = "Alice"; Last = "Smith"; BirthYear = 1994 }
let name  = view fullNameG alice                               // "Alice Smith"

// Setter over a list of strings
let mapSetter : Setter<string list, string> = List.map

let names  = ["alice"; "bob"]
let capped = over mapSetter (fun s ->
    string (System.Char.ToUpper s.[0]) + s.[1..]) names
// ["Alice"; "Bob"]
```

### Ruby

```ruby
# Getter: a callable that reads a derived value
# Setter: a callable that applies a mapping function to focused values

full_name_getter = ->(p) { "#{p[:first]} #{p[:last]}" }

alice = { first: 'Alice', last: 'Smith', birth_year: 1994 }
name  = full_name_getter.call(alice)                           # "Alice Smith"

# Setter: map over a list's elements
map_setter = ->(f, arr) { arr.map { |x| f.call(x) } }

names  = %w[alice bob]
capped = map_setter.call(->(s) { s.capitalize }, names)        # ["Alice", "Bob"]

# over helper:
def over(setter, f, s)
  setter.call(f, s)
end

upcased = over(map_setter, :upcase.to_proc, names)             # ["ALICE", "BOB"]
```

### C++

```cpp
#include <functional>
#include <string>
#include <vector>
#include <algorithm>

// Getter<S,A>: plain function wrapper
template <typename S, typename A>
struct Getter { std::function<A(const S&)> view; };

// Setter<S,A>: mapping-function wrapper
template <typename S, typename A>
struct Setter {
    std::function<S(std::function<A(A)>, const S&)> over;
    S set(A v, const S& s) const { return over([v](A) { return v; }, s); }
};

struct Person { std::string first, last; int birth_year; };

Getter<Person, std::string> fullNameG{
    [](const Person& p) { return p.first + " " + p.last; }
};
// fullNameG.view(alice) => "Alice Smith"

Setter<std::vector<std::string>, std::string> mapSetter{
    [](std::function<std::string(std::string)> f, const std::vector<std::string>& v) {
        std::vector<std::string> out;
        for (const auto& s : v) out.push_back(f(s));
        return out;
    }
};

Person alice{"Alice", "Smith", 1994};
auto name = fullNameG.view(alice);                             // "Alice Smith"

std::vector<std::string> names{"alice", "bob"};
auto capped = mapSetter.over(
    [](std::string s) { s[0] = static_cast<char>(std::toupper(s[0])); return s; }, names);
// {"Alice", "Bob"}
```

### JavaScript

```js
// Getter: a plain read function lifted into an optic
const to = (f) => ({ view: f });
// Setter: a mapping function lifted into an optic
const sets = (mapFn) => ({
  over: (f, s) => mapFn(f, s),
  set: (v, s) => mapFn(() => v, s),
});

const fullNameG = to((p) => `${p.first} ${p.last}`);

const alice = { first: "Alice", last: "Smith", birthYear: 1994 };
const name = fullNameG.view(alice); // "Alice Smith"

// Setter: map over an array's elements
const mapSetter = sets((f, arr) => arr.map(f));

const names = ["alice", "bob"];
const capped = mapSetter.over((s) => s[0].toUpperCase() + s.slice(1), names);
// ["Alice", "Bob"]

const cleared = mapSetter.set("", names);
// ["", ""]
```

### Python

```python
from dataclasses import dataclass
from typing import Callable, List

@dataclass(frozen=True)
class Person: first: str; last: str; birth_year: int

class Getter:
    def __init__(self, view_fn):
        self._view = view_fn
    def view(self, s):
        return self._view(s)

class Setter:
    def __init__(self, map_fn):
        self._map = map_fn
    def over(self, f, s):
        return self._map(f, s)
    def set(self, v, s):
        return self._map(lambda _: v, s)

full_name_g = Getter(lambda p: f"{p.first} {p.last}")

alice = Person("Alice", "Smith", 1994)
name  = full_name_g.view(alice)                                # "Alice Smith"

# Setter: map over a list
map_setter = Setter(lambda f, lst: [f(x) for x in lst])

names   = ["alice", "bob"]
capped  = map_setter.over(str.capitalize, names)               # ["Alice", "Bob"]
cleared = map_setter.set("", names)                            # ["", ""]
```

### Haskell

```hs
import Control.Lens

data Person = Person { _first :: String, _last :: String, _birthYear :: Int }
    deriving Show

makeLenses ''Person

-- to: lift any function into a Getter
fullNameG :: Getter Person String
fullNameG = to (\p -> _first p ++ " " ++ _last p)

alice :: Person
alice = Person "Alice" "Smith" 1994

name :: String
name = view fullNameG alice                  -- "Alice Smith"

-- Getter composes with other optics:
initials :: String
initials = toListOf (folding (\p -> [head (_first p), head (_last p)])) alice
-- "AS"

-- mapped: canonical Setter for any Functor
names :: [String]
names = ["alice", "bob"]

capped :: [String]
capped = over (mapped . _head) toUpper names  -- ["Alice", "Bob"]

-- sets: lift a mapping function into a Setter
filterSetter :: Setter [a] a
filterSetter = sets map  -- same as `mapped` but explicit

doubled :: [Int]
doubled = over (sets map) (* 2) [1, 2, 3]    -- [2, 4, 6]
```

### Rust

```rust
// Getter: a closure that reads a derived value
// Setter: a closure that applies a mapping to focused elements

struct Getter<S, A> {
    view: Box<dyn Fn(&S) -> A>,
}

struct Setter<S, A> {
    over: Box<dyn Fn(Box<dyn Fn(A) -> A>, S) -> S>,
}

impl<S, A: Clone> Setter<S, A> {
    fn set(&self, v: A, s: S) -> S {
        (self.over)(Box::new(move |_| v.clone()), s)
    }
}

#[derive(Debug, Clone)]
struct Person { first: String, last: String, birth_year: i32 }

let full_name_g: Getter<Person, String> = Getter {
    view: Box::new(|p| format!("{} {}", p.first, p.last)),
};

let alice = Person { first: "Alice".into(), last: "Smith".into(), birth_year: 1994 };
let name  = (full_name_g.view)(&alice);                        // "Alice Smith"

// Setter: map over a Vec
let map_setter: Setter<Vec<String>, String> = Setter {
    over: Box::new(|f, v| v.into_iter().map(|x| f(x)).collect()),
};

let names   = vec!["alice".to_string(), "bob".to_string()];
let capped  = (map_setter.over)(
    Box::new(|mut s: String| { if let Some(c) = s.get_mut(0..1) { c.make_ascii_uppercase(); } s }),
    names.clone(),
);
// ["Alice", "Bob"]
```

### Go

```go
import (
	"fmt"
	"strings"
	"unicode"
)

type Person struct{ First, Last string; BirthYear int }

// Getter[S,A]: a read-only function from S to A
type Getter[S, A any] struct {
	View func(S) A
}

// Setter[S,A]: a write-only "over" function
type Setter[S, A any] struct {
	Over func(func(A) A, S) S
}

func (st Setter[S, A]) Set(v A, s S) S {
	return st.Over(func(_ A) A { return v }, s)
}

fullNameG := Getter[Person, string]{
	View: func(p Person) string { return p.First + " " + p.Last },
}

alice := Person{"Alice", "Smith", 1994}
name  := fullNameG.View(alice)                                 // "Alice Smith"

// Setter: map over a []string
mapSetter := Setter[[]string, string]{
	Over: func(f func(string) string, ss []string) []string {
		out := make([]string, len(ss))
		for i, s := range ss { out[i] = f(s) }
		return out
	},
}

names  := []string{"alice", "bob"}
capped := mapSetter.Over(func(s string) string {
	r := []rune(s)
	r[0] = unicode.ToUpper(r[0])
	return string(r)
}, names)
fmt.Println(capped) // [Alice Bob]

cleared := mapSetter.Set("", names)
fmt.Println(cleared) // [ ]
```
