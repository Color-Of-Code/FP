# 23. Tagless Final

> **In plain terms:** Tagless Final is programming against an abstract capability interface `F[_]`
> so you can swap the concrete backend — real I/O in production, a pure in-memory stub in tests — by
> passing a different `F` at the call site.

**Tagless Final** (also called _Finally Tagless_ or _MTL-style_) is an approach to effect
abstraction where a program is written as a **typeclass-polymorphic function** over an abstract
effect type `F[_]`, rather than as a concrete free monad AST. Different interpreters simply pick
different `F`.

![tagless final](23-tagless-final/tagless-final.svg)

The name comes from Carette, Kiselyov & Shan (2009): _initial_ encodings use ADTs/GADTs (tagged
unions); _final_ encodings use typeclasses. Removing the "tags" (the ADT constructors) gives
_tagless final_.

## Core pattern

```text
-- 1. Define an algebra as a typeclass (one per effect domain)
trait Console[F[_]]:
    def readLine: F[String]
    def writeLine(s: String): F[Unit]

trait KVStore[F[_]]:
    def get(key: String): F[Option[String]]
    def put(key: String, value: String): F[Unit]

-- 2. Write programs that are polymorphic in F
def program[F[_]: Monad: Console: KVStore]: F[Unit] =
    for
        name <- Console[F].readLine
        _    <- KVStore[F].put("last", name)
        _    <- Console[F].writeLine(s"Stored $name")
    yield ()

-- 3. Choose an interpreter by picking F
program[IO]              // production: real console + real DB
program[StateT[Log, Id]] // test: log-collecting pure interpreter
```

## Comparison with Free Monad

|                       | Free Monad                           | Tagless Final                           |
| --------------------- | ------------------------------------ | --------------------------------------- |
| **Encoding**          | Initial — ADT/GADT representing ops  | Final — typeclass/interface             |
| **Interpretation**    | Pattern-match on the AST at run-time | Instantiate `F` at compile time         |
| **Performance**       | Heap allocation per bind step        | Monomorphised; near-zero overhead       |
| **Introspection**     | Yes — inspect/transform the AST      | No — the program is opaque              |
| **Composing effects** | Coproduct of functors                | Multiple typeclass constraints on `F`   |
| **Mocking / testing** | Swap the interpreter function        | Provide a pure `F` instance             |
| **Boilerplate**       | Algebra functor + smart constructors | Typeclass + instances                   |
| **Most popular in**   | Haskell (freer-simple, polysemy)     | Scala (cats-effect, ZIO), Haskell (MTL) |

## Laws and guarantees

Because the program is parametric in `F`, it can only use the operations the algebra exposes. This
is a form of **capability-based design**: the type signature lists exactly which effects the
function needs, and the compiler rejects any use of unlisted capabilities.

```text
-- This function can ONLY use Console — it has no access to KVStore or IO
def greet[F[_]: Monad: Console](name: String): F[Unit] =
    Console[F].writeLine(s"Hello, $name")
```

## Motivation

![tagless final motivation](23-tagless-final/tagless-final-motivation.svg)

Without tagless final, adding a new effect to a concrete implementation touches every call site.
With tagless final, programs are written once against an algebra; the effect stack is an
implementation detail chosen at the application's outermost layer.

## Examples

### C\#

```csharp
// Tagless final via generic interfaces in C#
// F<A> represented as the interface itself (simulated HKT)
// A simpler form: program against an interface, inject the implementation

public interface IConsole<F>
{
    F ReadLine();
    F WriteLine(string s);
}

// Production interpreter
public class IoConsole : IConsole<Task<string>>
{
    public Task<string> ReadLine()    => Task.Run(Console.ReadLine)!;
    public Task<string> WriteLine(string s) { Console.WriteLine(s); return Task.FromResult(s); }
}

// Test interpreter — records calls
public class FakeConsole : IConsole<string>
{
    public List<string> Output { get; } = new();
    public string ReadLine()         => "test-input";
    public string WriteLine(string s) { Output.Add(s); return s; }
}

// Program is generic over the interpreter
void Greet<F>(IConsole<F> console, string name) =>
    console.WriteLine($"Hello, {name}");
```

### F\#

```fsharp
// F# Computation Expressions as tagless final interpreters
// Define the algebra via a record of functions (simulated typeclass)

type ConsoleAlgebra<'F> = {
    ReadLine  : unit -> 'F
    WriteLine : string -> 'F
}

// Production interpreter
let ioConsole: ConsoleAlgebra<Async<string option>> = {
    ReadLine  = fun () -> async { return System.Console.ReadLine() |> Option.ofObj }
    WriteLine = fun s  -> async { System.Console.WriteLine(s); return Some s }
}

// Test interpreter — captures output
let testConsole (log: System.Collections.Generic.List<string>) : ConsoleAlgebra<string> = {
    ReadLine  = fun () -> "test-input"
    WriteLine = fun s  -> log.Add(s); s
}

// Program — polymorphic in 'F via the algebra record
let greet (console: ConsoleAlgebra<'F>) (name: string) : 'F =
    console.WriteLine $"Hello, {name}"
```

