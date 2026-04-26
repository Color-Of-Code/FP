# 21. Monad Transformers

> **In plain terms:** A monad transformer stacks one effect on top of another — like layering
> middleware — so a single type can carry error handling, config access, and logging simultaneously
> without manual wiring.

A **monad transformer** `T` converts any monad `M` into a new monad `T M` that adds one extra effect
on top. Stacking several transformers produces a **transformer stack**: a single type that carries
multiple effects simultaneously.

![transformer stack](diagrams/transformer.svg)

> Part of the **learning track**. For a comparison of Monad Transformers, Free Monads, and Algebraic
> Effects side-by-side, see [22. Composing Effects](./22-effects.md).

## The problem transformers solve

A single monad handles one effect cleanly. But a realistic function often needs several at once —
for example: it may fail early (`Maybe`/`Either`), reads shared configuration (`Reader`), and
accumulates a log (`Writer`). Naively nesting these types produces a deeply wrapped type that
requires manual unwrapping at every step.

Transformers solve this by providing a standard way to layer effects. Each transformer adds exactly
one effect and forwards all others to the monad below it.

See [22. Composing Effects](./22-effects.md) for a comparison of Monad Transformers, Free Monads,
and Algebraic Effects.

## Type

```text
-- A transformer T applied to base monad M adds one effect
newtype T M a = T (M (inner a))

-- Common stacking pattern: read config, may fail, log messages
type App a = ReaderT Config (ExceptT AppError (Writer Log)) a
--           ^ reads Config  ^ may fail          ^ accumulates Log

-- Unwinding the stack after running (inner-to-outer)
runApp cfg m = runWriter (runExceptT (runReaderT m cfg))
```

## Common transformers

| Transformer     | Effect added           | Key operations                      |
| --------------- | ---------------------- | ----------------------------------- |
| `MaybeT M a`    | optional value         | `MaybeT (M (Maybe a))`              |
| `ExceptT e M a` | failure with error `e` | `throwE`, `catchE`                  |
| `StateT s M a`  | read/write state `s`   | `get`, `put`, `modify`              |
| `ReaderT r M a` | read-only environment  | `ask`, `asks`, `local`              |
| `WriterT w M a` | accumulated output `w` | `tell`                              |
| `IdentityT M a` | no extra effect (base) | used as a stack base during testing |

## How `lift` works

```text
lift :: (MonadTrans T) => M a -> T M a
```

`lift` promotes an action from the layer below into the current layer. In a stack of depth _n_,
reaching the `k`-th layer requires `n - k` applications of `lift`.

```text
-- Stack: ExceptT on top of StateT on top of IO
type App a = ExceptT Err (StateT St IO) a

-- Reaching IO (deepest layer): lift twice
doIO :: IO () -> App ()
doIO action = lift (lift action)   -- or: liftIO action

-- Reaching StateT (middle layer): lift once
getState :: App St
getState = lift get
```

`liftIO` is a typeclass shortcut — it lifts any `IO` action to the top of the stack regardless of
how many transformer layers sit above it.

## Stack semantics and layer order

The order of layers in a transformer stack determines semantics when effects interact:

| Stack                     | Failure behaviour                            |
| ------------------------- | -------------------------------------------- |
| `ExceptT (StateT M)`      | State is **preserved** on failure            |
| `StateT (ExceptT M)`      | State is **discarded** on failure            |
| `ReaderT r (ExceptT e M)` | Config flows through; failure short-circuits |
| `WriterT w (ExceptT e M)` | Log is **discarded** on failure              |
| `ExceptT e (WriterT w M)` | Log is **preserved** on failure              |

Choosing the wrong order is a silent semantic bug — the types compile but the behaviour differs.

## Key use cases

- Web handlers: `ReaderT Config (ExceptT HttpError IO)` — read config, fail with HTTP errors, do IO
- CLI tools: `ReaderT Opts (StateT Progress IO)` — parse opts once, track progress, print output
- Game loop: `StateT World (WriterT Events IO)` — update world, emit events, perform IO
- Parsers: `StateT Input (ExceptT ParseError Identity)` — consume input, fail with a message

## Motivation

Without transformers, each function that needs multiple effects manually threads every piece of
state or context as an extra argument, and manually checks for failure at every step.

