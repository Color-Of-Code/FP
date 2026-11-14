# Tooling for the FP repository
# Run from anywhere: make -C .tools <target>
# Or: cd .tools && make <target>

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
NODE_BIN  := $(REPO_ROOT)/.tools/node_modules/.bin

# Diagram sources are discovered recursively under docs/ at depth 2 or 3.
# Two wildcard patterns cover both the historical layout
# (docs/diagrams/, docs/monads/diagrams/, docs/optics/diagrams/) and the
# per-chapter folder convention (docs/<chapter>/, docs/<track>/<chapter>/).
# Adding a new diagram or chapter folder needs no Makefile edit.
SYSML_FILES := $(wildcard $(REPO_ROOT)/docs/*/*.sysml $(REPO_ROOT)/docs/*/*/*.sysml)
SYSML_SVGS  := $(SYSML_FILES:.sysml=.svg)

# Generator tooling: any change here invalidates every SysML SVG.
# Two wildcard patterns cover the whole tree (root + one subdir level).
# Pure make built-in — no shell-out — so it's effectively free.
SYSML_TOOL_SRCS := $(wildcard $(REPO_ROOT)/.tools/sysml/*.ts $(REPO_ROOT)/.tools/sysml/*/*.ts)

.PHONY: all svgs sysml lint-diagrams fmt-md lint-md lint-langs lint lint-fix check-md fmt install help test test-update coverage typecheck langium-gen vscode-ext vscode-ext-link

## Default: show help
help:
	@echo ""
	@echo "Usage: make -C .tools <target>"
	@echo ""
	@echo "Architecture, state, and decisions: see .tools/docs/README.md"
	@echo ""
	@echo "  install     Install dev dependencies via pnpm"
	@echo "  svgs        Regenerate all SysML SVG diagrams"
	@echo "  lint-diagrams  Check diagram sources, embeds, accessibility text, and size budget"
	@echo "  fmt-md      Format all Markdown files with prettier"
	@echo "  lint-md     Lint all Markdown files with markdownlint-cli2"
	@echo "  lint-langs  Check language-example completeness and order"
	@echo "  check-md    Check Markdown formatting without writing (CI-friendly)"
	@echo "  fmt         Format all Markdown"
	@echo "  lint        Lint TypeScript sources with ESLint"
	@echo "  lint-fix    Lint and auto-fix TypeScript sources"
	@echo "  test        Run vitest snapshot tests for the SysML pipeline"
	@echo "  test-update Refresh SVG snapshots after intentional changes"
	@echo "  coverage    Run tests with V8 code coverage report"
	@echo "  typecheck   Run tsc --noEmit on the .tools/ TypeScript sources"
	@echo "  langium-gen Regenerate the SysML parser/AST from sysml.langium"
	@echo "  vscode-ext  Build the local VS Code extension (highlighting + LSP)"
	@echo "  vscode-ext-link  Symlink the extension into ~/.vscode/extensions"
	@echo "  all         svgs + fmt + lint-md + lint-langs + lint-diagrams + lint + typecheck + test"
	@echo ""

## Install dependencies via pnpm (recursively across the workspace)
install:
	cd $(REPO_ROOT)/.tools && pnpm install

## Transpile SysML v2 sources to SVG (each SVG written next to its source)
sysml: $(SYSML_SVGS)

## Regenerate all SysML SVG diagrams
svgs: $(SYSML_SVGS)

# Static pattern rule: each .svg is built from its sibling .sysml.
# Works regardless of which directory the source lives in.
$(SYSML_SVGS): %.svg: %.sysml $(SYSML_TOOL_SRCS)
	node --experimental-strip-types $(REPO_ROOT)/.tools/sysml/cli.ts "$<" "$@"

## Format Markdown files
fmt-md: $(NODE_BIN)/prettier
	$(NODE_BIN)/prettier --write "$(REPO_ROOT)/**/*.md"

## Lint Markdown files
lint-md: $(NODE_BIN)/markdownlint-cli2
	cd $(REPO_ROOT) && $(NODE_BIN)/markdownlint-cli2 --config .markdownlint.json "docs/**/*.md" "ct/**/*.md" "specs/**/*.md" "README.md" "AGENTS.md" "#docs/.next/**"

## Check language-example sections are complete and in the correct order
lint-langs:
	node --experimental-strip-types $(REPO_ROOT)/.tools/check-lang-order.ts

## Check Markdown formatting without writing (for CI)
check-md: $(NODE_BIN)/prettier
	$(NODE_BIN)/prettier --check "$(REPO_ROOT)/**/*.md"

## Format Markdown
fmt: fmt-md

## Validate source/output/link consistency, accessibility text, and diagram size
lint-diagrams:
	node --experimental-strip-types $(REPO_ROOT)/.tools/check-diagrams.ts $(REPO_ROOT)

## Run vitest snapshot tests against the SVG corpus
test:
	cd $(REPO_ROOT)/.tools && pnpm exec vitest run

## Refresh SVG snapshots from current renderer output
test-update:
	cd $(REPO_ROOT)/.tools && pnpm exec vitest run -u

## Type-check all .tools/ TypeScript sources without emitting
typecheck:
	cd $(REPO_ROOT)/.tools && pnpm exec tsc --noEmit

## Regenerate the Langium parser from sysml.langium
langium-gen:
	cd $(REPO_ROOT)/.tools && pnpm exec langium generate

## Build the local VS Code extension (syntax highlighting + LSP server)
vscode-ext: langium-gen
	cd $(REPO_ROOT)/.tools && pnpm install --filter sysml-fp-local...
	mkdir -p $(REPO_ROOT)/.tools/vscode-sysml/syntaxes
	cp $(REPO_ROOT)/.tools/sysml/sysml.tmLanguage.json $(REPO_ROOT)/.tools/vscode-sysml/syntaxes/sysml.tmLanguage.json
	cd $(REPO_ROOT)/.tools/vscode-sysml && pnpm exec tsc -p .

## Symlink the built extension into the per-user extensions folder
vscode-ext-link: vscode-ext
	mkdir -p $$HOME/.vscode/extensions
	ln -sfn $(REPO_ROOT)/.tools/vscode-sysml $$HOME/.vscode/extensions/fp-local.sysml-fp-local-0.0.1
	@echo "  linked $$HOME/.vscode/extensions/fp-local.sysml-fp-local-0.0.1 -> $(REPO_ROOT)/.tools/vscode-sysml"
	@echo "  reload VS Code window to activate."

## Lint TypeScript sources with ESLint
lint:
	cd $(REPO_ROOT)/.tools && pnpm exec eslint .

## Lint and auto-fix TypeScript sources
lint-fix:
	cd $(REPO_ROOT)/.tools && pnpm exec eslint . --fix

## Run tests with V8 code coverage
coverage:
	cd $(REPO_ROOT)/.tools && pnpm exec vitest run --coverage

## Run everything
all: svgs fmt lint-md lint-langs lint-diagrams lint typecheck test

# Guard: remind to run install if node_modules is missing
$(NODE_BIN)/prettier $(NODE_BIN)/markdownlint-cli2:
	@echo "Dependencies not installed. Run: make -C .tools install"
	@exit 1
