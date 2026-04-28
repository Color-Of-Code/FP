# 24. Concurrency and Parallelism

Functional programming changes the concurrency story fundamentally: **immutable values can be shared
between threads without locks**, and **pure functions can be parallelised without coordination**.
This chapter covers the FP-native approaches to concurrent and parallel programming.

![concurrency](24-concurrency/concurrency.svg)

## The core insight

Shared mutable state is the root cause of data races, deadlocks, and heisenbugs. FP avoids the
problem by default:

- **Immutable values** can be read by any number of threads simultaneously — no synchronisation
  needed.
- **Pure functions** have no observable side effects, so calling them in parallel is always safe.
- When mutable state _is_ needed, **STM** (Software Transactional Memory) provides composable,
  deadlock-free transactions.

## Four levels of FP concurrency

![concurrency motivation](24-concurrency/concurrency-motivation.svg)

| Level                | Mechanism                                   | Coordination                          | Best for                               |
| -------------------- | ------------------------------------------- | ------------------------------------- | -------------------------------------- |
| **Pure parallelism** | `par`/`pseq`, parallel strategies, `parMap` | None — purity guarantees safety       | CPU-bound, embarrassingly parallel     |
| **STM**              | Atomic transactions over `TVar`/`MVar`      | Composable; retry on conflict         | Shared mutable cells without deadlocks |
| **Async tasks**      | `Future`/`Task`/`async`-`await`             | Structured concurrency, cancellation  | I/O-bound, pipelines, timeouts         |
| **Actor model**      | Isolated actors with message queues         | No shared state; location-transparent | Distributed systems, fault tolerance   |

## Pure parallelism

A pure function called on independent inputs can always be evaluated in parallel. No locking, no
ordering constraints, no risk of data races.

```text
-- Haskell: par evaluates its first arg in parallel with the second
import Control.Parallel (par, pseq)

fib :: Int -> Int
fib 0 = 0
fib 1 = 1
fib n = let a = fib (n-1)
            b = fib (n-2)
        in  a `par` b `pseq` a + b

-- parMap: map a pure function over a list using a thread pool
import Control.Parallel.Strategies (parMap, rseq)
results = parMap rseq expensiveComputation [1..1000]
```

## STM — Software Transactional Memory

STM wraps reads and writes to shared cells in **atomic blocks** that either commit entirely or retry
without effect. Crucially, STM transactions are **composable**: you can build a transaction from
smaller transactions without worrying about lock ordering.

```text
-- STM in Haskell: TVar holds a mutable value; atomically runs the transaction
import Control.Concurrent.STM

transfer :: TVar Int -> TVar Int -> Int -> STM ()
transfer from to amount = do
    bal <- readTVar from
    if bal < amount
        then retry            -- block until from has enough
        else do
            modifyTVar from (subtract amount)
            modifyTVar to   (+ amount)

-- Compose two transactions — no deadlock possible
atomically $ do
    transfer accountA accountB 100
    transfer accountB accountC 50
```

See [STM in the monad catalogue](../monads/stm.md) for the full API.

## Async tasks and structured concurrency

Async tasks model I/O-bound concurrency: launch a computation, do other work, then collect the
result. **Structured concurrency** (e.g. `async`/`withAsync` in Haskell, `TaskGroup` in Swift,
`asyncio.TaskGroup` in Python) guarantees that child tasks cannot outlive their parent scope,
eliminating resource leaks.

```text
-- Haskell: async launches a thread; wait collects the result
import Control.Concurrent.Async (async, wait, concurrently)

fetchBoth :: IO (String, String)
fetchBoth = concurrently (fetch "url1") (fetch "url2")
-- Both fetches run in parallel; result only available when both finish.

-- Structured: withAsync ensures the child is always cancelled on exit
withAsync (fetch "url") $ \a -> do
    doOtherWork
    result <- wait a
    return result
```

## Actor model

Each actor is an isolated unit with its own mailbox; actors communicate only by sending immutable
messages. There is no shared state between actors, so data races are impossible by construction.
Erlang/OTP is the canonical implementation; Akka (Scala/Java) and Pony bring it to other platforms.

