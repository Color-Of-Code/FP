# Authoring SysML diagrams — what to care about

This is a **principles document** for writing new `.sysml` source files for this repo. For the
mechanical syntax reference (which keywords exist, which `show as <role>` values are valid, file
layout, etc.) see [`specs/diagrams.md`](../../specs/diagrams.md). For the rendering pipeline see
[`architecture.md`](architecture.md).

The advice below is generic — it applies regardless of the FP concept being diagrammed. It captures
lessons learned while authoring the existing corpus and is the checklist to run before committing a
new diagram.

---

## 1. Tell the truth about the runtime

A diagram of a function's body is a **specification of its runtime behaviour**. If the rendered
picture shows something the code does not actually do (or hides something it does), the diagram is
wrong, even if it parses, lints, and looks pretty.

Concretely:

- **One output node per output of the type signature.** A function `f :: A → B → C` has exactly one
  result; the activity must end at exactly one terminal `object`. Two parallel "result A / result B"
  outputs in the same diagram are almost always a lie — pick the one the type signature promises.
- **Make every decision visible.** Pattern matches, guards, error short-circuits, retry / orElse
  fallbacks, alternative parsers, monoid empty checks — anything that the runtime branches on must
  be a `decision` node with labelled guard edges, not a black-box `action`.
- **Make every join visible.** Whenever two or more branches must converge into a single result, use
  a `merge` node. The merge documents the invariant "exactly one inflow fires per invocation; both
  produce values of the same type".
- **Make type-changing-without-value-changing steps visible.** Re-tagging a constructor (e.g. the
  static type widens from `Left e` to `Either e b` while the runtime value is bit-identical) is a
  real semantic step. Give it its own `action` node so readers see _where_ the type changes.
- **Do not invent steps the runtime does not perform.** A separate "unwrap" action after a pattern
  match is a lie when the language's pattern syntax destructures in the same step.

If a diagram looks like a black box with a couple of input arrows and a couple of output arrows, it
is almost certainly wrong. Open the box.

## 2. Name operations, not operators

The activity-frame tab is the **canonical name** of the type-class operation:

- `bind`, `pure`, `tell`, `ask`, `local`, `get`, `put`, `modify`, `retry`, `orElse`, `callCC`,
  `alt`, …

Never put an operator symbol there:

- ❌ `>>=`, `<|>`, `>=>`, `>>`, `<*>`, `<$>`, `*>`
- ❌ `flatMap`, `andThen`, `SelectMany` — these are language aliases, not the canonical name.

Per-language and operator aliases belong in the **title** as a suffix:

```text
title = "bind :: Ma ⟶ (a ⟶ Mb) ⟶ Mb   — also called: flatMap, andThen / and_then, SelectMany, >>="
```

Rationale: the tab is read first and seen at a glance. Operators are noisy at small sizes, are not
universal across languages, and do not survive translation to other notations. Names do.

## 3. Identifiers must not collide with reserved keywords

The Langium grammar reserves the lowercase keywords used for SysML constructs. Common collisions:

- `in`, `out`, `inout` — direction modifiers
- `flow`, `from`, `to`, `via` — flow / connection syntax
- `package`, `part`, `port`, `action`, `activity`, `object`, `decision`, `merge`, `connection`,
  `def`, `succession`, `then`
- `as`, `show`, `tooltip`, `render`, `type`, `name`, `direction`, `layout`, `title`

If you need a node whose conceptual name is one of these, **prefix or suffix** it: `out` →
`outResult`, `right_a0`, `result_b`. The parse error will be cryptic
(`Expecting one of these possible Token sequences`) — when you see it, scan the file for any
identifier matching the list above before suspecting the grammar.

## 4. Choose the right diagram type

| If you need to show…                           | Use      |
| ---------------------------------------------- | -------- |
| The static type signature, parts wired by type | IBD      |
| Runtime behaviour, control flow, branches      | activity |

Mixing them is wrong. An IBD with a `decision` node, or an activity that uses `connection connect`
instead of `flow from`, is a category error. Pick one and commit.

For every new combinator with a polymorphic HOF signature, author **both** — the IBD shows the
contract, the activity shows the execution.

## 5. Tooltips explain semantics, not syntax

Tooltips are the place to put the things the picture cannot show:

