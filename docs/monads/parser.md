# Parser Monad

The **Parser monad** models computations that **consume a sequence of input** — typically characters
— and either succeed, returning a parsed value alongside the unconsumed remainder, or fail.

![parser monad](diagrams/parser.svg)

## Type

```text
type Parser a = String -> Maybe (a, String)
```

A parser is a **function**: given an input string it returns either `Nothing` (failure) or
`Just (a, rest)` where `a` is the parsed result and `rest` is the input that was not consumed.

## How bind works

```text
bind :: Parser a -> (a -> Parser b) -> Parser b
bind p f = \input -> case p input of
    Nothing        -> Nothing          -- first parser failed: propagate
    Just (a, rest) -> f a rest         -- first parser succeeded: pass rest to next
```

Each step automatically threads the **remaining input** to the next parser. Failure short-circuits
immediately — exactly like the [Maybe monad](./maybe.md).

## Key operations

| Operation      | Description                                                        |
| -------------- | ------------------------------------------------------------------ |
| `pure x`       | Succeed without consuming input; return `x`                        |
| `item`         | Consume and return one character; fail on empty input              |
| `satisfy pred` | Consume one char if `pred` holds; fail otherwise                   |
| `many p`       | Zero or more applications of `p` (greedy, always succeeds)         |
| `many1 p`      | One or more; fails if `p` fails immediately                        |
| `p <\|> q`     | Try `p`; on failure without consuming input, try `q` (alternative) |
| `chainl1 p op` | Parse `p` separated by binary operator `op`; left-associative      |

## Key use cases

- Language parsers (JSON, CSV, config files, DSLs)
- Tokenisers and lexers
- Protocol message parsers
- Input validation with precise error locations
- Expression evaluators

## Motivation

Without the parser monad, each step must manually receive and pass on the remaining input string.
The plumbing overwhelms the grammar logic.

```text
-- Without Parser monad: rest threaded manually through every call
function parse_natural(input):
    r1 = parse_digit(input)
    if r1 == null: return null
    (d1, rest1) = r1
    r2 = parse_digit(rest1)     -- must use rest1, not input
    if r2 == null: return (d1, rest1)
    (d2, rest2) = r2
    return (d1 * 10 + d2, rest2)
-- Every sub-parser must accept AND return the remaining input.
```

```text
-- With Parser monad: bind handles remaining input automatically
natural = do
    d1 <- digit
    d2 <- optional digit         -- rest is threaded silently by bind
    return (combine d1 d2)
```

![parser motivation](diagrams/parser-motivation.svg)

## Examples

### C\#

```csharp
// Parser<T>: string -> (T value, string rest)?
static class Parse
{
    public static Func<string, (T Value, string Rest)?> Pure<T>(T value) =>
        input => (value, input);

    public static Func<string, (B Value, string Rest)?> Bind<A, B>(
        this Func<string, (A Value, string Rest)?> p,
        Func<A, Func<string, (B Value, string Rest)?>> f) =>
        input => p(input) is { } r ? f(r.Value)(r.Rest) : null;

    public static Func<string, (char Value, string Rest)?> Satisfy(Func<char, bool> pred) =>
        input => input.Length > 0 && pred(input[0]) ? (input[0], input[1..]) : null;

    public static Func<string, (string Value, string Rest)?> Many1(
        Func<string, (char Value, string Rest)?> p) =>
        input =>
        {
            var sb = new System.Text.StringBuilder();
            while (p(input) is { } r) { sb.Append(r.Value); input = r.Rest; }
            return sb.Length > 0 ? (sb.ToString(), input) : null;
        };
}

var digit  = Parse.Satisfy(char.IsDigit);
var digits = Parse.Many1(digit);   // one or more digit chars as a string

// Parse a natural number: "42 rest" -> (42, " rest")
var natural = digits.Bind(ds => Parse.Pure(int.Parse(ds)));
var result  = natural("42 rest"); // (Value: 42, Rest: " rest")
```

### F\#

FParsec is the standard F# parser combinator library. The hand-rolled version below uses a
computation expression to show the monad structure explicitly.

```fsharp
// Using FParsec (idiomatic F#)
open FParsec

let natural : Parser<int, unit> = pint32   // built-in integer parser

let pair : Parser<int * string, unit> =
    pint32 .>> spaces .>>. many1Chars asciiLetter

let result = run pair "42 alice"
// Success: (42, "alice")

// --- Hand-rolled parser monad with computation expression ---
type Parser<'a> = string -> ('a * string) option

let bind (p : Parser<'a>) (f : 'a -> Parser<'b>) : Parser<'b> =
    fun input ->
        match p input with
        | None           -> None
        | Some (a, rest) -> f a rest

type ParseBuilder() =
    member _.Bind(p, f) = bind p f
    member _.Return x   = fun input -> Some (x, input)

let parse = ParseBuilder()

let satisfy pred : Parser<char> =
    fun input ->
        if input.Length > 0 && pred input.[0]
        then Some (input.[0], input.[1..])
        else None

let digit  = satisfy System.Char.IsDigit
let letter = satisfy System.Char.IsLetter

let digitThenLetter : Parser<char * char> = parse {
    let! d = digit
    let! l = letter
    return (d, l)
}
// digitThenLetter "3x" -> Some (('3', 'x'), "")
```

