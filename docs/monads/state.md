# State Monad

The **State monad** models computations that read and write a **shared mutable state** without
actually using mutable variables — state is threaded explicitly as a function argument.

![state monad](../../basics/monad-state.svg)

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
