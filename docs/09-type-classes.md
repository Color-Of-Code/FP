# 9. Type Classes

A **type class** is a named contract: a set of operations and laws that a type must satisfy. Any
type that provides implementations for those operations is said to have an **instance** of the class
and can be used wherever the class is required. Type classes build directly on
[7. Algebraic Data Types](./07-adt.md): ADTs define the _shape_ of data; type classes define
_behaviour_ that can be attached to that shape.

Every abstraction in the rest of this track — Semigroup, Monoid, Functor, Applicative, Foldable,
Traversable, Monad — is a type class. Understanding the mechanism here makes all of those chapters
coherent.

![type classes](diagrams/type-classes.svg)

## Anatomy

```text
-- 1. Declare the class: name + operations (and optionally laws)
class Printable a where
    display :: a -> String

-- 2. Write instances: implementations for specific types
instance Printable Int where
    display n = show n

instance Printable Bool where
    display True  = "yes"
    display False = "no"

-- 3. Use the class: constrain a type variable with =>
printAll :: Printable a => [a] -> IO ()
printAll xs = mapM_ (putStrLn . display) xs

-- Works for any type with a Printable instance:
printAll [1, 2, 3]           -- Int instance
printAll [True, False, True] -- Bool instance
```

## Parametric vs ad-hoc polymorphism

| Kind                    | What varies                             | Example                                |
| ----------------------- | --------------------------------------- | -------------------------------------- |
| **Parametric**          | Works for _any_ type `a`                | `id :: a -> a`, `length :: [a] -> Int` |
| **Ad-hoc** (type class) | Works for types _that have an instance_ | `show :: Show a => a -> String`        |

Parametric polymorphism cannot inspect the value at all. Ad-hoc polymorphism dispatches to the
correct implementation based on the type.

## Laws

Operations alone are not enough. A type class also carries **laws** — equalities that every instance
must satisfy:

```text
-- Eq laws
x == x              -- reflexivity
x == y  ⟹  y == x  -- symmetry
x == y ∧ y == z  ⟹  x == z  -- transitivity

-- Ord laws (additionally)
compare x y == EQ  ⟺  x == y
compare x y == LT  ⟺  compare y x == GT
```

Laws allow code that is written against the type class to make assumptions that hold for _all_ legal
instances, enabling [3. Equational Reasoning](./03-equational-reasoning.md).

## How each language expresses type classes

| Language   | Mechanism                                                            |
| ---------- | -------------------------------------------------------------------- |
| Haskell    | Native `class` / `instance` syntax; compiler resolves instances      |
| Rust       | `trait` + `impl T for Type`; monomorphised at compile time           |
| C#         | `interface` + generics; runtime virtual dispatch                     |
| F#         | `interface` or inline-if member constraints; structural typing       |
| C++        | `concept` (C++20) or manual SFINAE; monomorphised                    |
| Go         | `interface`; structural (implicit) implementation                    |
| Python     | Protocol (structural) or ABC (nominal); duck typing                  |
| Ruby       | Module as mixin; duck typing                                         |
| JavaScript | No native mechanism; conventions via duck typing or Symbol protocols |

## Motivation

```text
-- without a type class: one sort function per comparison strategy
sortUsersByAge  :: [User] -> [User]
sortUsersByName :: [User] -> [User]
sortIntList     :: [Int]  -> [Int]
-- every new type or strategy requires a new function
```

```text
-- with a type class (Ord): one generic sort for all ordered types
sort :: Ord a => [a] -> [a]

-- The compiler resolves which compare to use based on the type:
sort [3, 1, 4, 1, 5]        -- uses Ord Int
sort ["banana", "apple"]    -- uses Ord String
sort [User{age=30}, ...]    -- uses Ord User  (if we write an instance)
```

![type classes motivation](diagrams/type-classes-motivation.svg)

## Examples

### C\#

```csharp
// C# expresses type classes via generic interfaces.
// The 'constraint' (where T : IComparable<T>) is the type class constraint.

interface IPrintable<T>
{
    string Display(T value);
}

// "Instance" for int
class PrintableInt : IPrintable<int>
{
    public string Display(int value) => value.ToString();
}

// Generic function constrained to types with IComparable (the Ord type class)
static T Min<T>(T a, T b) where T : IComparable<T> =>
    a.CompareTo(b) <= 0 ? a : b;

// Usage
Console.WriteLine(Min(3, 5));       // 3
Console.WriteLine(Min("apple", "banana")); // apple
```

### F\#

```fsharp
// F# uses interfaces and member constraints to express type class-like patterns.
// The standard library's comparison operators are resolved via member constraints.

// Ad-hoc polymorphism via interface
type IPrintable<'a> =
    abstract Display : 'a -> string

let printableInt = { new IPrintable<int> with member _.Display n = string n }
let printableBool = { new IPrintable<bool> with member _.Display b = if b then "yes" else "no" }

// Generic function using interface constraint
let printAll (p: IPrintable<'a>) (xs: 'a list) =
    xs |> List.iter (p.Display >> printfn "%s")

printAll printableInt [1; 2; 3]
printAll printableBool [true; false]

// F# also uses inline + ^T member constraints for structural type classes:
let inline show (x: ^T) = (^T : (member ToString : unit -> string) x)
```

### Ruby