### Ruby

```ruby
# Parser: String -> [value, rest] | nil

def satisfy(&pred)
  ->(input) { !input.empty? && pred.call(input[0]) ? [input[0], input[1..]] : nil }
end

def many1(parser)
  ->(input) {
    chars = []
    while (r = parser.call(input))
      chars << r[0]
      input = r[1]
    end
    chars.empty? ? nil : [chars.join, input]
  }
end

def bind(parser, &f)
  ->(input) {
    r = parser.call(input)
    r ? f.call(r[0]).call(r[1]) : nil
  }
end

def pure(value)
  ->(input) { [value, input] }
end

digit  = satisfy { |c| c =~ /\d/ }
digits = many1(digit)

# Parse a natural number: "42 rest" -> [42, " rest"]
natural = bind(digits) { |ds| pure(ds.to_i) }
result  = natural.call("42 rest")
# [42, " rest"]
```

### C++

```cpp
#include <functional>
#include <optional>
#include <string>
#include <cctype>

template <typename T>
using ParseResult = std::optional<std::pair<T, std::string>>;
template <typename T>
using Parser = std::function<ParseResult<T>(std::string)>;

template <typename T>
Parser<T> pure(T value) {
    return [value](std::string input) -> ParseResult<T> {
        return std::make_pair(value, input);
    };
}

template <typename A, typename B>
Parser<B> bind(Parser<A> p, std::function<Parser<B>(A)> f) {
    return [p, f](std::string input) -> ParseResult<B> {
        auto r = p(input);
        if (!r) return std::nullopt;
        return f(r->first)(r->second);
    };
}

Parser<char> satisfy(std::function<bool(char)> pred) {
    return [pred](std::string input) -> ParseResult<char> {
        if (input.empty() || !pred(input[0])) return std::nullopt;
        return std::make_pair(input[0], input.substr(1));
    };
}

Parser<std::string> many1(Parser<char> p) {
    return [p](std::string input) -> ParseResult<std::string> {
        std::string acc;
        while (auto r = p(input)) { acc += r->first; input = r->second; }
        if (acc.empty()) return std::nullopt;
        return std::make_pair(acc, input);
    };
}

auto digit  = satisfy([](char c) { return std::isdigit(static_cast<unsigned char>(c)) != 0; });
auto digits = many1(digit);

// Parse a natural number: "42 rest" -> (42, " rest")
auto natural = bind<std::string, int>(
    digits, [](std::string ds) { return pure(std::stoi(ds)); });

auto result = natural("42 rest");
// {42, " rest"}
```

### JavaScript

```js
// Parser: string -> [value, rest] | null

const satisfy = (pred) => (input) =>
  input.length > 0 && pred(input[0]) ? [input[0], input.slice(1)] : null;

const many1 = (parser) => (input) => {
  const chars = [];
  let rest = input;
  let r;
  while ((r = parser(rest)) !== null) {
    chars.push(r[0]);
    rest = r[1];
  }
  return chars.length > 0 ? [chars.join(""), rest] : null;
};

const bind = (p, f) => (input) => {
  const r = p(input);
  return r === null ? null : f(r[0])(r[1]);
};

const pure = (value) => (input) => [value, input];

const digit = satisfy((c) => /\d/.test(c));
const digits = many1(digit); // one or more digits as a string

// Parse a natural number: "42 rest" -> [42, " rest"]
const natural = bind(digits, (ds) => pure(parseInt(ds, 10)));
const result = natural("42 rest");
// [42, " rest"]
```

### Python

```py
# Parser: str -> (value, rest) | None

def satisfy(pred):
    return lambda s: (s[0], s[1:]) if s and pred(s[0]) else None

def many1(parser):
    def run(s):
        chars = []
        while r := parser(s):
            chars.append(r[0])
            s = r[1]
        return (''.join(chars), s) if chars else None
    return run

def bind(parser, f):
    return lambda s: (lambda r: f(r[0])(r[1]) if r else None)(parser(s))

def pure(value):
    return lambda s: (value, s)

digit  = satisfy(str.isdigit)
digits = many1(digit)

# Parse a natural number: "42 rest" -> (42, ' rest')
natural = bind(digits, lambda ds: pure(int(ds)))
result  = natural("42 rest")
# (42, ' rest')
```

### Haskell

