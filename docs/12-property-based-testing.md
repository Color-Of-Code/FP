# 12. Property-Based Testing

Purity and algebraic laws have a direct practical payoff: if a law holds for _all_ inputs, you can
let a machine generate hundreds of random inputs and check the law automatically. This technique —
**property-based testing** — was pioneered by QuickCheck (Haskell, 1999) and is now available in
every major language.

![property-based testing](12-property-based-testing/property-based-testing.svg)

## Why it matters

Example-based tests verify a handful of hand-picked cases. A property test expresses an invariant
that must hold universally, then delegates input generation to the framework. When a counterexample
is found the framework **shrinks** it to the minimal failing input, making bugs easy to reproduce.

The laws from [11. Semigroup & Monoid](./11-semigroup-monoid.md) are ideal first properties:
associativity and identity hold for _every_ element of the type, so they're straightforward to
encode as generators.

## Anatomy of a property test

1. **Describe a law** as a predicate over generated values:
   `∀ a b c: (a <> b) <> c == a <> (b <> c)`
2. **Register generators** for the types involved (often derived automatically).
3. **Run** — the framework samples the input space, typically 100–500 cases per run.
4. **Shrink** — on failure the framework binary-searches for the smallest counterexample.
5. **Reproduce** — a fixed seed lets you replay the exact sequence of inputs.

```text
-- pseudocode
property "associativity" {
  forAll { a: String, b: String, c: String ->
    (a + b) + c == a + (b + c)
  }
}
```

![property-based testing motivation](12-property-based-testing/property-based-testing-motivation.svg)

## Laws worth testing as properties

| Abstraction | Law                                                  |
| ----------- | ---------------------------------------------------- |
| Semigroup   | `(a <> b) <> c == a <> (b <> c)` (associativity)     |
| Monoid      | `mempty <> a == a` and `a <> mempty == a` (identity) |
| Functor     | `fmap id == id`, `fmap (g∘f) == fmap g ∘ fmap f`     |
| Monad       | left/right identity and associativity of `>>=`       |
| Lens        | get/set round-trips                                  |

## Examples

### C\#

```csharp
// FsCheck works with C# as well as F#
// Install-Package FsCheck

using FsCheck;
using FsCheck.Xunit;

public class StringProperties
{
    [Property]
    public bool AssociativityHolds(string a, string b, string c) =>
        (a + b) + c == a + (b + c);

    [Property]
    public bool IdentityHolds(string s) =>
        "" + s == s && s + "" == s;

    [Property]
    public bool ReverseInvolution(int[] xs) =>
        xs.Reverse().Reverse().SequenceEqual(xs);
}
```

### F\#

```fsharp
// FsCheck — the original .NET port of QuickCheck
// dotnet add package FsCheck

open FsCheck

// Inline property — runs 100 random cases immediately
let associativity (a: string) (b: string) (c: string) =
    (a + b) + c = a + (b + c)

Check.Quick associativity   // Ok, passed 100 tests.

// Full test with custom generator
let genSmallInt = Gen.choose (1, 100)

let monoidIdentity (n: int) =
    n + 0 = n && 0 + n = n

Check.Quick monoidIdentity
```

### Ruby

```ruby
# prop_check gem — pure Ruby property testing
# gem install prop_check

require "prop_check"

include PropCheck::Generators

# Associativity of string concatenation
PropCheck.forall(string, string, string) do |a, b, c|
  ((a + b) + c) == (a + (b + c))
end

# Identity element
PropCheck.forall(string) do |s|
  ("" + s) == s && (s + "") == s
end
```

### C++

```cpp
// RapidCheck — QuickCheck for C++
// https://github.com/emil-e/rapidcheck

#include <rapidcheck.h>
#include <string>

int main() {
    // Associativity of string concatenation
    rc::check("associativity", [](std::string a, std::string b, std::string c) {
        RC_ASSERT((a + b) + c == a + (b + c));
    });

    // Reverse involution
    rc::check("reverse involution", [](std::vector<int> xs) {
        auto rev = xs;
        std::reverse(rev.begin(), rev.end());
        std::reverse(rev.begin(), rev.end());
        RC_ASSERT(rev == xs);
    });

    return 0;
}
```

### JavaScript

```javascript
// fast-check — the de-facto JS/TS property testing library
// npm install fast-check

import fc from "fast-check";

// Associativity of string concatenation
fc.assert(
  fc.property(fc.string(), fc.string(), fc.string(), (a, b, c) => {
    return a + b + c === a + (b + c);
  }),
);

// Monoid identity for arrays
fc.assert(
  fc.property(fc.array(fc.integer()), (xs) => {
    return (
      JSON.stringify([...[], ...xs]) === JSON.stringify(xs) &&
      JSON.stringify([...xs, ...[]]) === JSON.stringify(xs)
    );
  }),
);

// Shrinking: fast-check automatically reduces failing cases to minimal examples
fc.assert(
  fc.property(fc.array(fc.integer(), { minLength: 1 }), (xs) => {
    // intentionally wrong — shows shrinking in action
    return xs.length < 5; // will shrink to [0, 0, 0, 0, 0]
  }),
);
```