```text
-- Without transformers: error + state + log threaded manually
function process(input, state, log):
    r1 = step1(input)
    if r1 == null: return (Error, state, log)
    new_state = update_state(state, r1)
    new_log   = log ++ ["step1 done"]
    r2 = step2(r1, new_state)
    if r2 == null: return (Error, new_state, new_log)
    return (r2, new_state, new_log ++ ["step2 done"])
-- Three pieces of context threaded manually; adding a fourth touches every function.
```

```text
-- With transformers: bind handles threading; effects compose automatically
process = do
    r1 <- step1            -- ExceptT handles early exit
    logMsg "step1 done"    -- WriterT accumulates log
    r2 <- step2 r1         -- ReaderT provides config
    logMsg "step2 done"
    return r2
```

![transformer motivation](diagrams/transformer-motivation.svg)

## Examples

All examples build the same **two-layer stack**: a computation that may fail with an error string
and accumulates a log alongside its result. The stack is `ExceptT String (Writer [String])`.

### C\#

C# has no monad transformers. The equivalent is achieved by manually threading `(result, log)` and
propagating errors with early returns or exceptions.

```csharp
using System.Collections.Generic;
using System.Linq;

// Manual two-layer stack: Result<T> + log
record App<T>(T? Value, string? Error, List<string> Log)
{
    public bool IsError => Error is not null;
}

static class AppM
{
    public static App<T> Pure<T>(T value) =>
        new(value, null, new List<string>());

    public static App<B> Bind<A, B>(App<A> m, Func<A, App<B>> f)
    {
        if (m.IsError) return new(default, m.Error, m.Log);
        var next = f(m.Value!);
        return new(next.Value, next.Error, m.Log.Concat(next.Log).ToList());
    }

    public static App<Unit> LogMsg(string msg) =>
        new(new Unit(), null, new List<string> { msg });

    public static App<T> Fail<T>(string error) =>
        new(default, error, new List<string>());
}

record Unit;

// Build the computation manually (no syntactic sugar for monadic bind)
var result = AppM.Bind(AppM.Pure(10), x =>
    AppM.Bind(AppM.LogMsg("got x"), _ =>
        AppM.Bind(AppM.Pure(x * 2), y =>
            y > 25
                ? AppM.Fail<int>("too large")
                : AppM.Bind(AppM.LogMsg($"result: {y}"), _ => AppM.Pure(y)))));
// result.Value = 20, result.Log = ["got x", "result: 20"]
```

### F\#

F# achieves the same layering with a **custom computation expression** that threads state
explicitly. This mirrors the transformer stack without using typeclasses.

```fsharp
type Log      = string list
type AppError = string

// Two-layer stack: error + log
// App<'a> = Log -> Result<'a * Log, AppError>
type App<'a> = Log -> Result<'a * Log, AppError>

module App =
    let pure x : App<'a> = fun log -> Ok(x, log)

    let bind (m: App<'a>) (f: 'a -> App<'b>) : App<'b> =
        fun log ->
            match m log with
            | Error e          -> Error e
            | Ok(a, log')      -> f a log'

    let logMsg msg : App<unit> = fun log -> Ok((), log @ [msg])
    let fail err   : App<'a>   = fun _   -> Error err
    let run m = m []

type AppBuilder() =
    member _.Return x   = App.pure x
    member _.Bind(m, f) = App.bind m f
    member _.ReturnFrom m = m

let app = AppBuilder()

let program = app {
    let! x = App.pure 10
    do!  App.logMsg "got x"
    let  y = x * 2
    if y > 25 then return! App.fail "too large"
    do!  App.logMsg (sprintf "result: %d" y)
    return y
}

// App.run program => Ok(20, ["got x"; "result: 20"])
```

### Ruby

```ruby
# Manual two-layer stack: error + log as a plain Ruby object

class App
  attr_reader :value, :error, :log

  def initialize(value: nil, error: nil, log: [])
    @value = value
    @error = error
    @log   = log
  end

  def self.pure(value)  = new(value: value)
  def self.fail(msg)    = new(error: msg)
  def self.log_msg(msg) = new(value: nil, log: [msg])

  def bind(&f)
    return self if @error
    result = f.call(@value)
    App.new(
      value: result.value,
      error: result.error,
      log:   @log + result.log
    )
  end
end

result = App.pure(10)
  .bind { |x|   App.log_msg("got x").bind { App.pure(x) } }
  .bind { |x|   y = x * 2
                y > 25 ? App.fail("too large") : App.pure(y) }
  .bind { |y|   App.log_msg("result: #{y}").bind { App.pure(y) } }
# result.value = 20, result.log = ["got x", "result: 20"]
```

