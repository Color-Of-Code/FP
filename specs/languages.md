# Language Example Conventions

## The nine languages

Every `docs/*.md` and `docs/monads/*.md` (except SKIP_FILES) must contain **exactly one `###`
section heading per language, in this exact order**:

| #   | Language   | `###` heading to use |
| --- | ---------- | -------------------- |
| 1   | C#         | `### C\#`            |
| 2   | F#         | `### F\#`            |
| 3   | Ruby       | `### Ruby`           |
| 4   | C++        | `### C++`            |
| 5   | JavaScript | `### JavaScript`     |
| 6   | Python     | `### Python`         |
| 7   | Haskell    | `### Haskell`        |
| 8   | Rust       | `### Rust`           |
| 9   | Go         | `### Go`             |

`check-lang-order.js` enforces this. It normalises `C\#` → `C#` and `C\+\+` → `C++` when matching,
so write the escaped forms in Markdown headings.

## SKIP_FILES

Files in `SKIP_FILES` (`.tools/check-lang-order.js`) are exempt from the language check. Currently:

```js
const SKIP_FILES = new Set(["01-function.md", "12-effects.md"]);
```

- `01-function.md` — introductory overview, not a per-language tutorial.
- `12-effects.md` — comparison/discussion chapter covering only Haskell and F#.

**Do not add a file to SKIP_FILES to silence an error.** Fix the content instead. A file belongs in
SKIP*FILES only when it is a \_discussion* document that deliberately does not have per-language
tutorial code.

## Per-language style rules

### General

- Each language section contains **one or more code blocks** using the language's fence tag:
  ` ```csharp `, ` ```fsharp `, ` ```ruby `, ` ```cpp `, ` ```js `, ` ```python `, ` ```hs `,
  ` ```rust `, ` ```go `.
- Use ` ```text ` for pseudo-code or notation that is not any specific language.
- Follow the idiom of the language — do not just transliterate Haskell into every other language.
- If a concept has no standard library support in a language, show a minimal hand-rolled version and
  add a comment naming the well-known library (e.g. `// see: LanguageExt`, `// see: arrow-kt`).

### C\#

- Target .NET 8+ idioms: `record`, pattern matching with `switch` expressions, nullable reference
  types, collection expressions.
- Prefer `record` over `class` for immutable data.
- Use LINQ (`Select`, `Where`, `Aggregate`) for collection operations.

### F\#

- Use idiomatic pipeline style (`|>`) and `match` expressions.
- Prefer modules and `let` bindings over classes.
- Computation expressions (`async { }`, `seq { }`) where appropriate.

### Ruby

- Idiomatic Ruby: blocks, lambdas, `Struct`, `freeze` for immutable records.
- Pattern matching with `case/in` (Ruby 3+) is preferred over nested `if/case/when`.

### C++

- Target C++17 or later. Use `std::variant`, `std::optional`, `std::function`.
- Prefer `std::visit` + lambdas over hand-rolled visitors.
- Use `auto` and structured bindings where they improve clarity.

### JavaScript

- Target ES2020+. Use arrow functions, destructuring, `const`/`let`.
- Do not assume a framework; show plain JS.
- Where a popular library exists (e.g. `fp-ts`, `monocle-ts`), mention it in a comment.

### Python

- Target Python 3.10+. Use `match`/`case` (structural pattern matching) for ADT-style code.
- Use `@dataclass(frozen=True)` for immutable records.
- Use type hints in function signatures.
- Where a popular library exists (e.g. `returns`, `lenses`), mention it in a comment.

### Haskell

- Haskell is the canonical reference language. Show the most idiomatic GHC version.
- Use `deriving` (`Functor`, `Show`, `Eq`) where applicable.
- Use `do`-notation for monadic chains.
- Mention relevant packages in comments (`recursion-schemes`, `lens`, `mtl`, etc.).

### Rust

- Target stable Rust. Use `enum`, `impl`, closures, `Box<T>` for recursive types.
- Ownership and borrowing constraints are often the interesting story — don't hide them.
- Where a library exists (e.g. `lens-rs`, `recursion`), mention it in a comment.

### Go

- Go uses **tabs for indentation** inside code — do not convert to spaces. The markdownlint config
  has `"MD010": { "code_blocks": false }` specifically to allow this.
- Use `interface{}` / `any` + type-switch for sum-type-like dispatch.
- Generics (`[T any]`) are available (Go 1.18+); prefer them over `interface{}` where cleaner.
- Standard library only unless a comment names a notable library.