```hs
import Control.Applicative (Alternative(..))
import Data.Char           (isDigit, isAlpha)

newtype Parser a = Parser { runParser :: String -> Maybe (a, String) }

instance Functor Parser where
    fmap f (Parser p) = Parser $ fmap (\(a, s) -> (f a, s)) . p

instance Applicative Parser where
    pure x    = Parser $ \input -> Just (x, input)
    pf <*> px = Parser $ \input -> do
        (f, rest1) <- runParser pf input
        (x, rest2) <- runParser px rest1
        return (f x, rest2)

instance Monad Parser where
    return = pure
    Parser p >>= f = Parser $ \input -> do
        (a, rest) <- p input
        runParser (f a) rest

instance Alternative Parser where
    empty   = Parser $ const Nothing
    p <|> q = Parser $ \input ->
        case runParser p input of
            Nothing -> runParser q input
            result  -> result

satisfy :: (Char -> Bool) -> Parser Char
satisfy pred = Parser $ \case
    (c : rest) | pred c -> Just (c, rest)
    _                   -> Nothing

digit  = satisfy isDigit
letter = satisfy isAlpha

many1 :: Parser a -> Parser [a]
many1 p = (:) <$> p <*> many p

natural :: Parser Int
natural = read <$> many1 digit

-- do-notation reads like a grammar rule
pair :: Parser (Int, String)
pair = do
    n    <- natural
    _    <- satisfy (== ' ')
    word <- many1 letter
    return (n, word)

-- runParser pair "42 alice" == Just ((42, "alice"), "")
```

### Rust

```rust
// Minimal parser combinators using closures.
// For production, use the `nom` or `winnow` crates.

fn satisfy<'a>(pred: impl Fn(char) -> bool + 'a) -> impl Fn(&'a str) -> Option<(char, &'a str)> {
    move |input| {
        let mut chars = input.chars();
        let c = chars.next()?;
        if pred(c) { Some((c, chars.as_str())) } else { None }
    }
}

fn many1<'a>(
    parser: impl Fn(&'a str) -> Option<(char, &'a str)> + 'a,
) -> impl Fn(&'a str) -> Option<(String, &'a str)> {
    move |mut input| {
        let mut buf = String::new();
        while let Some((c, rest)) = parser(input) {
            buf.push(c);
            input = rest;
        }
        if buf.is_empty() { None } else { Some((buf, input)) }
    }
}

fn bind<'a, A, B>(
    p: impl Fn(&'a str) -> Option<(A, &'a str)> + 'a,
    f: impl Fn(A) -> Box<dyn Fn(&'a str) -> Option<(B, &'a str)> + 'a> + 'a,
) -> impl Fn(&'a str) -> Option<(B, &'a str)> + 'a {
    move |input| {
        let (a, rest) = p(input)?;
        f(a)(rest)
    }
}

let digit_p  = satisfy(|c| c.is_ascii_digit());
let digits_p = many1(digit_p);

// Parse a natural number: "42 rest" -> Some((42, " rest"))
let natural = bind(digits_p, |ds: String| {
    Box::new(move |rest: &str| ds.parse::<u32>().ok().map(|n| (n, rest)))
});

let result = natural("42 rest"); // Some((42, " rest"))

// With nom (idiomatic Rust):
// use nom::{character::complete::digit1, combinator::map_res};
// let natural = map_res(digit1, str::parse::<u32>);
// natural("42 rest") -> Ok((" rest", 42))
```

### Go

```go
import (
	"strconv"
	"unicode"
)

// Parser[T]: string -> (T, string, bool)
type ParseResult[T any] struct {
	Value T
	Rest  string
	OK    bool
}

type Parser[T any] func(string) ParseResult[T]

func Satisfy(pred func(rune) bool) Parser[rune] {
	return func(input string) ParseResult[rune] {
		runes := []rune(input)
		if len(runes) > 0 && pred(runes[0]) {
			return ParseResult[rune]{Value: runes[0], Rest: string(runes[1:]), OK: true}
		}
		return ParseResult[rune]{}
	}
}

func Many1(p Parser[rune]) Parser[string] {
	return func(input string) ParseResult[string] {
		var runes []rune
		for {
			r := p(input)
			if !r.OK {
				break
			}
			runes = append(runes, r.Value)
			input = r.Rest
		}
		if len(runes) == 0 {
			return ParseResult[string]{}
		}
		return ParseResult[string]{Value: string(runes), Rest: input, OK: true}
	}
}

func Bind[A, B any](p Parser[A], f func(A) Parser[B]) Parser[B] {
	return func(input string) ParseResult[B] {
		r := p(input)
		if !r.OK {
			return ParseResult[B]{}
		}
		return f(r.Value)(r.Rest)
	}
}

digit  := Satisfy(func(r rune) bool { return unicode.IsDigit(r) })
digits := Many1(digit) // Parser[string]

// Parse a natural number: "42 rest" -> {42, " rest", true}
natural := Bind(digits, func(ds string) Parser[int] {
	return func(rest string) ParseResult[int] {
		n, err := strconv.Atoi(ds)
		if err != nil {
			return ParseResult[int]{}
		}
		return ParseResult[int]{Value: n, Rest: rest, OK: true}
	}
})

result := natural("42 rest") // {42, " rest", true}
```