### Ruby

```ruby
# Tagless final in Ruby via dependency injection and duck typing
# Ruby's dynamic typing gives "free" polymorphism — just inject the object

module Console
  def read_line   = raise NotImplementedError
  def write_line(_) = raise NotImplementedError
end

# Production
class IoConsole
  include Console
  def read_line     = gets&.chomp
  def write_line(s) = puts(s)
end

# Test — pure, captures output
class FakeConsole
  include Console
  attr_reader :output
  def initialize = (@output = [])
  def read_line   = "test-input"
  def write_line(s) = (@output << s)
end

# Program — polymorphic via duck typing
def greet(console, name)
  console.write_line("Hello, #{name}")
end

greet(IoConsole.new, "World")          # production
fake = FakeConsole.new
greet(fake, "World")                   # test
puts fake.output.inspect               # ["Hello, World"]
```

### C++

```cpp
// Tagless final in C++ via template parameters (static dispatch, no heap)
#include <iostream>
#include <string>
#include <vector>

// "Algebra" concept (C++20)
template <typename T>
concept ConsoleAlgebra = requires(T t, std::string s) {
    { t.read_line()   } -> std::same_as<std::string>;
    { t.write_line(s) } -> std::same_as<void>;
};

// Production interpreter
struct IoConsole {
    std::string read_line()            { std::string s; std::getline(std::cin, s); return s; }
    void        write_line(const std::string& s) { std::cout << s << '\n'; }
};

// Test interpreter
struct FakeConsole {
    std::vector<std::string> output;
    std::string read_line()            { return "test-input"; }
    void        write_line(const std::string& s) { output.push_back(s); }
};

// Program is a template — instantiated at compile time (zero overhead)
template <ConsoleAlgebra C>
void greet(C& console, const std::string& name) {
    console.write_line("Hello, " + name);
}

// Swap interpreter at compile time, not run time
IoConsole  io;   greet(io,  "World");  // production
FakeConsole fc;  greet(fc, "World");  // test
```

### JavaScript

```javascript
// Tagless final in JavaScript via plain objects as algebras
// No higher-kinded types needed — JS Promises/arrays act as F

// Algebra: an object with the required operations
const ioConsole = {
  readLine: () =>
    new Promise((resolve) => process.stdin.once("data", (d) => resolve(d.toString().trim()))),
  writeLine: (s) => Promise.resolve(console.log(s)),
};

const fakeConsole = (log = []) => ({
  readLine: () => Promise.resolve("test-input"),
  writeLine: (s) => {
    log.push(s);
    return Promise.resolve();
  },
});

// Program is polymorphic — works with any algebra object
async function greet(console, name) {
  await console.writeLine(`Hello, ${name}`);
}

// Switch interpreter by injecting a different object
await greet(ioConsole, "World");

const log = [];
await greet(fakeConsole(log), "World");
console.log(log); // ['Hello, World']
```

### Python

```python
# Tagless final in Python via Protocol (structural typing) and dependency injection
from __future__ import annotations
from typing import Protocol, TypeVar
from dataclasses import dataclass, field

# Algebra as a Protocol (structural subtyping — no explicit inheritance needed)
class Console(Protocol):
    def read_line(self) -> str: ...
    def write_line(self, s: str) -> None: ...

# Production interpreter
class IoConsole:
    def read_line(self) -> str:
        return input()

    def write_line(self, s: str) -> None:
        print(s)

# Test interpreter — pure, captures output
@dataclass
class FakeConsole:
    output: list[str] = field(default_factory=list)

    def read_line(self) -> str:
        return "test-input"

    def write_line(self, s: str) -> None:
        self.output.append(s)

# Program — polymorphic via Protocol
def greet(console: Console, name: str) -> None:
    console.write_line(f"Hello, {name}")

# Production
greet(IoConsole(), "World")

# Test — no IO, fully pure, easily assertable
fake = FakeConsole()
greet(fake, "World")
assert fake.output == ["Hello, World"]
```

### Haskell