```text
-- Erlang: spawn creates an actor (process); ! sends a message
Pid = spawn(fun() -> loop() end),
Pid ! {self(), "hello"},
receive
    {From, Msg} -> io:format("got: ~p~n", [Msg])
end.
```

## Examples

### C\#

```csharp
// 1. Pure parallelism — PLINQ (Parallel LINQ)
using System.Linq;

int[] numbers = Enumerable.Range(1, 1_000_000).ToArray();

// AsParallel splits work across thread pool; pure function, no locking needed
var squares = numbers.AsParallel()
                     .Select(n => n * n)
                     .ToArray();

// 2. Async tasks — Task<T> and async/await
using System.Threading.Tasks;

async Task<(string, string)> FetchBothAsync(string url1, string url2)
{
    // Run both I/O operations concurrently
    var t1 = FetchAsync(url1);
    var t2 = FetchAsync(url2);
    await Task.WhenAll(t1, t2);
    return (await t1, await t2);
}

// 3. STM-like: Channel<T> for lock-free producer/consumer
using System.Threading.Channels;

var channel = Channel.CreateUnbounded<int>();
await channel.Writer.WriteAsync(42);
var value = await channel.Reader.ReadAsync(); // 42
```

### F\#

```fsharp
// 1. Pure parallelism — Array.Parallel
let squares =
    [| 1..1_000_000 |]
    |> Array.Parallel.map (fun n -> n * n)

// 2. Async workflows — F#'s built-in async CE
open System.Net.Http

let fetchAsync (url: string) : Async<string> = async {
    use client = new HttpClient()
    return! client.GetStringAsync(url) |> Async.AwaitTask
}

// Run two fetches in parallel
let fetchBoth url1 url2 = async {
    let! results = [fetchAsync url1; fetchAsync url2] |> Async.Parallel
    return results
}

// 3. MailboxProcessor — F#'s built-in actor
let counter = MailboxProcessor.Start(fun inbox ->
    let rec loop n = async {
        let! msg = inbox.Receive()
        match msg with
        | "inc"  -> return! loop (n + 1)
        | "get"  -> inbox.Reply(n); return! loop n
        | _      -> return ()
    }
    loop 0)

counter.Post "inc"
counter.Post "inc"
let n = counter.PostAndReply "get"  // 2
```

### Ruby

```ruby
# 1. Pure parallelism — Ractors (Ruby 3+, true parallelism)
results = (1..8).map do |i|
  Ractor.new(i) { |n| n * n }
end.map(&:take)
# [1, 4, 9, 16, 25, 36, 49, 64] — computed in parallel

# 2. Async tasks — Async gem
require "async"

Async do
  task1 = Async { sleep 1; "result1" }
  task2 = Async { sleep 1; "result2" }
  puts [task1.wait, task2.wait].inspect  # both complete in ~1s
end

# 3. Actor-like — Ractor as an isolated mailbox
counter = Ractor.new do
  n = 0
  loop do
    msg = Ractor.receive
    case msg
    in [:inc]  then n += 1
    in [:get, sender] then sender.send(n)
    end
  end
end

counter.send([:inc])
counter.send([:inc])
me = Ractor.current
counter.send([:get, me])
puts Ractor.receive  # 2
```

### C++

```cpp
// 1. Pure parallelism — std::execution::par (C++17)
#include <algorithm>
#include <execution>
#include <vector>
#include <numeric>

std::vector<int> nums(1'000'000);
std::iota(nums.begin(), nums.end(), 1);

// Pure function applied in parallel — no locks needed
std::transform(std::execution::par_unseq,
               nums.begin(), nums.end(), nums.begin(),
               [](int n) { return n * n; });

// 2. Async tasks — std::async / std::future
#include <future>
#include <string>

std::future<std::string> t1 = std::async(std::launch::async, [] { return fetch("url1"); });
std::future<std::string> t2 = std::async(std::launch::async, [] { return fetch("url2"); });

std::string r1 = t1.get();  // blocks until ready
std::string r2 = t2.get();

// 3. Lock-free channels — std::atomic for simple shared state
#include <atomic>

std::atomic<int> counter{0};
// Increment from multiple threads without mutex
counter.fetch_add(1, std::memory_order_relaxed);
```

