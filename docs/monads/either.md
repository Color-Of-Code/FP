# Either Monad

The **Either monad** (`Result` in Rust/Swift) models computations that may **fail with an error
value** — carrying a description of what went wrong.

![either monad](../../basics/monad-either.svg)

## Type

```text
Either<e, a> = Left e   -- failure: carries an error of type e
             | Right a  -- success: carries a result of type a
```

By convention, `Right` is "right" (success) and `Left` is the error side.

## How bind works

| Input     | bind behaviour                                  |
| --------- | ----------------------------------------------- |
| `Right a` | unwrap `a`, apply `f`, return the result        |
| `Left e`  | **skip `f`**, propagate the error `e` unchanged |

The first failure short-circuits the entire chain and its error is preserved — unlike `Maybe`, you
know _why_ it failed.

## Key use cases

- Parsing with error messages
- Validation pipelines (report the first error)
- HTTP / IO operations that may fail with a reason
- Replacing exception-based error handling

## Motivation

Without Either, error-handling logic is scattered — either as deeply nested `if`/`try-catch` blocks
or as repetitive early-return boilerplate that buries the actual logic.

```text
-- Without Either: error check repeated after every step
function process(input):
    parsed = parse_int(input)
    if parsed.failed: return Fail(parsed.error)
    validated = validate_positive(parsed.value)
    if validated.failed: return Fail(validated.error)
    saved = save_to_db(validated.value)
    if saved.failed: return Fail(saved.error)
    return Ok(saved.value)
-- Adding a step means adding another if/return pair.
```

```text
-- With Either: bind short-circuits on the first Left; happy path reads top to bottom
process(input) =
    parse_int(input)
    >>= validate_positive
    >>= save_to_db
```

## Examples

### C\#

```csharp
// Using a simple Result type
record Result<T>(T? Value, string? Error)
{
    public static Result<T> Ok(T value) => new(value, null);
    public static Result<T> Fail(string err) => new(default, err);
    public Result<U> Bind<U>(Func<T, Result<U>> f)
        => Error is null ? f(Value!) : Result<U>.Fail(Error);
}

var result = Result<string>.Ok("42")
    .Bind(s => int.TryParse(s, out var n) ? Result<int>.Ok(n) : Result<int>.Fail("not a number"))
    .Bind(n => n >= 0 ? Result<int>.Ok(n) : Result<int>.Fail("negative age"))
    .Bind(n => Result<string>.Ok($"{n} years old"));
// Ok("42 years old")
```

### F\#

F# has a built-in `Result<'T,'E>` type with `Ok` and `Error` cases and `Result.bind` for chaining.

```fsharp
let parseAge (s: string) =
    match System.Int32.TryParse(s) with
    | true, n  -> Ok n
    | _        -> Error "not a number"

let validateAge n =
    if n >= 0 then Ok n else Error "negative age"

let formatAge n = Ok $"{n} years old"

let result =
    parseAge "42"
    |> Result.bind validateAge   // Ok 42
    |> Result.bind formatAge     // Ok "42 years old"
// result = Ok "42 years old"
```

### Ruby

```ruby
# Minimal Result type
Ok   = ->(val) { [:ok,   val] }
Fail = ->(err) { [:fail, err] }

def bind(result)
  result[0] == :ok ? yield(result[1]) : result
end

result = bind(Ok["42"])  { |s| s =~ /\A\d+\z/ ? Ok[s.to_i] : Fail["not a number"] }
result = bind(result)    { |n| n >= 0 ? Ok[n] : Fail["negative age"] }
result = bind(result)    { |n| Ok["#{n} years old"] }
# [:ok, "42 years old"]
```

### C++

```cpp
#include <expected>  // C++23
#include <string>

auto parse_age(const std::string& s) -> std::expected<int, std::string> {
    try { return std::stoi(s); }
    catch (...) { return std::unexpected("not a number"); }
}

auto validate_age(int n) -> std::expected<int, std::string> {
    return n >= 0 ? std::expected<int, std::string>{n}
                 : std::unexpected("negative age");
}

// C++23: and_then is bind for expected
auto result = parse_age("42")
    .and_then(validate_age)
    .and_then([](int n) -> std::expected<std::string, std::string> {
        return std::to_string(n) + " years old";
    });
// expected("42 years old")
```

### JavaScript

```js
const ok = (value) => ({ ok: true, value });
const fail = (error) => ({ ok: false, error });
const bind = (r, f) => (r.ok ? f(r.value) : r);

const result = bind(
  bind(
    bind(ok("42"), (s) => (isNaN(s) ? fail("not a number") : ok(Number(s)))),
    (n) => (n < 0 ? fail("negative age") : ok(n)),
  ),
  (n) => ok(`${n} years old`),
); // { ok: true, value: "42 years old" }
```

### Python

```py
def bind(result, f):
    ok, val = result
    return f(val) if ok else result

parse  = lambda s: (True, int(s)) if s.lstrip('-').isdigit() else (False, "not a number")
check  = lambda n: (True, n) if n >= 0 else (False, "negative age")
fmt    = lambda n: (True, f"{n} years old")

result = bind(bind(bind((True, "42"), parse), check), fmt)
# (True, "42 years old")
```

### Haskell

```hs
parseAge :: String -> Either String Int
parseAge s = case reads s of
    [(n, "")] -> Right n
    _         -> Left "not a number"

validateAge :: Int -> Either String Int
validateAge n
    | n >= 0    = Right n
    | otherwise = Left "negative age"

formatAge :: Int -> Either String String
formatAge n = Right (show n ++ " years old")

result :: Either String String
result = do
    n <- parseAge "42"        -- Right 42
    v <- validateAge n        -- Right 42
    formatAge v               -- Right "42 years old"
```