```haskell
-- MTL-style (the original tagless final) uses typeclasses directly
-- Each algebra is a typeclass; programs are constrained by what they need

{-# LANGUAGE FlexibleContexts #-}

import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.State    (MonadState, StateT, execStateT, modify)
import System.IO              (hFlush, stdout)

-- Algebra 1: console I/O
class Monad m => MonadConsole m where
    readLine  :: m String
    writeLine :: String -> m ()

-- Algebra 2: a key-value store
class Monad m => MonadKVStore m where
    kvGet :: String -> m (Maybe String)
    kvPut :: String -> String -> m ()

-- Program is polymorphic in m — only lists the effects it needs
program :: (MonadConsole m, MonadKVStore m) => m ()
program = do
    name <- readLine
    kvPut "last_user" name
    writeLine $ "Stored: " <> name

-- Production interpreter: IO
instance MonadConsole IO where
    readLine      = do { putStr "> "; hFlush stdout; getLine }
    writeLine s   = putStrLn s

-- In-memory test interpreter
type TestM = StateT [(String, String)] IO

instance MonadConsole TestM where
    readLine    = return "test-user"
    writeLine _ = return ()          -- swallow output in tests

instance MonadKVStore TestM where
    kvGet k   = fmap (lookup k) get'
      where get' = fmap id (Control.Monad.State.get)
    kvPut k v = modify ((k, v) :)

-- Run production
runProd :: IO ()
runProd = program  -- m ~ IO; kvGet/kvPut would need a real DB instance

-- Run test — pure, inspectable
runTest :: IO [(String, String)]
runTest = execStateT program []
-- result: [("last_user", "test-user")]
```

### Rust

```rust
// Tagless final in Rust via trait objects / generic parameters
// Rust uses traits as the algebra; monomorphisation gives zero overhead

// Algebra trait
trait Console {
    fn read_line(&self)              -> String;
    fn write_line(&self, s: &str);
}

trait KvStore {
    fn get(&self, key: &str)         -> Option<String>;
    fn put(&mut self, key: &str, value: &str);
}

// Production interpreter
struct IoConsole;
impl Console for IoConsole {
    fn read_line(&self) -> String {
        let mut buf = String::new();
        std::io::stdin().read_line(&mut buf).unwrap();
        buf.trim().to_owned()
    }
    fn write_line(&self, s: &str) { println!("{}", s); }
}

// Test interpreter
#[derive(Default)]
struct FakeConsole { pub output: Vec<String> }
impl Console for FakeConsole {
    fn read_line(&self)         -> String { "test-input".to_owned() }
    fn write_line(&self, s: &str) {
        // Can't mutate through &self with this signature; use RefCell in practice
        println!("[fake] {}", s);
    }
}

// Program — generic over C: Console
fn greet<C: Console>(console: &C, name: &str) {
    console.write_line(&format!("Hello, {name}"));
}

fn main() {
    let io = IoConsole;
    greet(&io, "World");        // production

    let fake = FakeConsole::default();
    greet(&fake, "World");      // test (no real I/O)
}
```

### Go

```go
// Tagless final in Go via interfaces — idiomatic Go already follows this pattern
package main

import "fmt"

// Algebra: interface defines the capability
type Console interface {
    ReadLine() string
    WriteLine(s string)
}

type KVStore interface {
    Get(key string) (string, bool)
    Put(key, value string)
}

// Production interpreter
type IOConsole struct{}

func (IOConsole) ReadLine() string     { var s string; fmt.Scan(&s); return s }
func (IOConsole) WriteLine(s string)   { fmt.Println(s) }

// Test interpreter — pure, in-memory
type FakeConsole struct{ Output []string }

func (f *FakeConsole) ReadLine() string   { return "test-input" }
func (f *FakeConsole) WriteLine(s string) { f.Output = append(f.Output, s) }

// In-memory KV store (used in tests)
type MemKV map[string]string

func (m MemKV) Get(k string) (string, bool) { v, ok := m[k]; return v, ok }
func (m MemKV) Put(k, v string)             { m[k] = v }

// Program — polymorphic via interfaces
func greet(c Console, name string) {
    c.WriteLine("Hello, " + name)
}

func storeAndGreet(c Console, kv KVStore, name string) {
    kv.Put("last", name)
    c.WriteLine("Stored: " + name)
}

func main() {
    // Production
    greet(IOConsole{}, "World")

    // Test — swap interpreter, no I/O
    fake := &FakeConsole{}
    kv   := MemKV{}
    storeAndGreet(fake, kv, "World")
    fmt.Println(fake.Output) // [Stored: World]
    fmt.Println(kv["last"])  // World
}
```

## Key points

| Concept             | Description                                                                 |
| ------------------- | --------------------------------------------------------------------------- |
| Algebra             | A typeclass / interface expressing one domain's operations                  |
| Polymorphic program | `∀ F[_]. Algebra[F] ⇒ F[Result]` — written once, interpreted many ways      |
| Capability control  | The type signature is an exact capability list; unlisted effects are banned |
| Testing             | Provide a pure `F` (Identity, State, List) — no mocking frameworks needed   |
| vs Free Monad       | Same power, better performance, no AST heap allocation                      |
| MTL                 | Monad Transformer Library — the Haskell precursor; constraints over `m`     |

## See also

- [22. Composing Effects](./22-effects.md) — Free Monad and Algebraic Effects as alternatives
- [19. Monad](./19-monad.md) — the monad constraint underpinning every program in `F`
- [09. Type Classes](./09-type-classes.md) — the mechanism that makes the algebra polymorphism work
