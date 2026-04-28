# 0006 — Local-only VS Code extension

- **Status**: Accepted
- **Date**: 2026-04-28

## Context

Once the parser moved to Langium ([0003](0003-langium-parser.md)), the ingredients for editor
support were already on disk: a TextMate grammar and an LSP-capable language server. The remaining
question was how to ship them to contributors without taking on the cost of a published extension.

Constraints:

- No marketplace / publisher account.
- No telemetry, no auto-update.
- Must not require building anything outside `.tools/`.
- Should be uninstalled with one command.

## Decision

- Self-contained extension at [.tools/vscode-sysml/](../../vscode-sysml/), part of the pnpm
  workspace.
- Two install paths, both fully local:
  - `make -C .tools vscode-ext-link` symlinks the folder into
    `~/.vscode/extensions/fp-local.sysml-fp-local-0.0.1/`.
  - `pnpm dlx @vscode/vsce package` produces a `.vsix` that `code --install-extension` consumes. The
    `.vsix` is just a zip; nothing is uploaded.
- Provides:
  - Syntax highlighting via the langium-cli-emitted `sysml/sysml.tmLanguage.json` (copied into
    `vscode-sysml/syntaxes/`).
  - Parse-error diagnostics via a thin LSP client (`extension.ts`) + server (`server.ts`) that
    re-uses the same generated module as the CLI.
- The extension's tsconfig pulls in `../sysml/generated/**/*` so the LSP server is bundled with the
  latest grammar artefacts on every build.

## Consequences

- Contributors get highlighting + live diagnostics with one Make target and a window reload.
- No marketplace lifecycle to manage; no registered publisher; no CI release pipeline.
- Re-build required after any grammar change (`make -C .tools vscode-ext`). Acceptable because the
  grammar rarely changes.
- The extension cannot be searched / installed by non-contributors. By design.

Related: [0003](0003-langium-parser.md), [0001](0001-build-orchestration.md).