### JavaScript

```javascript
// 1. Pure parallelism — Worker threads (Node.js) / Web Workers (browser)
import { Worker, isMainThread, workerData, parentPort } from "worker_threads";

// Pure computation offloaded to a worker (no shared state)
if (!isMainThread) {
  const result = workerData ** 2;
  parentPort.postMessage(result);
} else {
  const squared = (n) =>
    new Promise((resolve) => {
      const w = new Worker(__filename, { workerData: n });
      w.on("message", resolve);
    });
  const results = await Promise.all([1, 2, 3, 4].map(squared));
  console.log(results); // [1, 4, 9, 16]
}

// 2. Async tasks — Promise / async-await (structured via Promise.all)
async function fetchBoth(url1, url2) {
  const [r1, r2] = await Promise.all([fetch(url1), fetch(url2)]);
  return [await r1.text(), await r2.text()];
}

// 3. Actor-like — isolated web worker with postMessage
// Worker state is isolated; communication is message-passing only
const worker = new Worker("./worker.js");
worker.postMessage({ type: "inc" });
worker.postMessage({ type: "get" });
worker.on("message", (msg) => console.log(msg)); // { count: 1 }
```

### Python

```python
import asyncio
from concurrent.futures import ProcessPoolExecutor

# 1. Pure parallelism — ProcessPoolExecutor (bypasses GIL; pure functions only)
def square(n: int) -> int:
    return n * n

with ProcessPoolExecutor() as pool:
    results = list(pool.map(square, range(1_000_000)))

# 2. Async tasks — asyncio with structured concurrency (TaskGroup, Python 3.11+)
import httpx

async def fetch(url: str) -> str:
    async with httpx.AsyncClient() as client:
        r = await client.get(url)
        return r.text

async def fetch_both(url1: str, url2: str) -> tuple[str, str]:
    async with asyncio.TaskGroup() as tg:  # structured: children can't outlive scope
        t1 = tg.create_task(fetch(url1))
        t2 = tg.create_task(fetch(url2))
    return t1.result(), t2.result()

# 3. Actor-like — asyncio.Queue as a mailbox
async def counter_actor(queue: asyncio.Queue) -> None:
    n = 0
    while True:
        msg = await queue.get()
        match msg:
            case ("inc",):       n += 1
            case ("get", reply): await reply.put(n)
            case ("stop",):      break

async def main() -> None:
    q: asyncio.Queue = asyncio.Queue()
    asyncio.create_task(counter_actor(q))
    await q.put(("inc",))
    await q.put(("inc",))
    reply: asyncio.Queue = asyncio.Queue()
    await q.put(("get", reply))
    print(await reply.get())  # 2

asyncio.run(main())
```

### Haskell

```haskell
-- Haskell has the most principled FP concurrency story:
-- pure by default, STM for shared state, async for I/O

import Control.Parallel.Strategies (parMap, rseq)
import Control.Concurrent.STM
import Control.Concurrent.Async   (concurrently, withAsync, wait)
import Control.Concurrent          (forkIO, threadDelay)

-- 1. Pure parallelism — parMap runs a pure function on all elements in parallel
squares :: [Int]
squares = parMap rseq (^ 2) [1..1_000_000]

-- 2. STM — composable, deadlock-free shared state
transfer :: TVar Int -> TVar Int -> Int -> STM ()
transfer from to amt = do
    bal <- readTVar from
    if bal < amt
        then retry
        else do modifyTVar from (subtract amt)
                modifyTVar to   (+ amt)

runTransfer :: IO ()
runTransfer = do
    a <- newTVarIO 100
    b <- newTVarIO 0
    atomically (transfer a b 40)
    readTVarIO b >>= print  -- 40

-- 3. Async — structured concurrency
fetchBoth :: IO (String, String)
fetchBoth = concurrently (fetch "url1") (fetch "url2")

-- 4. MVar — a single-slot mutable box; basis of semaphores and locks
import Control.Concurrent.MVar

ping :: MVar () -> MVar () -> IO ()
ping pingVar pongVar = do
    takeMVar pingVar  -- wait for ping
    putMVar pongVar ()
    ping pingVar pongVar
```

