# Tooling Reference

This page is the contributor-facing **reference** for `make -C .tools` targets. For pipeline
architecture, current state, and the design decisions behind the tooling, see
[.tools/docs/](../.tools/docs/README.md).

## Prerequisites

| Tool             | Version   | Location                                              |
| ---------------- | --------- | ----------------------------------------------------- |
| Node.js          | 24+       | `~/.nvm/versions/node/v24.12.0/bin/`                  |
| pnpm             | 10.28.2   | via Corepack, pinned in `.tools/package.json`         |
| npm dev packages | see below | `.tools/node_modules/` (run `make -C .tools install`) |

Install npm packages once:

```sh
make -C .tools install
```

## Make targets

All targets must be run as `make -C .tools <target>` from the repo root, or `make <target>` from
inside `.tools/`.

| Target          | What it does                                                             |
| --------------- | ------------------------------------------------------------------------ |
| `install`       | `pnpm install` in `.tools/` (recursively across the workspace)           |
| `svgs`          | Incrementally compile each SysML source to a sibling SVG                 |
| `sysml`         | Compile all SysML SVGs                                                   |
| `lint-diagrams` | Check SysML sources, SVGs, Markdown embeds, accessibility, and node size |
| `fmt-md`        | `prettier --write "**/*.md"` (respects `.prettierrc`)                    |
| `check-md`      | `prettier --check "**/*.md"` (read-only; for CI)                         |
| `lint-md`       | `markdownlint-cli2 "**/*.md"` (respects `.markdownlint.json`)            |
| `lint-langs`    | Check completeness and order of all nine language sections               |
| `fmt`           | `fmt-md`                                                                 |
| `lint`          | ESLint for TypeScript tooling                                            |
| `typecheck`     | `tsc --noEmit` for TypeScript tooling                                    |
| `test`          | Run Vitest parser, renderer, and behavior tests                          |
| `test-update`   | Refresh SVG snapshots after intentional renderer changes                 |
| `all`           | SVGs, format, diagram/Markdown/TS lint, typecheck, and tests             |

**Minimum after any Markdown edit:** `make -C .tools fmt-md lint-md lint-langs`

**Minimum after any SysML diagram edit:** `make -C .tools svgs lint-diagrams`

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

Validates that every `docs/*.md`, `docs/monads/*.md`, and `docs/optics/*.md` file (except
SKIP_FILES) contains:

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

## SysML SVG compilation

The Makefile incrementally compiles each `.sysml` source to a sibling `.svg`. To compile one diagram
manually:

```sh
node --experimental-strip-types .tools/sysml/cli.ts docs/19-monad/monad.sysml docs/19-monad/monad.svg
```

SVG files are committed to the repository (they are the rendered artefacts referenced by Markdown
`![alt](path.svg)` links).
