# 2. Immutability

**Immutability** means that a value, once created, can never be changed. An operation that appears
to "update" a value instead returns a **new value** with the desired change, while the original
remains intact. This is the natural consequence of [1. Function](./01-function.md) purity: if a
function's output depends only on its inputs, it cannot silently alter data that other code still
holds.

![immutability and structural sharing](02-immutability/immutability.svg)

## Core properties

| Property                     | What it means                                                                         |
| ---------------------------- | ------------------------------------------------------------------------------------- |
| **No in-place mutation**     | Every "update" produces a fresh value; the original is untouched                      |
| **Referential transparency** | A name always refers to the same value; you can substitute it for its definition      |
| **Safe sharing**             | Multiple parts of a program can hold the same value without coordination              |
| **Structural sharing**       | Persistent data structures reuse unchanged subtrees; memory cost is often logarithmic |
| **Free undo / history**      | Old versions are never destroyed; snapshots come for free                             |

## Persistent data structures

Naive immutability would copy the entire structure on every change — O(n) for every "update". A
**persistent data structure** avoids this by sharing the parts that did not change:

```text
-- Prepend to a linked list: O(1), no copy
xs = [1, 2, 3]
ys = 0 : xs        -- ys = [0, 1, 2, 3]; xs is unchanged
                   -- ys and xs share the tail [1, 2, 3]

-- Update a balanced tree: O(log n) path copied, rest shared
t  = insert 42 emptyTree
t' = insert 99 t   -- only the path from root to 99 is new
                   -- t is still valid, t and t' share most nodes
```

## Connection to purity

A pure function cannot cause a mutation side effect, so it naturally operates on immutable values.
Immutability, in turn, makes purity checkable: if values cannot change, there is no hidden mutable
state for a function to observe or alter. The two concepts reinforce each other.

## Motivation

```text
-- mutable update: the original is destroyed

user  = { name = "Alice", age = 30 }
user.age = 31                -- user now has age 31

-- all code holding a reference to user now sees the new age
-- concurrent readers may observe a half-updated state
-- the old value is gone
```

```text
-- immutable update: a new value is returned

user  = { name = "Alice", age = 30 }
older = { user | age = 31 } -- a new record; user is unchanged

-- user still has age 30
-- older has age 31
-- both versions coexist; no coordination needed for safe concurrent reads
```

![immutability motivation](02-immutability/immutability-motivation.svg)

## Examples

### C\#

```csharp
// records are immutable by default; 'with' produces a new record
record User(string Name, int Age);

var alice = new User("Alice", 30);
var older = alice with { Age = 31 };   // new record; alice unchanged

// Immutable list via ImmutableList<T> (.NET)
using System.Collections.Immutable;

var xs = ImmutableList.Create(1, 2, 3);
var ys = xs.Insert(0, 0);              // new list; xs unchanged
// ys = [0, 1, 2, 3],  xs = [1, 2, 3]
```

### F\#

```fsharp
// Records are immutable; copy-and-update creates a new record
type User = { Name: string; Age: int }

let alice = { Name = "Alice"; Age = 30 }
let older = { alice with Age = 31 }   // new record; alice unchanged

// Lists are persistent singly-linked lists
let xs = [1; 2; 3]
let ys = 0 :: xs    // prepend O(1); xs unchanged
// ys = [0; 1; 2; 3],  xs = [1; 2; 3]
```

### Ruby

```ruby
# Freeze an object to enforce immutability at runtime
user = { name: "Alice", age: 30 }.freeze

# "Update" by creating a new hash
older = user.merge(age: 31)   # new hash; user unchanged

# Ruby strings are mutable by default; use frozen string literals
# frozen_string_literal: true
name = "Alice".freeze
# name << " Smith"  => FrozenError
```

### C++

```cpp
#include <string>

// Immutable value type: use const references and value semantics
struct User {
    const std::string name;
    const int age;
};

// "Update" by constructing a new value
User alice{"Alice", 30};
User older{alice.name, alice.age + 1};  // new object; alice unchanged

// std::string is a value type; assignment copies, not shares
std::string s1 = "hello";
std::string s2 = s1;   // copy; s1 unchanged after s2 modification
```

### JavaScript

```js
// Object.freeze prevents mutation at runtime
const user = Object.freeze({ name: "Alice", age: 30 });

// Spread creates a new object; original unchanged
const older = { ...user, age: 31 };

// Immutable arrays via spread
const xs = Object.freeze([1, 2, 3]);
const ys = [0, ...xs]; // new array; xs unchanged
// see: Immer, Immutable.js for persistent data structures
```

### Python

```python
from dataclasses import dataclass, replace

@dataclass(frozen=True)       # frozen=True makes all fields read-only
class User:
    name: str
    age: int

alice = User("Alice", 30)
older = replace(alice, age=31)  # new instance; alice unchanged

# Tuples are immutable; lists are mutable
point = (1, 2)                  # tuple — cannot be changed
# point[0] = 9                  # TypeError
xs = (1, 2, 3)
ys = (0,) + xs                  # new tuple; xs unchanged
```

### Haskell

```hs
-- All values are immutable by default in Haskell

data User = User { name :: String, age :: Int } deriving Show

alice :: User
alice = User { name = "Alice", age = 30 }

-- Record update syntax returns a new value; alice is unchanged
older :: User
older = alice { age = 31 }

-- Persistent list: prepend is O(1), tail is shared
xs :: [Int]
xs = [1, 2, 3]

ys :: [Int]
ys = 0 : xs    -- [0, 1, 2, 3]; xs still [1, 2, 3]
```

### Rust

```rust
// Structs are immutable by default; rebind to "update"
#[derive(Debug, Clone)]
struct User {
    name: String,
    age: u32,
}

let alice = User { name: "Alice".to_string(), age: 30 };

// Struct update syntax creates a new owned value
let older = User { age: 31, ..alice.clone() };   // alice unchanged

// im::Vector (im crate) — persistent, structurally shared
// use im::Vector;
// let xs = vector![1, 2, 3];
// let ys = xs.clone().push_front(0);   // O(log n); xs unchanged
// see: im crate for persistent collections
```

### Go

```go
package main

// Structs are copied on assignment — value semantics enforce immutability
type User struct {
    Name string
    Age  int
}

alice := User{Name: "Alice", Age: 30}

// "Update": copy the struct, change a field — original untouched
older := alice          // copy
older.Age = 31          // modifies only older; alice.Age still 30

// Slices are reference types; use copy() to avoid shared backing array
xs := []int{1, 2, 3}
ys := make([]int, len(xs)+1)
ys[0] = 0
copy(ys[1:], xs)        // xs unchanged
// see: github.com/tobyjsullivan/immer for persistent collections
```