```ruby
# Ruby uses modules as mixins to attach shared behaviour to types.
# Including Comparable (with <=> defined) gives you <, <=, >, >=, between?, clamp.

class Temperature
  include Comparable

  attr_reader :degrees

  def initialize(degrees)
    @degrees = degrees
  end

  # "Instance" of Comparable: define the one required operation
  def <=>(other)
    degrees <=> other.degrees
  end
end

temps = [Temperature.new(30), Temperature.new(15), Temperature.new(22)]
puts temps.min.degrees  # 15
puts temps.sort.map(&:degrees).inspect  # [15, 22, 30]

# Enumerable is another type class: include it, define each, get map/filter/etc.
```

### C++

```cpp
#include <concepts>
#include <string>

// C++20 concept = type class declaration
template<typename T>
concept Printable = requires(T x) {
    { x.display() } -> std::convertible_to<std::string>;
};

// "Instance": any type that satisfies the structural requirements
struct Celsius {
    double value;
    std::string display() const { return std::to_string(value) + "°C"; }
};

// Constrained generic function (= function with a type class constraint)
void printAll(Printable auto const& x) {
    // Only compiles if T satisfies Printable
    std::cout << x.display() << '\n';
}

// std::totally_ordered is the Ord type class in C++20
static_assert(std::totally_ordered<int>);
static_assert(std::totally_ordered<std::string>);
```

### JavaScript

```js
// JavaScript has no native type class mechanism.
// Conventions: Functor, Foldable etc. are represented by Symbol-keyed protocols
// (Fantasy Land spec) or plain duck typing.

// Fantasy Land: a type class defined by a Symbol key
const fl = { map: Symbol("fantasy-land/map") };

// "Instance" for Array: Array already has .map, so wrap it
class Box {
  constructor(value) {
    this.value = value;
  }
  [fl.map](f) {
    return new Box(f(this.value));
  }
}

// Generic function using the protocol (the type class constraint)
function fmap(f, functor) {
  if (typeof functor[fl.map] === "function") return functor[fl.map](f);
  throw new TypeError("Not a Functor");
}

console.log(fmap((x) => x * 2, new Box(21)).value); // 42
// see: sanctuary-js, crocks, fp-ts for full type class hierarchies
```

### Python

```python
from abc import ABC, abstractmethod
from typing import Protocol, TypeVar

T = TypeVar("T")

# Type class as Protocol (structural — duck typing with type-checker support)
class Printable(Protocol):
    def display(self) -> str: ...

# "Instance": any class with a .display() method satisfies Printable
class Temperature:
    def __init__(self, degrees: float) -> None:
        self.degrees = degrees

    def display(self) -> str:
        return f"{self.degrees}°C"

# Constrained generic function (checked by mypy/pyright, not runtime)
def print_all(xs: list[Printable]) -> None:
    for x in xs:
        print(x.display())

print_all([Temperature(20), Temperature(37)])

# Python also has ABC (nominal type class):
from abc import ABC, abstractmethod
class Comparable(ABC):
    @abstractmethod
    def __lt__(self, other: object) -> bool: ...
```

### Haskell

```hs
-- Haskell has native type classes: class declares, instance implements.

-- Declare a type class (the contract)
class Printable a where
    display :: a -> String

-- Instances (implementations for specific types)
instance Printable Int where
    display n = show n

instance Printable Bool where
    display True  = "yes"
    display False = "no"

instance Printable a => Printable [a] where
    display xs = "[" ++ concatMap (\x -> display x ++ ",") xs ++ "]"

-- Constrained generic function — works for any type with a Printable instance
printAll :: Printable a => [a] -> IO ()
printAll = mapM_ (putStrLn . display)

-- The Functor type class (from the standard library)
class Functor f where
    fmap :: (a -> b) -> f a -> f b
    -- Law: fmap id = id
    -- Law: fmap (g . f) = fmap g . fmap f

instance Functor [] where
    fmap = map

instance Functor Maybe where
    fmap _ Nothing  = Nothing
    fmap f (Just x) = Just (f x)
```

### Rust

```rust
// Rust expresses type classes as traits.
// 'impl Trait for Type' is the "instance".

use std::fmt;

// Type class declaration
trait Printable {
    fn display(&self) -> String;
}

// Instances
impl Printable for i32 {
    fn display(&self) -> String { self.to_string() }
}

impl Printable for bool {
    fn display(&self) -> String {
        if *self { "yes".into() } else { "no".into() }
    }
}

// Constrained generic function (monomorphised at compile time — no runtime cost)
fn print_all<T: Printable>(xs: &[T]) {
    for x in xs { println!("{}", x.display()); }
}

print_all(&[1i32, 2, 3]);
print_all(&[true, false]);

// Ord (the ordering type class) is a trait in std:
fn min_val<T: Ord>(a: T, b: T) -> T { if a <= b { a } else { b } }
```

### Go

```go
package main

import "fmt"

// Go uses interfaces for structural ad-hoc polymorphism.
// Any type that implements the methods satisfies the interface — no explicit declaration.

// Type class declaration
type Printable interface {
    Display() string
}

// "Instances": any type with a Display() method
type Celsius float64

func (c Celsius) Display() string { return fmt.Sprintf("%.1f°C", float64(c)) }

type Kelvin float64

func (k Kelvin) Display() string { return fmt.Sprintf("%.1fK", float64(k)) }

// Constrained generic function
func printAll(xs []Printable) {
    for _, x := range xs {
        fmt.Println(x.Display())
    }
}

func main() {
    printAll([]Printable{Celsius(20), Kelvin(293.15)})
}
// Limitation: Go interfaces carry no laws; the contract is structural only.
```