### Rust

```rust
// 1. Pure parallelism — Rayon (data-parallel, no locks needed for pure fns)
// cargo add rayon
use rayon::prelude::*;

let squares: Vec<u64> = (1u64..=1_000_000)
    .into_par_iter()
    .map(|n| n * n)
    .collect();

// 2. Async tasks — Tokio (structured concurrency)
// cargo add tokio --features full
use tokio::task;

#[tokio::main]
async fn main() {
    // Spawn two independent tasks and join them
    let t1 = task::spawn(async { fetch("url1").await });
    let t2 = task::spawn(async { fetch("url2").await });
    let (r1, r2) = tokio::join!(t1, t2);

    // tokio::select! races tasks — first to finish wins
    tokio::select! {
        v = t1 => println!("t1 done: {:?}", v),
        v = t2 => println!("t2 done: {:?}", v),
    }
}

// 3. Message passing — std::sync::mpsc (or tokio::sync::mpsc for async)
use std::sync::mpsc;
use std::thread;

let (tx, rx) = mpsc::channel::<i32>();
let tx2 = tx.clone();

thread::spawn(move || tx.send(1).unwrap());
thread::spawn(move || tx2.send(2).unwrap());

println!("{}", rx.recv().unwrap() + rx.recv().unwrap()); // 3
```

### Go

```go
// Go's concurrency model is idiomatic goroutines + channels (CSP)
// and sync primitives for pure parallelism

package main

import (
    "fmt"
    "sync"
)

// 1. Pure parallelism — goroutines + WaitGroup
func parallelMap(xs []int, f func(int) int) []int {
    out := make([]int, len(xs))
    var wg sync.WaitGroup
    for i, x := range xs {
        wg.Add(1)
        go func(idx, val int) {
            defer wg.Done()
            out[idx] = f(val)  // pure function, each goroutine writes to its own index
        }(i, x)
    }
    wg.Wait()
    return out
}

// 2. Async tasks — goroutines + channels (structured via select)
func fetchBoth(url1, url2 string) (string, string) {
    ch1 := make(chan string, 1)
    ch2 := make(chan string, 1)

    go func() { ch1 <- fetch(url1) }()
    go func() { ch2 <- fetch(url2) }()

    return <-ch1, <-ch2  // both run concurrently
}

// 3. Actor model — goroutine with a dedicated input channel (CSP actor)
type Msg struct {
    Kind  string
    Reply chan<- int
}

func counterActor(inbox <-chan Msg) {
    n := 0
    for msg := range inbox {
        switch msg.Kind {
        case "inc":
            n++
        case "get":
            msg.Reply <- n
        }
    }
}

func main() {
    inbox := make(chan Msg, 10)
    go counterActor(inbox)

    inbox <- Msg{Kind: "inc"}
    inbox <- Msg{Kind: "inc"}
    reply := make(chan int, 1)
    inbox <- Msg{Kind: "get", Reply: reply}
    fmt.Println(<-reply) // 2

    squares := parallelMap([]int{1, 2, 3, 4}, func(n int) int { return n * n })
    fmt.Println(squares) // [1 4 9 16]
}
```

## Key points

| Concept                | Description                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------- |
| Pure parallelism       | No synchronisation needed; purity is the safety guarantee (`parMap`, Rayon)            |
| STM                    | Composable atomic transactions; no deadlocks; `retry` suspends until retry is possible |
| Structured concurrency | Child tasks cannot outlive their scope; cancellation propagates automatically          |
| Actor model            | Isolated mailboxes; message passing only; location-transparent distribution            |
| Immutability           | Shared values without locks — the foundational FP concurrency win                      |
| `MVar` / `Channel`     | Single-slot mutable boxes; building block for semaphores and lock-free structures      |

## See also

- [../monads/stm.md](../monads/stm.md) — STM monad in detail: `TVar`, `retry`, `orElse`
- [19. Monad](./19-monad.md) — `IO` and `STM` are monads; `>>=` sequences concurrent actions
- [22. Composing Effects](./22-effects.md) — how effects stacks interact with concurrency