### C++

```cpp
#include <string>
#include <vector>
#include <optional>
#include <variant>
#include <functional>

// Two-layer stack: optional error + log
template <typename T>
struct App {
    std::optional<T> value;
    std::optional<std::string> error;
    std::vector<std::string> log;
};

template <typename T>
App<T> pure(T v) { return {v, std::nullopt, {}}; }

template <typename T>
App<T> fail(std::string err) { return {std::nullopt, err, {}}; }

App<std::nullptr_t> logMsg(std::string msg) { return {nullptr, std::nullopt, {msg}}; }

template <typename A, typename B>
App<B> bind(App<A> m, std::function<App<B>(A)> f) {
    if (m.error) return {std::nullopt, m.error, m.log};
    auto next = f(*m.value);
    auto combined = m.log;
    combined.insert(combined.end(), next.log.begin(), next.log.end());
    return {next.value, next.error, combined};
}

auto result =
    bind<int, int>(pure(10), [](int x) {
        return bind<std::nullptr_t, int>(logMsg("got x"), [x](auto) {
            int y = x * 2;
            if (y > 25) return fail<int>("too large");
            return bind<std::nullptr_t, int>(logMsg("result: " + std::to_string(y)), [y](auto) {
                return pure(y);
            });
        });
    });
// result.value = 20, result.log = {"got x", "result: 20"}
```

### JavaScript

```js
// Two-layer stack: error + log

class App {
  constructor({ value = null, error = null, log = [] } = {}) {
    this.value = value;
    this.error = error;
    this.log = log;
  }

  static pure(value) {
    return new App({ value });
  }
  static fail(error) {
    return new App({ error });
  }
  static logMsg(msg) {
    return new App({ log: [msg] });
  }

  bind(f) {
    if (this.error !== null) return this;
    const next = f(this.value);
    return new App({
      value: next.value,
      error: next.error,
      log: [...this.log, ...next.log],
    });
  }
}

const result = App.pure(10)
  .bind((x) => App.logMsg("got x").bind(() => App.pure(x)))
  .bind((x) => {
    const y = x * 2;
    return y > 25 ? App.fail("too large") : App.pure(y);
  })
  .bind((y) => App.logMsg(`result: ${y}`).bind(() => App.pure(y)));
// result.value = 20, result.log = ["got x", "result: 20"]
```

### Python

```py
from dataclasses import dataclass, field
from typing import Generic, TypeVar, Callable, Optional

A = TypeVar('A')
B = TypeVar('B')

@dataclass
class App(Generic[A]):
    value: Optional[A] = None
    error: Optional[str] = None
    log: list[str] = field(default_factory=list)

    @staticmethod
    def pure(value): return App(value=value)

    @staticmethod
    def fail(error): return App(error=error)

    @staticmethod
    def log_msg(msg): return App(log=[msg])

    def bind(self, f: Callable):
        if self.error is not None:
            return self
        next_ = f(self.value)
        return App(
            value=next_.value,
            error=next_.error,
            log=self.log + next_.log,
        )

result = (
    App.pure(10)
    .bind(lambda x: App.log_msg("got x").bind(lambda _: App.pure(x)))
    .bind(lambda x: App.fail("too large") if x * 2 > 25 else App.pure(x * 2))
    .bind(lambda y: App.log_msg(f"result: {y}").bind(lambda _: App.pure(y)))
)
# result.value = 20, result.log = ["got x", "result: 20"]
```

### Haskell

Haskell has full monad transformer support via the `transformers` or `mtl` library. The `do` block
reads like sequential imperative code while the type encodes every effect present.

