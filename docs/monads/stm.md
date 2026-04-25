# STM Monad

**Software Transactional Memory** (STM) models concurrent reads and writes to shared state as
**atomic transactions**. A transaction either commits completely — with all its writes visible at
once — or retries from the beginning if another thread modified a value it read.

![STM monad](diagrams/stm.svg)

## Type

```text
STM a     -- an atomic action that produces a
TVar a    -- a mutable cell readable and writable inside STM
```

`STM` is a monad that runs inside `IO` via `atomically`. `TVar` is the unit of shared mutable state.

## Key operations

| Operation          | Type           | Description                                                     |
| ------------------ | -------------- | --------------------------------------------------------------- |
| `newTVar a`        | `STM (TVar a)` | Create a new transactional variable with initial value          |
| `readTVar tv`      | `STM a`        | Read the current value of a `TVar`                              |
| `writeTVar tv a`   | `STM ()`       | Write a new value to a `TVar`                                   |
| `atomically stm`   | `IO a`         | Execute a transaction atomically in `IO`                        |
| `retry`            | `STM a`        | Block; retry the whole transaction when any read `TVar` changes |
| `orElse stm1 stm2` | `STM a`        | Try `stm1`; if it calls `retry`, run `stm2` instead             |

## What makes STM unique

- **Composability** — STM actions combine with `>>=` and `orElse` without holding any locks
- **`retry` semantics** — "wait until the relevant `TVar`s change"; the runtime handles waking
- **No deadlocks** — no explicit lock ordering is required
- **Automatic rollback** — if a transaction fails mid-way, all tentative writes are discarded

## Key use cases

- Atomic multi-variable updates (e.g. bank transfer between two accounts)
- "Produce when ready / consume when available" bounded queues
- Dining philosophers and other resource-allocation problems
- Any scenario that previously required acquiring multiple locks in a specific order

## Motivation

Classic locking requires careful lock ordering to avoid deadlock. Acquiring `accountA` then
`accountB` in one thread while another acquires `accountB` then `accountA` causes a deadlock. The
only safe fix — a global lock ordering — scales poorly and cannot be composed.

```text
-- Without STM: explicit locks; wrong ordering -> deadlock
function transfer(from, to, amount):
    lock(from)              -- Thread 1 holds from; Thread 2 holds to -> deadlock
    lock(to)
    from.balance -= amount
    to.balance   += amount
    unlock(to)
    unlock(from)
```

```text
-- With STM: compose two reads and two writes in a single transaction
transfer from to amount = atomically $ do
    fb <- readTVar from
    writeTVar from (fb - amount)
    tb <- readTVar to
    writeTVar to (tb + amount)
-- Runtime retries automatically if another transaction conflicts; no deadlock possible.
```

![STM motivation](diagrams/stm-motivation.svg)

## Examples

The examples below all solve the same problem: **atomic bank transfer** — debit one account and
credit another so that no intermediate state is ever visible to other threads.

### C\#

C# has no STM. Atomicity is achieved with `lock` (a mutual-exclusion monitor). Composing operations
across multiple objects still requires a single coarse lock to avoid deadlock.

```csharp
using System.Threading;

class Account
{
    private decimal _balance;
    public Account(decimal initial) => _balance = initial;
    public decimal Balance => _balance;

    public void Deposit(decimal amount)  => Interlocked.Exchange(ref _balance, _balance + amount);
    public void Withdraw(decimal amount) => Interlocked.Exchange(ref _balance, _balance - amount);
}

// Transfer: acquire a global lock to prevent the deadlock that per-account locks would cause
static readonly object _transferLock = new();

static void Transfer(Account from, Account to, decimal amount)
{
    lock (_transferLock)
    {
        if (from.Balance < amount) throw new InvalidOperationException("insufficient funds");
        from.Withdraw(amount);
        to.Deposit(amount);
    }
}
```

### F\#

F# has no built-in STM. The idiomatic approach for simple cases uses `lock`. For actor-style
concurrency `MailboxProcessor` avoids shared state entirely.

