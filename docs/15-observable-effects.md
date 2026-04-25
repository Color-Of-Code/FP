# 15. Observable Effects

The functional model treats functions as timeless mathematical mappings: given the same inputs a
pure function always returns the same output, with no visible interaction with the world. Real
hardware runs inside a physical world — every function call takes time, draws power, warms silicon,
and emits electromagnetic radiation. Most programs can safely ignore these physical effects and the
functional abstraction holds perfectly. Some domains cannot: cryptographic code that leaks timing
data can allow an attacker to recover a secret key in seconds.

![observable effects](diagrams/observable-effects.svg)

## The effect spectrum

| Layer             | Example effects                                   | Usually ignored?                    |
| ----------------- | ------------------------------------------------- | ----------------------------------- |
| Mathematical      | none — functions are timeless relations           | n/a                                 |
| Functional        | `IO`, `State`, `Error`, `Random` — explicit types | no — the whole point of FP          |
| Runtime           | memory allocation, GC pauses, JIT warmup          | yes, for most application code      |
| Microarchitecture | cache hits/misses, branch prediction, pipelines   | yes, except real-time / WCET work   |
| Physical          | CPU timing, power draw, EM emissions, heat        | yes, **except crypto and embedded** |

## When physical effects are negligible

For the vast majority of programs the physical layer is completely invisible:

- Business logic, data processing, web services — correctness is the only concern.
- The runtime abstracts resource management; the developer works with values and functions.
- Performance tuning stays at the runtime/microarchitecture layer (profilers, flamegraphs).

The FP purity guarantee covers exactly the functional layer. It says nothing about time, power, or
radiation, and it does not need to — for most software those effects are irrelevant to correctness.

## When physical effects are critical

Two broad domains must treat physical effects as first-class concerns.

### Security: side-channel attacks

A **timing attack** exploits the fact that a naive `==` on byte arrays short-circuits on the first
mismatch. An adversary who can measure the time to receive a response can learn how many bytes of
their guess match the secret, and recover it byte-by-byte in at most `256 × n` guesses instead of
`256^n`.

**Power analysis** and **EM emanation attacks** go further: an oscilloscope or EM probe measures CPU
power draw or radiated field strength, and the modulation encodes the bits being processed —
including AES round keys. Against these attacks the only defense is **data-oblivious code**: no
branches, table lookups, or memory addresses that vary with secret values.

### Real-time and embedded systems

A real-time system has a deadline: the answer must arrive within a fixed time budget regardless of
input. **Worst-case execution time (WCET)** analysis accounts for cache state, branch-predictor
history, and memory-bus contention — effects that are invisible to the pure functional model.

## Motivation

```text
-- naive equality: short-circuits as soon as a byte differs
--
-- secret = [0xAB, 0xCD, 0xEF, 0x01]
-- guess1 = [0xAB, 0xCD, 0xEF, 0x00]  ← 3 correct bytes → slow response
-- guess2 = [0x00, 0x00, 0x00, 0x00]  ← 0 correct bytes → fast response
--
-- The timing difference reveals the shared prefix length.
-- An attacker recovers 4 bytes with at most 4 × 256 = 1 024 guesses.
-- Brute-force without the oracle would need up to 256^4 ≈ 4 billion.
```

```text
-- constant-time equality: always processes all bytes
--
-- secret = [0xAB, 0xCD, 0xEF, 0x01]
-- guess1 = [0xAB, 0xCD, 0xEF, 0x00]  ← diff = 0x01; all 4 bytes visited
-- guess2 = [0x00, 0x00, 0x00, 0x00]  ← diff = 0xAB; all 4 bytes visited
--
-- Response time is identical for any input of the same length.
-- The attacker learns nothing from timing: 256^4 guesses required.
```

![observable effects motivation](diagrams/observable-effects-motivation.svg)

## Examples

Each example below shows the naive short-circuiting comparison alongside a constant-time
replacement. The constant-time variant XORs all byte pairs and accumulates differences without
branching on secret data, so execution time is the same regardless of where (or whether) the values
diverge.

### C\#

```csharp
using System;
using System.Security.Cryptography;

// naive — short-circuits; leaks how many leading bytes match
static bool NaiveEqual(byte[] a, byte[] b) =>
    ((ReadOnlySpan<byte>)a).SequenceEqual(b);

// constant-time — always processes all bytes (.NET 5+)
static bool ConstantTimeEqual(byte[] a, byte[] b) =>
    CryptographicOperations.FixedTimeEquals(a, b);

// manual fallback for older runtimes
static bool ConstantTimeEqualManual(byte[] a, byte[] b)
{
    if (a.Length != b.Length) return false;
    int diff = 0;
    for (int i = 0; i < a.Length; i++)
        diff |= a[i] ^ b[i];
    return diff == 0;
}
```