```hs
import Control.Monad.Trans.Except (ExceptT, throwE, runExceptT)
import Control.Monad.Trans.Writer (WriterT, tell, runWriterT)
import Control.Monad.Identity     (Identity, runIdentity)
import Control.Monad.Trans.Class  (lift)

-- Two-layer stack: error + log (Identity as the base monad)
type App a = ExceptT String (WriterT [String] Identity) a

runApp :: App a -> (Either String a, [String])
runApp m = runIdentity (runWriterT (runExceptT m))

logMsg :: String -> App ()
logMsg msg = lift (tell [msg])   -- lift once to reach WriterT

program :: App Int
program = do
    let x = 10
    logMsg "got x"
    let y = x * 2
    if y > 25
        then throwE "too large"
        else do
            logMsg ("result: " ++ show y)
            return y

-- runApp program => (Right 20, ["got x", "result: 20"])

-- ---- with mtl typeclasses: no explicit lift needed ----
-- type App' a = ExceptT String (WriterT [String] Identity) a
-- (MonadError String m, MonadWriter [String] m) => m Int
-- These constraints resolve automatically to the right layer.
```

### Rust

```rust
// Rust has no monad transformers. The equivalent pattern uses Result<T, E>
// with an explicit log accumulated alongside. This is the common "App" type
// used in Rust applications that need error handling + structured output.

type Log = Vec<String>;

// Manual two-layer stack: Result + log threaded as a pair
struct App<T> {
    value: Result<T, String>,
    log:   Log,
}

impl<T> App<T> {
    fn pure(value: T) -> Self { App { value: Ok(value), log: vec![] } }
    fn fail(err: &str)  -> Self { App { value: Err(err.to_string()), log: vec![] } }
    fn log_msg(msg: &str) -> App<()> { App { value: Ok(()), log: vec![msg.to_string()] } }

    fn bind<B>(self, f: impl FnOnce(T) -> App<B>) -> App<B> {
        match self.value {
            Err(e) => App { value: Err(e), log: self.log },
            Ok(a)  => {
                let next = f(a);
                let mut log = self.log;
                log.extend(next.log);
                App { value: next.value, log }
            }
        }
    }
}

// Chained manually (no do-notation)
let result = App::pure(10)
    .bind(|x| App::<i32>::log_msg("got x").bind(move |_| App::pure(x)))
    .bind(|x| {
        let y = x * 2;
        if y > 25 { App::fail("too large") } else { App::pure(y) }
    })
    .bind(|y| App::<i32>::log_msg(&format!("result: {y}")).bind(move |_| App::pure(y)));
// result.value = Ok(20), result.log = ["got x", "result: 20"]

// For richer stacks, crates like `frunk` or `im` are available.
// The most idiomatic Rust approach for larger programs is to use
// the `anyhow` / `thiserror` crates for errors and pass log/config explicitly.
```

### Go

```go
// Go has no monad transformers. The equivalent is explicit error propagation
// and passing a context / log collector to functions.

import "fmt"

type Log []string

// Two-layer stack: (value, error) + accumulated log
type App[T any] struct {
	Value T
	Err   error
	Log   Log
}

func Pure[T any](v T) App[T] { return App[T]{Value: v} }

func Fail[T any](msg string) App[T] {
	var zero T
	return App[T]{Value: zero, Err: fmt.Errorf("%s", msg)}
}

func LogMsg(msg string) App[struct{}] {
	return App[struct{}]{Log: Log{msg}}
}

func Bind[A, B any](m App[A], f func(A) App[B]) App[B] {
	if m.Err != nil {
		var zero B
		return App[B]{Value: zero, Err: m.Err, Log: m.Log}
	}
	next := f(m.Value)
	return App[B]{
		Value: next.Value,
		Err:   next.Err,
		Log:   append(m.Log, next.Log...),
	}
}

// Running the stack
x := Pure(10)
step1 := Bind(x, func(n int) App[int] {
	logged := LogMsg("got x")
	return Bind(logged, func(_ struct{}) App[int] { return Pure(n) })
})
step2 := Bind(step1, func(n int) App[int] {
	y := n * 2
	if y > 25 {
		return Fail[int]("too large")
	}
	return Pure(y)
})
result := Bind(step2, func(y int) App[int] {
	logged := LogMsg(fmt.Sprintf("result: %d", y))
	return Bind(logged, func(_ struct{}) App[int] { return Pure(y) })
})
// result.Value = 20, result.Log = ["got x", "result: 20"]

// Idiomatic Go: pass *slog.Logger + context.Context to each function;
// return (value, error); let the caller accumulate logs.
```
