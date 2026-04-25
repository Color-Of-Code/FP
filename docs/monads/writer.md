# Writer Monad

The **Writer monad** models computations that produce a result **alongside an accumulated log** (or
any other monoidal side output such as metrics, warnings, or a list of events).

![writer monad](diagrams/writer.svg)

## Type

```text
Writer w a  =  (a, w)
```

A writer computation is a **pair** of a result `a` and a log `w`. `w` must be a **monoid**:

- **empty** — the identity log value (e.g. `""`, `[]`, `0`)
- **append (`<>`)** — combines two log values

## How bind works

```text
bind (a, w1) f  =
    let (b, w2) = f(a)
    in  (b, w1 <> w2)      -- result from f, logs combined
```

Each step produces its own log fragment; `bind` concatenates them in order.

## Primitive operations

| Operation       | Type                           | Description                                         |
| --------------- | ------------------------------ | --------------------------------------------------- |
| `tell w`        | `Writer w ()`                  | append `w` to the log, produce no meaningful result |
| `writer (a, w)` | `Writer w a`                   | construct a writer from a value and an initial log  |
| `listen`        | `Writer w a ⟶ Writer w (a, w)` | expose the accumulated log as part of the result    |
| `runWriter`     | `Writer w a ⟶ (a, w)`          | execute and return the result-log pair              |

## Key use cases

- Audit trails and operation logs
- Collecting warnings or validation messages (without stopping)
- Accumulating metrics or counters alongside a computation
- Tracing the steps of an algorithm

## Motivation

Without the Writer monad, every function must accept the accumulated log as an extra parameter and
return the updated log alongside its result. Forgetting to pass the latest log to the next step
silently discards entries.

```text
-- Without Writer monad: log threaded manually through every call
function pipeline(x):
    (r1, log1) = step1(x,  [])    -- initial empty log
    (r2, log2) = step2(r1, log1)  -- must pass log1, not []
    (r3, log3) = step3(r2, log2)  -- must pass log2, not log1
    return (r3, log3)
-- Every new step needs two variables (result + log).
-- Passing a stale log variable compiles fine but silently drops entries.
```

```text
-- With Writer monad: log accumulated automatically via tell/writer
pipeline = do
    r1 <- step1      -- appends its own log fragment
    r2 <- step2 r1   -- appends its own log fragment
    r3 <- step3 r2   -- appends its own log fragment
    pure r3
-- runWriter returns (r3, combinedLog) with all fragments in order.
```

![writer motivation](diagrams/writer-motivation.svg)

## Examples

### C\#

```csharp
// Writer as a value tuple — manual accumulation
(int Value, List<string> Log) Double(int n) =>
    (n * 2, new List<string> { $"doubled {n}" });

(int Value, List<string> Log) AddOne(int n) =>
    (n + 1, new List<string> { $"added 1 to {n}" });

var (v1, log1) = Double(3);           // (6, ["doubled 3"])
var (v2, log2) = AddOne(v1);          // (7, ["added 1 to 6"])
var finalLog = log1.Concat(log2);     // ["doubled 3", "added 1 to 6"]
// result = 7
```

### F\#

F# models Writer as a tuple `'a * 'w list`. The `@` operator concatenates log lists.

```fsharp
let bind (value, log1) f =
    let value2, log2 = f value
    (value2, log1 @ log2)

let double n = (n * 2, [$"doubled {n}"])
let addOne n = (n + 1, [$"added 1 to {n}"])

let result = bind (double 3) addOne
// (7, ["doubled 3"; "added 1 to 6"])

// With a computation expression (e.g. FSharpPlus writer CE):
// let computation = writer {
//     let! x = writer (3 * 2, ["doubled 3"])
//     let! y = writer (x + 1, [$"added 1 to {x}"])
//     return y
// }
```

### Ruby

```ruby
def bind(wa)
  value, log1 = wa
  value2, log2 = yield(value)
  [value2, log1 + log2]
end

double  = ->(n) { [n * 2, ["doubled #{n}"]] }
add_one = ->(n) { [n + 1, ["added 1 to #{n}"]] }

result = bind(double.call(3), &add_one)
# [7, ["doubled 3", "added 1 to 6"]]
```