### F\#

```fsharp
open System
open System.Security.Cryptography

// naive — short-circuits on first mismatch
let naiveEqual (a: byte[]) (b: byte[]) = a = b

// constant-time via .NET 5+ (CryptographicOperations.FixedTimeEquals)
let constantTimeEqual (a: byte[]) (b: byte[]) =
    CryptographicOperations.FixedTimeEquals(ReadOnlySpan(a), ReadOnlySpan(b))

// manual fallback: fold XOR over all pairs, never branch on secret data
let constantTimeEqualManual (a: byte[]) (b: byte[]) =
    if a.Length <> b.Length then false
    else Array.fold2 (fun acc x y -> acc ||| (x ^^^ y)) 0uy a b = 0uy
```

### Ruby

```ruby
require 'openssl'

# naive — short-circuits on first mismatch
def naive_equal(a, b) = a == b

# constant-time — fold XOR without early exit
def constant_time_equal(a, b)
  return false unless a.bytesize == b.bytesize

  diff = 0
  a.bytes.zip(b.bytes) { |x, y| diff |= x ^ y }
  diff.zero?
end
# see: OpenSSL::HMAC.hexdigest comparison,
#      Rack::Utils.secure_compare,
#      ActiveSupport::SecurityUtils.secure_compare
```

### C++

```cpp
#include <cstdint>
#include <cstddef>

// naive — std::memcmp may short-circuit; not guaranteed constant-time
bool naiveEqual(const uint8_t* a, const uint8_t* b, std::size_t len) {
    return std::memcmp(a, b, len) == 0;
}

// constant-time — XOR fold, no data-dependent branches
bool constantTimeEqual(const uint8_t* a, const uint8_t* b, std::size_t len) {
    uint8_t diff = 0;
    for (std::size_t i = 0; i < len; ++i)
        diff |= a[i] ^ b[i];           // accumulate differences
    return diff == 0;
}
// see: libsodium  sodium_memcmp()
//      OpenSSL     CRYPTO_memcmp()
```

### JavaScript

```js
const { timingSafeEqual } = require("crypto");

// naive — short-circuits; exposes timing to the caller
const naiveEqual = (a, b) => a.equals(b); // Buffer method

// constant-time — Node.js built-in
function constantTimeEqual(a, b) {
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b); // crypto.timingSafeEqual
}

// manual fallback (e.g. browser environments)
function constantTimeEqualManual(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}
```

### Python

```python
import hmac

# naive — short-circuits on first differing byte
def naive_equal(a: bytes, b: bytes) -> bool:
    return a == b

# constant-time — stdlib since Python 3.3
def constant_time_equal(a: bytes, b: bytes) -> bool:
    return hmac.compare_digest(a, b)
# hmac.compare_digest uses a C-level loop that prevents short-circuit
# optimisations and resists compiler reordering.
```

### Haskell

```hs
import Data.Bits (xor, (.|.))
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS

-- naive — ByteString (==) short-circuits on the first differing byte
naiveEqual :: ByteString -> ByteString -> Bool
naiveEqual = (==)

-- constant-time — fold XOR over all pairs; no branch on secret data
constantTimeEqual :: ByteString -> ByteString -> Bool
constantTimeEqual a b
    | BS.length a /= BS.length b = False
    | otherwise = BS.foldl' (.|.) 0 (BS.zipWith xor a b) == 0
-- see: memory package  Data.ByteArray.constEq
--      cryptonite      Crypto.Error.constEq
```

### Rust

```rust
// naive — short-circuits; timing depends on where values diverge
fn naive_equal(a: &[u8], b: &[u8]) -> bool {
    a == b
}

// constant-time — fold XOR over all byte pairs
fn constant_time_equal(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.iter()
        .zip(b.iter())
        .fold(0u8, |acc, (x, y)| acc | (x ^ y))
        == 0
}
// see: subtle crate  subtle::ConstantTimeEq
//      (inserts compiler barriers to prevent the optimiser from
//       reintroducing the early exit the compiler would otherwise add)
```

### Go

```go
import "crypto/subtle"

// naive — bytes.Equal short-circuits on first mismatch
func naiveEqual(a, b []byte) bool {
    return string(a) == string(b)
}

// constant-time — standard library
func constantTimeEqual(a, b []byte) bool {
    return subtle.ConstantTimeCompare(a, b) == 1
}
// crypto/subtle.ConstantTimeCompare is documented to run in time
// proportional only to the length of the slices, not their contents.
```
