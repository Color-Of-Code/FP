# Tooling Reference

## Prerequisites

| Tool             | Version   | Location                                              |
| ---------------- | --------- | ----------------------------------------------------- |
| `d2`             | 0.6.1+    | `~/.local/bin/d2`                                     |
| Node.js          | 24+       | `~/.nvm/versions/node/v24.12.0/bin/`                  |
| npm dev packages | see below | `.tools/node_modules/` (run `make -C .tools install`) |

Install npm packages once:

```sh
make -C .tools install
```

## Make targets

All targets must be run as `make -C .tools <target>` from the repo root, or `make <target>` from
inside `.tools/`.

| Target       | Command(s) invoked                                                   |
| ------------ | -------------------------------------------------------------------- |
| `install`    | `npm install` in `.tools/`                                           |
| `svgs`       | `d2 --layout=elk <src>.d2 <src>.svg` for every D2 file (incremental) |
| `fmt-d2`     | `d2 fmt` on all D2 sources and `styles.d2`                           |
| `fmt-md`     | `prettier --write "**/*.md"` (respects `.prettierrc`)                |
| `check-md`   | `prettier --check "**/*.md"` (read-only; for CI)                     |
| `lint-md`    | `markdownlint-cli2 "**/*.md"` (respects `.markdownlint.json`)        |
| `lint-langs` | `node .tools/check-lang-order.js`                                    |
| `fmt`        | `fmt-d2` + `fmt-md`                                                  |
| `all`        | `svgs` + `fmt` + `lint-md` + `lint-langs`                            |

**Minimum after any Markdown edit:** `make -C .tools fmt-md lint-md lint-langs`

**Minimum after any D2 edit:** `make -C .tools svgs` (then also `fmt-md lint-md lint-langs`)

## Linting rules (`.markdownlint.json`)

```json
{
  "default": true,
  "MD010": { "code_blocks": false },
  "MD013": { "line_length": 120, "tables": false, "code_blocks": false },
  "MD024": { "siblings_only": true },
  "MD033": false,
  "MD041": false
}
```

| Rule  | Setting                         | Reason                                              |
| ----- | ------------------------------- | --------------------------------------------------- |
| MD010 | `code_blocks: false`            | Go uses real tabs inside code; don't flag them      |
| MD013 | 120 chars; tables & code exempt | Long lines allowed in tables and code blocks        |
| MD024 | `siblings_only: true`           | Duplicate headings OK across different parents      |
| MD033 | off                             | HTML allowed (not used but not blocked)             |
| MD041 | off                             | First line need not be `# H1` (monad pages omit it) |

## Formatting rules (`.prettierrc`)

```json
{ "proseWrap": "always", "printWidth": 100, "tabWidth": 2 }
```

Prettier rewraps prose to 100 characters and uses 2-space indentation. It does **not** touch code
fences. Run `fmt-md` after every prose edit to keep diffs clean.

## Language-order checker (`.tools/check-lang-order.js`)

Validates that every `docs/*.md` and `docs/monads/*.md` file (except SKIP_FILES) contains:

- Exactly **one** `### <Lang>` heading per language
- All nine languages present
- Languages appear in the required order (C# → F# → Ruby → C++ → JavaScript → Python → Haskell →
  Rust → Go)

The checker normalises `C\#` → `C#` and `C\+\+` → `C++` before matching, so the escaped Markdown
forms are accepted.

**When the checker fails:**

- `Missing language X` — add the missing `### X` section with a code example.
- `Wrong order` — reorder the `###` sections to match the required sequence.
- `Duplicate heading` — remove or merge the duplicate `###` section.

Do not add a file to `SKIP_FILES` to silence the check. Only discussion chapters with no per-
language tutorial code belong there.

## D2 SVG compilation

The Makefile uses incremental builds (Make's implicit `.d2` → `.svg` rules). If you need to force a
rebuild of all SVGs:

```sh
touch docs/diagrams/*.d2 docs/monads/diagrams/*.d2
make -C .tools svgs
```

To compile a single diagram manually:

```sh
d2 --layout=elk docs/diagrams/foo.d2 docs/diagrams/foo.svg
```

SVG files are committed to the repository (they are the rendered artefacts referenced by Markdown
`![alt](path.svg)` links).
