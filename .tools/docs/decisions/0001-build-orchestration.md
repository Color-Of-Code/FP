# 0001 — Build orchestration via Make + pnpm

- **Status**: Accepted
- **Date**: 2026-04-28

## Context

The repo is a multi-language FP learning track. Authors edit Markdown, diagrams (D2 + SysML), and a
small amount of TypeScript tooling. The build needs to:

- regenerate SVGs from D2 and SysML sources,
- format Markdown and D2 consistently,
- lint the 9-language ordering rule (see [AGENTS.md](../../../AGENTS.md)),
- type-check and snapshot-test the tooling itself,
- be runnable on any contributor laptop without per-OS scripts.

We considered: pure npm scripts; a TypeScript task runner like Just / Nx / Turbo; a hand-rolled Node
CLI.

## Decision

- Single [Makefile](../../Makefile) at `.tools/Makefile`, invoked from the repo root via
  `make -C .tools <target>`.
- pnpm workspace at `.tools/` with `vscode-sysml/` as a member.
- Node packages run via `pnpm exec` (replaces `npx`), keeping tool versions pinned by the lockfile.
- Toolchain pinned with `packageManager: "pnpm@10.28.2"` so Corepack picks the right version
  automatically.

Make wins because:

- targets express _file dependencies_ (`%.svg: %.sysml`), so partial rebuilds are free.
- it's already installed on every developer machine.
- the task list is short and stable; we don't need a JS DSL.

pnpm over npm because the workspace mode hoists the shared `langium`, `typescript`, etc. to
`.tools/node_modules`, avoiding duplicate installs in `.tools/vscode-sysml/`.

## Consequences

- All entry points live in one place; new task = one Make target + `.PHONY` entry.
- Contributors must have GNU Make and Node ≥ 22 with Corepack enabled.
- The pnpm lockfile is the source of truth; no per-sub-package lockfiles exist any more.
- `npx`-style ad-hoc tool invocations are discouraged outside the Makefile.

Related: [0002](0002-snapshot-tests.md), [0006](0006-local-vscode-extension.md).