### Python

```python
# Hypothesis — property-based testing for Python
# pip install hypothesis

from hypothesis import given, settings
from hypothesis import strategies as st

# Associativity of string concatenation
@given(st.text(), st.text(), st.text())
def test_associativity(a, b, c):
    assert (a + b) + c == a + (b + c)

# Monoid identity
@given(st.text())
def test_identity(s):
    assert "" + s == s
    assert s + "" == s

# Reverse involution — Hypothesis will try hundreds of lists
@given(st.lists(st.integers()))
def test_reverse_involution(xs):
    assert list(reversed(list(reversed(xs)))) == xs

# Run explicitly (pytest discovers @given tests automatically)
test_associativity()
test_identity()
test_reverse_involution()
```

### Haskell

```haskell
-- QuickCheck — the original property-based testing library (1999)
-- cabal install QuickCheck  /  stack add-package QuickCheck

import Test.QuickCheck

-- Monoid laws for String
prop_assoc :: String -> String -> String -> Bool
prop_assoc a b c = (a <> b) <> c == a <> (b <> c)

prop_leftId :: String -> Bool
prop_leftId s = mempty <> s == s

prop_rightId :: String -> Bool
prop_rightId s = s <> mempty == s

-- Functor identity law for Maybe
prop_fmapId :: Maybe Int -> Bool
prop_fmapId mx = fmap id mx == mx

main :: IO ()
main = do
    quickCheck prop_assoc       -- +++ OK, passed 100 tests.
    quickCheck prop_leftId
    quickCheck prop_rightId
    quickCheck prop_fmapId
    -- Verbose mode shows all generated inputs:
    verboseCheck prop_assoc
```

### Rust

```rust
// proptest — property-based testing for Rust
// cargo add proptest

use proptest::prelude::*;

proptest! {
    // Associativity of string concatenation
    #[test]
    fn associativity(a in ".*", b in ".*", c in ".*") {
        let lhs = format!("{}{}", format!("{}{}", a, b), c);
        let rhs = format!("{}{}", a, format!("{}{}", b, c));
        prop_assert_eq!(lhs, rhs);
    }

    // Reverse involution for Vec<i32>
    #[test]
    fn reverse_involution(xs in prop::collection::vec(any::<i32>(), 0..100)) {
        let mut rev = xs.clone();
        rev.reverse();
        rev.reverse();
        prop_assert_eq!(xs, rev);
    }

    // Monoid identity for Vec
    #[test]
    fn vec_identity(xs in prop::collection::vec(any::<i32>(), 0..50)) {
        let mut with_empty = Vec::new();
        with_empty.extend(xs.iter().cloned());
        prop_assert_eq!(&xs, &with_empty);
    }
}
```

### Go

```go
// Go standard library testing/quick — simple property testing built-in
// For richer shrinking, use github.com/leanovate/gopter

package main

import (
    "strings"
    "testing"
    "testing/quick"
)

// Associativity of string concatenation
func TestAssociativity(t *testing.T) {
    f := func(a, b, c string) bool {
        return (a+b)+c == a+(b+c)
    }
    if err := quick.Check(f, nil); err != nil {
        t.Error(err)
    }
}

// Reverse involution for slices (using gopter for richer shrinking)
// go get github.com/leanovate/gopter

import (
    "github.com/leanovate/gopter"
    "github.com/leanovate/gopter/gen"
    "github.com/leanovate/gopter/prop"
)

func TestReverseInvolution(t *testing.T) {
    properties := gopter.NewProperties(nil)

    properties.Property("reverse involution", prop.ForAll(
        func(xs []int) bool {
            rev := make([]int, len(xs))
            copy(rev, xs)
            // reverse twice
            for i, j := 0, len(rev)-1; i < j; i, j = i+1, j-1 {
                rev[i], rev[j] = rev[j], rev[i]
            }
            for i, j := 0, len(rev)-1; i < j; i, j = i+1, j-1 {
                rev[i], rev[j] = rev[j], rev[i]
            }
            return strings.Join(intSliceToStr(rev), ",") ==
                strings.Join(intSliceToStr(xs), ",")
        },
        gen.SliceOf(gen.Int()),
    ))

    properties.TestingRun(t)
}
```

## Key points

| Concept   | Description                                                              |
| --------- | ------------------------------------------------------------------------ |
| Property  | A universally-quantified predicate: `∀ x: invariant(x)`                  |
| Generator | Produces random values of the required type; composable and shrinkable   |
| Shrinking | On failure, reduces inputs to the smallest counterexample automatically  |
| Seed      | Fixed integer that reproduces the exact sequence of inputs               |
| Law tests | Algebraic laws (associativity, identity, functor laws) are ideal targets |

## See also

- [11. Semigroup & Monoid](./11-semigroup-monoid.md) — the laws you test with property tests
- [13. Functor](./13-functor.md) — functor identity/composition are classic property tests
- [19. Monad](./19-monad.md) — monad laws are the most important properties to verify