- **What this node represents at runtime** ("the unwrapped success payload, only exists on the Right
  branch").
- **What the law/invariant is** ("exactly one branch fires per invocation; the merge is a
  control-flow join, not a runtime choice").
- **What is _not_ happening** ("f does not see the error; widening allocates nothing").
- **Per-monad / per-language realisation** when the diagram is generic (`pure` → `Just a`,
  `Right a`, `[a]`, `\s -> (a, s)`, …).

Do **not** use tooltips to restate the visible label of the node — that adds clutter without
information.

## 6. Edge labels are part of the contract

Every conditional edge out of a `decision` carries a guard label that names which case it covers.
Every short-circuit edge says what it does to the value:

```text
flow from matchEa to a0  : "Right a0";
flow from matchEa to e0  : "Left e0  (f skipped)";
flow from widen   to ec  : "Left e0 : Either e b";
```

Three good reasons to label an edge:

1. **It carries a value with a non-obvious shape** (e.g. `"f(a0) — Right b' or Left e'"`).
2. **It carries a guard** (e.g. `"Right a0"`, `"Nothing"`, `"on retry"`).
3. **It documents the type at this point** (e.g. `"\\s -> (a0, s)"`, `"[(a0, 1.0)]"`).

Unlabelled edges are fine when the source and target are unambiguous; do not add labels just to fill
space.

## 7. Generic vs. concrete: keep them separate

The repo distinguishes two rendering layers:

- **Generic, type-class-level diagrams** in `docs/diagrams/` — the operation as the abstract
  interface declares it (e.g. the chapter-intro `bind`, `pure`).
- **Concrete, per-instance diagrams** in `docs/monads/diagrams/` — the same operation realised by a
  specific monad with all its branches and type changes.

Each layer must be honest about what it shows: a generic `bind` should not show
`Right a → f(a) | Left e → Left e` (that is `Either`-specific); an Either-specific `bind` must show
exactly that.

When both exist for the same operation, the per-instance one supersedes the generic one for
correctness — but do not delete the generic. Readers approach the chapter top-down.

## 8. Variables and types — use the language of the chapter

Match the variable names used in the prose of the chapter / monad page:

- `ma`, `mb` for monadic values
- `a0`, `b0`, `b1`, `b2` for plain payloads
- `s`, `s'`, `s''` (or `s0`/`s1`/`s2`) for state threads
- `wa` for Writer pairs `(a, w)`
- `e0` for an Either error payload
- `r` for a Reader environment
- `k` for a continuation

Diagrams that invent fresh names (`x`, `y`, `tmp`) detach from the prose and slow the reader down.

## 9. Layout

- Default to ELK (`layout = elk`) for any diagram with **branching, merging, or a HOF skipping
  multiple ranks**. Dagre often produces overlapping edges in those cases.
- Use `direction = TB` (top-to-bottom) only when you have an enumerated, step-numbered computation;
  otherwise keep the default left→right.
- Do not over-constrain layout. The `succession … then …` ordering is for control-flow ordering
  only; it is not a positioning hint.

## 10. Verify before committing

Workflow for a new `.sysml` file:

1. Run `cd .tools && pnpm exec vitest run -u` — this both validates the parse (AST snapshot) and
   re-renders all SVGs (visual snapshot). A failing parse appears as a parser-test failure with
   `Expecting one of these possible Token sequences` — almost always a reserved-keyword or typo
   issue.
2. Open the rendered `.svg` in a browser and walk through it node by node, asking: _does each
   visible element correspond to something the runtime actually does, and is anything the runtime
   does missing?_
3. Run `make -C .tools fmt-md lint-md lint-langs` — catches markdown drift and (for `docs/*.md`
   chapters) the 9-language ordering check.
4. Commit. Snapshot churn from a title or tab-name edit is expected and harmless.

`make -C .tools sysml` is currently broken under Node 24 (the Langium-generated module imports
`./generated/module.js` which the strip-types loader does not remap to `.ts`). The vitest pipeline
is the canonical render path for now.

---

## Anti-patterns (look here when something feels off)

| Smell                                                                        | Likely fix                                                              |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Diagram has two output nodes but the function returns one value              | Add a `merge` node; the second output was a control-flow branch         |
| Tab labelled `>>=` / `<\|>` / `>=>`                                          | Rename the tab to the operation's name, move operator into title suffix |
| Pattern match collapsed into a single `bind` action                          | Replace with `decision` node + guard-labelled outflows + `merge` join   |
| `Expecting one of these possible Token sequences` parse error                | An identifier collides with a reserved keyword (e.g. `out`, `in`)       |
| Diagram says `Just a → f(a)` for a generic monad                             | Move that diagram into `monads/diagrams/`; keep the generic abstract    |
| Tooltip restates the node label                                              | Replace with semantics: invariants, what-doesn't-happen, per-instance   |
| HOF argument (`f : a → Mb`) drawn as an `action` node                        | It is data — model as `object` with `show f as hof`                     |
| Type-widening / re-tagging step (`Left e ⟶ Either e b`) absent from activity | Add a small `action` node for it; tooltip explains "value identical"    |
| `make -C .tools sysml` red                                                   | Use `pnpm exec vitest run -u` from `.tools/`; that path works           |