### C++

```cpp
#include <vector>
#include <string>

template<typename A>
struct Writer { A value; std::vector<std::string> log; };

auto bind_w = [](auto wa, auto f) {
    auto [value2, log2] = f(wa.value);
    auto combined = wa.log;
    combined.insert(combined.end(), log2.begin(), log2.end());
    return Writer<decltype(value2)>{value2, combined};
};

auto double_ = [](int n) -> Writer<int> {
    return {n * 2, {"doubled " + std::to_string(n)}};
};
auto add_one = [](int n) -> Writer<int> {
    return {n + 1, {"added 1 to " + std::to_string(n)}};
};

auto result = bind_w(double_(3), add_one);
// { value: 7, log: ["doubled 3", "added 1 to 6"] }
```

### JavaScript

```js
// Writer helpers
const writer = (value, log) => ({ value, log });
const tell = (entry) => writer(undefined, [entry]);
const bind = ({ value, log }, f) => {
  const { value: v2, log: l2 } = f(value);
  return writer(v2, [...log, ...l2]);
};

const double = (n) => writer(n * 2, [`doubled ${n}`]);
const addOne = (n) => writer(n + 1, [`added 1 to ${n}`]);

const result = bind(double(3), addOne);
// { value: 7, log: ["doubled 3", "added 1 to 6"] }
```

### Python

```py
def bind(wa, f):
    value, log1 = wa
    value2, log2 = f(value)
    return (value2, log1 + log2)

def double(n):
    return (n * 2, [f"doubled {n}"])

def add_one(n):
    return (n + 1, [f"added 1 to {n}"])

result = bind(double(3), add_one)
# (7, ["doubled 3", "added 1 to 6"])
```

### Haskell

```hs
import Control.Monad.Writer

double :: Int -> Writer [String] Int
double n = do
    tell ["doubled " ++ show n]
    return (n * 2)

addOne :: Int -> Writer [String] Int
addOne n = do
    tell ["added 1 to " ++ show n]
    return (n + 1)

computation :: Writer [String] Int
computation = do
    x <- double 3    -- x = 6,  log = ["doubled 3"]
    y <- addOne x    -- y = 7,  log = ["doubled 3", "added 1 to 6"]
    return y

(result, finalLog) = runWriter computation
-- result   = 7
-- finalLog = ["doubled 3", "added 1 to 6"]
```

### Rust

```rust
// Rust: Writer as an explicit (value, log) pair threaded through functions.

fn double(n: i32) -> (i32, Vec<String>) {
    let result = n * 2;
    (result, vec![format!("doubled {n}")])
}

fn add_one(n: i32) -> (i32, Vec<String>) {
    let result = n + 1;
    (result, vec![format!("added 1 to {n}")])
}

// Chain by threading the value and concatenating the logs
let (x, log1) = double(3);      // (6, ["doubled 3"])
let (y, log2) = add_one(x);     // (7, ["added 1 to 6"])
let full_log: Vec<String> = [log1, log2].concat();
// result = 7, log = ["doubled 3", "added 1 to 6"]
```

### Go

```go
import "fmt"

// Go: Writer as an explicit (value, log) struct.

type Writer[A any] struct {
	Value A
	Log   []string
}

func double(n int) Writer[int] {
	return Writer[int]{
		Value: n * 2,
		Log:   []string{fmt.Sprintf("doubled %d", n)},
	}
}

func addOne(n int) Writer[int] {
	return Writer[int]{
		Value: n + 1,
		Log:   []string{fmt.Sprintf("added 1 to %d", n)},
	}
}

// Chain: thread the value, accumulate the log
w1 := double(3)          // {6, ["doubled 3"]}
w2 := addOne(w1.Value)   // {7, ["added 1 to 6"]}
fullLog := append(w1.Log, w2.Log...)
// result = 7, log = ["doubled 3", "added 1 to 6"]
```
