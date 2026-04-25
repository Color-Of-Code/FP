# State Monad

The **State monad** models computations that read and write a **shared mutable state** without
actually using mutable variables — state is threaded explicitly as a function argument.

![state monad](diagrams/state.svg)

## Type

```text
State s a  =  s -> (a, s)
```

A state computation is a **function** from an input state `s` to a pair of a result `a` and an
output state `s`. `bind` threads the state: the output state of each step becomes the input state of
the next.

## How bind works

```text
bind sa f  =  \s ->
    let (a, s')  = sa(s)   -- run first action with current state
        (b, s'') = f(a)(s') -- run second action with new state
    in  (b, s'')
```

The result value flows down; the state flows sideways through every step.

## Primitive operations

| Operation  | Type         | Description                            |
| ---------- | ------------ | -------------------------------------- |
| `get`      | `State s s`  | read the current state as the result   |
| `put s'`   | `State s ()` | replace the state with `s'`            |
| `modify f` | `State s ()` | apply `f` to the current state         |
| `return a` | `State s a`  | produce `a` without touching the state |

## Key use cases

- Counters and accumulators
- Generating unique IDs
- Interpreter / virtual machine state
- Parser state (position in input stream)
- Any algorithm needing implicit "context"

## Motivation

Without the State monad, every function in a stateful pipeline must accept the current state as an
extra parameter and return the updated state alongside its result. A single wrong variable name
(passing `s1` where `s3` was intended) is a silent bug.

```text
-- Without State monad: state threaded manually through every call
function pipeline(input, s0):
    (tok1, s1) = next_token(input, s0)
    (tok2, s2) = next_token(input, s1)   -- must use s1, not s0!
    (node, s3) = build_node(tok1, tok2, s2)
    (result, s4) = validate(node, s3)    -- must use s3, not s2!
    return (result, s4)
-- Every new step adds two variables (result + state).
-- Using a stale state variable compiles fine but is a logic bug.
```

```text
-- With State monad: state flows automatically; steps see only their result
pipeline(input) = do
    tok1   <- next_token input
    tok2   <- next_token input
    node   <- build_node tok1 tok2
    result <- validate node
    pure result
-- No state variables at call sites; the monad threads them correctly.
```

![state motivation](diagrams/state-motivation.svg)

## Examples

### C\# (threading state manually)

```csharp
// State threading without the monad (explicit)
(int result, int state) Get(int s) => (s, s);
(int result, int state) ModifyAdd(int n, int s) => (0, s + n);

var (_, s1) = ModifyAdd(1, 0);     // state = 1
var (v, _)  = Get(s1);             // result = 1
// v == 1
```

### F\# (state computation expression)

F# computation expressions can model State. Here using explicit state threading, which is the
idiomatic F# approach without a library.

```fsharp
// State as a function: int -> ('a * int)
let get s = (s, s)
let modify f s = ((), f s)
let ret a s = (a, s)

let bind sa f s =
    let a, s' = sa s
    f a s'

// counter: modify (+1), then get
let program = bind (modify (fun s -> s + 1)) (fun _ -> get)
let result, finalState = program 0
// result = 1, finalState = 1

// With FSharpPlus or a custom CE the syntax becomes:
// state {
//     do! modify ((+) 1)
//     do! modify ((+) 1)
//     return! get
// }
```

### Ruby

```ruby
# State as a lambda: ->(s) { [result, new_state] }
get      = ->(s) { [s, s] }
modify_f = ->(f) { ->(s) { [nil, f.call(s)] } }

def bind(sa)
  ->(s) {
    a, s1 = sa.call(s)
    yield(a).call(s1)
  }
end

# counter: modify (+1), then get
program = bind(modify_f[->(s) { s + 1 }]) { get }
result, final_state = program.call(0)
# result = 1, final_state = 1
```

### C++

```cpp
#include <functional>
#include <tuple>

// State<S,A> = std::function<std::pair<A,S>(S)>
auto get = [](int s) { return std::make_pair(s, s); };
auto modify = [](auto f) {
    return [f](int s) { return std::make_pair(0, f(s)); };
};
auto bind = [](auto sa, auto f) {
    return [sa, f](int s) {
        auto [a, s1] = sa(s);
        return f(a)(s1);
    };
};

// counter: modify (+1), then get
auto program = bind(modify([](int s) { return s + 1; }),
                    [](int) { return get; });
auto [result, final_state] = program(0);
// result = 1, final_state = 1
```

### JavaScript

```js
// State monad implementation
const state = (run) => ({
  run,
  bind: (f) =>
    state((s) => {
      const [a, s1] = run(s);
      return f(a).run(s1);
    }),
});

const get = state((s) => [s, s]);
const put = (s) => state((_) => [undefined, s]);
const modify = (f) => state((s) => [undefined, f(s)]);
const returnVal = (a) => state((s) => [a, s]);

// counter: get, add 1, get
const program = get.bind(() => modify((s) => s + 1)).bind(() => get);

const [result, finalState] = program.run(0);
// result = 1, finalState = 1
```

### Python

```py
# State monad as a function wrapper
def bind(sa, f):
    def run(s):
        a, s1 = sa(s)
        return f(a)(s1)
    return run

get      = lambda s: (s, s)
modify_f = lambda f: lambda s: (None, f(s))
ret      = lambda a: lambda s: (a, s)

# counter: modify (+1), then get
program = bind(modify_f(lambda s: s + 1), lambda _: get)
result, final_state = program(0)
# result = 1, final_state = 1
```

### Haskell

```hs
import Control.Monad.State

counter :: State Int Int
counter = do
    modify (+1)   -- increment state
    modify (+1)   -- increment again
    get           -- return current state as result

result :: (Int, Int)
result = runState counter 0
-- (2, 2)  — result value = 2, final state = 2

-- With more operations
program :: State Int String
program = do
    modify (+1)           -- state: 0 -> 1
    n <- get              -- n = 1
    modify (* 10)         -- state: 1 -> 10
    m <- get              -- m = 10
    return (show n ++ " then " ++ show m)

(output, finalState) = runState program 0
-- output = "1 then 10", finalState = 10
```

### Rust

```rust
// Rust models state as a function from state to (result, new_state),
// or via explicit mutable variables.

// Functional state threading: a closure that returns (result, new_state)
fn modify(s: i32, f: impl Fn(i32) -> i32) -> ((), i32) { ((), f(s)) }
fn get_state(s: i32) -> (i32, i32) { (s, s) }

let (_, s1) = modify(0, |s| s + 1);  // state -> 1
let (_, s2) = modify(s1, |s| s + 1); // state -> 2
let (n, _)  = get_state(s2);          // n = 2

// Idiomatic Rust: pass state as a mutable reference or return a new state
struct AppState { counter: i32 }

fn increment(s: &mut AppState) { s.counter += 1; }
fn get_counter(s: &AppState) -> i32 { s.counter }

let mut state = AppState { counter: 0 };
increment(&mut state);
increment(&mut state);
let result = get_counter(&state); // 2
```

### Go

```go
// Go models state explicitly via function arguments or struct mutation.

type AppState struct{ Counter int }

// Functional style: return a new state value
func increment(s AppState) AppState { return AppState{Counter: s.Counter + 1} }
func getCounter(s AppState) int     { return s.Counter }

s := AppState{Counter: 0}
s = increment(s)
s = increment(s)
result := getCounter(s) // 2

// Imperative style: mutate via pointer
func incrementMut(s *AppState) { s.Counter++ }

state := &AppState{Counter: 0}
incrementMut(state)
incrementMut(state)
// state.Counter == 2
```