```fsharp
open System.Threading

type Account(initial: decimal) =
    let mutable balance = initial
    member _.Balance = balance
    member _.Deposit amount  = balance <- balance + amount
    member _.Withdraw amount = balance <- balance - amount

let transferLock = obj ()

let transfer (from: Account) (to_: Account) amount =
    lock transferLock (fun () ->
        if from.Balance < amount then failwith "insufficient funds"
        from.Withdraw amount
        to_.Deposit amount)

// MailboxProcessor: each account is an actor — no shared mutable state at all
type AccountMsg =
    | Deposit  of decimal
    | Withdraw of decimal * AsyncReplyChannel<Result<unit, string>>

let makeAccount initial =
    MailboxProcessor.Start(fun inbox ->
        let rec loop bal = async {
            let! msg = inbox.Receive()
            match msg with
            | Deposit amount -> return! loop (bal + amount)
            | Withdraw (amount, reply) ->
                if bal < amount then reply.Reply(Error "insufficient funds"); return! loop bal
                else reply.Reply(Ok ()); return! loop (bal - amount)
        }
        loop initial)
```

### Ruby

Ruby has no STM. `Mutex` provides per-operation locking. For atomic multi-resource operations a
shared mutex is the standard approach.

```ruby
require 'thread'

class Account
  attr_reader :balance

  def initialize(initial)
    @balance = initial
    @mutex   = Mutex.new
  end

  def deposit(amount)
    @mutex.synchronize { @balance += amount }
  end

  def withdraw(amount)
    @mutex.synchronize do
      raise 'insufficient funds' if @balance < amount
      @balance -= amount
    end
  end
end

TRANSFER_LOCK = Mutex.new

def transfer(from, to, amount)
  TRANSFER_LOCK.synchronize do
    raise 'insufficient funds' if from.balance < amount
    from.withdraw(amount)
    to.deposit(amount)
  end
end
```

### C++

C++ uses `std::mutex` and `std::lock_guard`. `std::scoped_lock` (C++17) acquires multiple mutexes in
a deadlock-free order.

```cpp
#include <mutex>
#include <stdexcept>

struct Account {
    double balance;
    std::mutex mx;
    explicit Account(double initial) : balance(initial) {}
};

void transfer(Account& from, Account& to, double amount) {
    // std::scoped_lock acquires both mutexes without deadlock (uses std::lock internally)
    std::scoped_lock lock(from.mx, to.mx);
    if (from.balance < amount)
        throw std::runtime_error("insufficient funds");
    from.balance -= amount;
    to.balance   += amount;
}
```

### JavaScript

JavaScript is single-threaded; concurrent access to shared objects cannot happen within one thread.
`SharedArrayBuffer` + `Atomics` provide true shared memory between Web Workers.

```js
// Single-threaded: plain objects are naturally "atomic" — no interleaving possible
class Account {
  constructor(initial) {
    this.balance = initial;
  }
  deposit(amount) {
    this.balance += amount;
  }
  withdraw(amount) {
    if (this.balance < amount) throw new Error("insufficient funds");
    this.balance -= amount;
  }
}

function transfer(from, to, amount) {
  from.withdraw(amount); // no race: JS event loop is non-preemptive
  to.deposit(amount);
}

// Shared memory between workers (SharedArrayBuffer + Atomics):
// const shared = new SharedArrayBuffer(4);
// const view   = new Int32Array(shared);
// Atomics.add(view, 0, amount);   // atomic increment
// Atomics.wait / Atomics.notify replace retry / orElse
```

### Python

Python's GIL (Global Interpreter Lock) prevents true parallel execution of Python bytecode.
`threading.Lock` + `threading.Condition` cover the STM use cases in the single-GIL model.

