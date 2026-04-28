# `.tools/` documentation

Structured notes about the FP-repo build tooling: what it does, why it is shaped the way it is, and
which decisions are still in force.

The tooling lives entirely under [.tools/](..) and is invoked through `make -C .tools <target>` from
the repo root.

## Contents

- [architecture.md](architecture.md) — pipeline overview: SysML source → Langium parser → AST
  adapter → renderer → SVG, plus the supporting Make / pnpm / Vitest / VS Code-extension layers.
- [state.md](state.md) — current snapshot: what is built, what is tested, what works well, what
  doesn't. Update on any non-trivial structural change.
- [decisions/](decisions/README.md) — Architecture Decision Records (ADRs). One file per significant
  choice. Superseded ADRs stay in place for history.

See also the repo-level [AGENTS.md](../../AGENTS.md) and [specs/](../../specs/) directory for the
editorial / content rules of the FP track. Those rules drive several tooling decisions recorded
here.

## Reading order

1. [architecture.md](architecture.md) for the big picture.
2. [state.md](state.md) for what works today and the open issues.
3. Individual [decisions/](decisions/README.md) entries when you need the _why_ behind a specific
   choice.

## Updating

- New decision → add `decisions/NNNN-kebab-title.md` (next free number) and link it from
  [decisions/README.md](decisions/README.md).
- Decision becomes obsolete → set `Status: Superseded by NNNN` at the top of the old ADR and link
  forward; do **not** delete it.
- After any non-trivial structural change, update [state.md](state.md) in the same commit.
- Run `make -C .tools fmt-md lint-md` after editing.
