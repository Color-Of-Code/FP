# Agent Guidelines — FP Learning Track

This repo is a multi-language FP learning track. Every document explains one concept through prose,
a D2 diagram, motivation, and code examples in **all nine languages in a fixed order**.

See `specs/` for detailed specifications.

## Build system

All tooling lives in `.tools/`. Run from the repo root:

```sh
make -C .tools <target>
```

| Target       | What it does                                         |
| ------------ | ---------------------------------------------------- |
| `fmt-md`     | Format all Markdown with prettier                    |
| `lint-md`    | Lint all Markdown with markdownlint-cli2             |
| `lint-langs` | Check 9-language completeness and order in every doc |
| `svgs`       | Compile all D2 sources to SVG                        |
| `fmt`        | `fmt-md` + D2 formatter                              |
| `all`        | `svgs` + `fmt` + `lint-md` + `lint-langs`            |

**After every edit run at minimum:** `make -C .tools fmt-md lint-md lint-langs`

**After adding or editing any diagram:** also run `make -C .tools svgs`

## Key constraints — read before touching anything

1. **9 languages, fixed order**: every `docs/*.md` and `docs/monads/*.md` (except SKIP_FILES) must
   contain exactly one `### <Lang>` section per language in this order: `C#` → `F#` → `Ruby` → `C++`
   → `JavaScript` → `Python` → `Haskell` → `Rust` → `Go` See
   [`specs/languages.md`](specs/languages.md).

2. **File numbering is sequential**: `docs/NN-kebab-name.md`. Inserting a new concept in the middle
   requires renumbering all higher files, updating cross-links, and updating README. See
   [`specs/doc-structure.md`](specs/doc-structure.md).

3. **Every new concept diagram** must be referenced by the doc and compiled to SVG before commit.
   See [`specs/diagrams.md`](specs/diagrams.md).

4. **SKIP_FILES**: only discussion/comparison chapters (no tutorial code) belong in this set in
   `.tools/check-lang-order.js`. Do not add a file there to silence a check — fix the content.

5. **README table, monad catalogue, and optics catalogue** must be kept in sync with actual files.
   - `docs/monads/` — monad detail pages (linked from `docs/10-monad.md` and README)
   - `docs/optics/` — optic detail pages (linked from `docs/13-optics.md` and README) See
     [`specs/doc-structure.md`](specs/doc-structure.md).