```py
import threading

class Account:
    def __init__(self, initial):
        self.balance = initial
        self._lock   = threading.Lock()

    def deposit(self, amount):
        with self._lock:
            self.balance += amount

    def withdraw(self, amount):
        with self._lock:
            if self.balance < amount:
                raise ValueError("insufficient funds")
            self.balance -= amount

_transfer_lock = threading.Lock()

def transfer(from_acc, to_acc, amount):
    # One lock for the pair; avoids deadlock from per-account locks
    with _transfer_lock:
        if from_acc.balance < amount:
            raise ValueError("insufficient funds")
        from_acc.balance -= amount
        to_acc.balance   += amount
```

### Haskell

Haskell has a full `STM` monad in `Control.Concurrent.STM`. `retry` and `orElse` are unique — they
have no direct equivalent in any other mainstream language.

```hs
import Control.Concurrent.STM

transfer :: TVar Int -> TVar Int -> Int -> STM ()
transfer from to amount = do
    fromBal <- readTVar from
    if fromBal < amount
        then retry                          -- block until from changes, then re-run
        else do
            writeTVar from (fromBal - amount)
            tb <- readTVar to
            writeTVar to (tb + amount)

-- Execute atomically in IO
main :: IO ()
main = do
    from <- newTVarIO 100
    to   <- newTVarIO  50
    atomically (transfer from to 30)
    -- from: 70, to: 80

-- orElse: try the first transaction; fall back to the second if it retries
withdrawOrNothing :: TVar Int -> Int -> STM Bool
withdrawOrNothing tv amount =
    (do
        bal <- readTVar tv
        if bal < amount then retry else writeTVar tv (bal - amount) >> return True)
    `orElse`
    return False
```

### Rust

Rust has no STM in the standard library. `Arc<Mutex<T>>` (exclusive) or `Arc<RwLock<T>>`
(shared-read / exclusive-write) are the standard concurrency primitives. The
[`stm`](https://crates.io/crates/stm) crate provides a Haskell-style STM.

```rust
use std::sync::{Arc, Mutex};

#[derive(Default)]
struct Account {
    balance: i64,
}

fn transfer(from: Arc<Mutex<Account>>, to: Arc<Mutex<Account>>, amount: i64) {
    // Lock both — use a consistent ordering to avoid deadlock (lower address first)
    let (mut a, mut b) = if Arc::ptr_eq(&from, &to) {
        panic!("same account");
    } else {
        (from.lock().unwrap(), to.lock().unwrap())
    };
    if a.balance < amount {
        panic!("insufficient funds");
    }
    a.balance -= amount;
    b.balance += amount;
}

// With the `stm` crate (Haskell-style):
// use stm::{atomically, TVar};
// let from = TVar::new(100i64);
// let to   = TVar::new(50i64);
// atomically(|tx| {
//     let fb = from.read(tx)?;
//     if fb < 30 { stm::retry()?; }
//     from.write(tx, fb - 30)?;
//     let tb = to.read(tx)?;
//     to.write(tx, tb + 30)
// });
```

### Go

Go favours **channels** for communication and `sync.Mutex` for shared state. There is no STM in the
standard library. The channel model avoids shared-state races entirely for many patterns.

```go
import "sync"

type Account struct {
	mu      sync.Mutex
	balance int
}

func (a *Account) Deposit(amount int) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.balance += amount
}

func (a *Account) Balance() int {
	a.mu.Lock()
	defer a.mu.Unlock()
	return a.balance
}

// Transfer: use a package-level mutex to keep both accounts in sync
var transferMu sync.Mutex

func Transfer(from, to *Account, amount int) error {
	transferMu.Lock()
	defer transferMu.Unlock()
	if from.balance < amount {
		return fmt.Errorf("insufficient funds")
	}
	from.balance -= amount
	to.balance += amount
	return nil
}

// Channel-based approach: send transfer requests to a single goroutine that owns the state
type transferMsg struct{ from, to *Account; amount int; reply chan<- error }

func accountManager(ch <-chan transferMsg) {
	for msg := range ch {
		if msg.from.balance < msg.amount {
			msg.reply <- fmt.Errorf("insufficient funds")
		} else {
			msg.from.balance -= msg.amount
			msg.to.balance += msg.amount
			msg.reply <- nil
		}
	}
}
```
