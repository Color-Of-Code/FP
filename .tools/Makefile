# Tooling for the FP repository
# Run from anywhere: make -C .tools <target>
# Or: cd .tools && make <target>

REPO_ROOT   := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
DOCS_DIAG   := $(REPO_ROOT)/docs/diagrams
MONAD_DIAG  := $(REPO_ROOT)/docs/monads/diagrams
OPTIC_DIAG  := $(REPO_ROOT)/docs/optics/diagrams
NODE_BIN    := $(REPO_ROOT)/.tools/node_modules/.bin

# styles.d2 lives alongside the diagrams under docs/
STYLES := $(REPO_ROOT)/docs/styles.d2

# SysML v2 source files (transpile to SVG via sysml/cli.ts)
SYSML_FILES_DOCS   := $(wildcard $(DOCS_DIAG)/*.sysml)
SYSML_FILES_MONADS := $(wildcard $(MONAD_DIAG)/*.sysml)
SYSML_FILES        := $(SYSML_FILES_DOCS) $(SYSML_FILES_MONADS)
SYSML_SVGS         := $(patsubst %.sysml,%.svg,$(SYSML_FILES))

# D2 source files in each location
D2_FILES_DOCS   := $(wildcard $(DOCS_DIAG)/*.d2)
D2_FILES_MONADS := $(wildcard $(MONAD_DIAG)/*.d2)
D2_FILES_OPTICS := $(wildcard $(OPTIC_DIAG)/*.d2)

D2_FILES_ALL := $(D2_FILES_DOCS) $(D2_FILES_MONADS) $(D2_FILES_OPTICS)

DIAGRAM_SVG := $(D2_FILES_DOCS:.d2=.svg) \
               $(D2_FILES_MONADS:.d2=.svg) \
               $(D2_FILES_OPTICS:.d2=.svg)

.PHONY: all svgs fmt-d2 fmt-md lint-md lint-langs check-md fmt install help test test-update typecheck langium-gen vscode-ext vscode-ext-link

## Default: show help
help:
	@echo ""
	@echo "Usage: make -C .tools <target>"
	@echo ""
	@echo "  install     Install npm dev dependencies"
	@echo "  svgs        Regenerate all SVG diagrams from D2 sources"
	@echo "  fmt-d2      Format all D2 source files"
	@echo "  fmt-md      Format all Markdown files with prettier"
	@echo "  lint-md     Lint all Markdown files with markdownlint-cli2"
	@echo "  lint-langs  Check language-example completeness and order"
	@echo "  check-md    Check Markdown formatting without writing (CI-friendly)"
	@echo "  fmt         Format both D2 and Markdown"
	@echo "  test        Run vitest snapshot tests for the SysML pipeline"
	@echo "  test-update Refresh SVG snapshots after intentional changes"
	@echo "  typecheck   Run tsc --noEmit on the .tools/ TypeScript sources"
	@echo "  langium-gen Regenerate the SysML parser/AST from sysml.langium"
	@echo "  vscode-ext  Build the local VS Code extension (highlighting + LSP)"
	@echo "  vscode-ext-link  Symlink the extension into ~/.vscode/extensions"
	@echo "  all         svgs + fmt + lint-md"
	@echo ""

## Install npm dependencies
install:
	cd $(REPO_ROOT)/.tools && npm install

## Transpile SysML v2 sources to SVG
sysml: $(SYSML_SVGS)

$(DOCS_DIAG)/%.svg: $(DOCS_DIAG)/%.sysml
	node --experimental-strip-types $(REPO_ROOT)/.tools/sysml/cli.ts "$<" "$@"

$(MONAD_DIAG)/%.svg: $(MONAD_DIAG)/%.sysml
	node --experimental-strip-types $(REPO_ROOT)/.tools/sysml/cli.ts "$<" "$@"

## Regenerate all SVG diagrams
svgs: $(DIAGRAM_SVG)

# Rule for docs/diagrams/ diagrams (depend on styles.d2)
$(DOCS_DIAG)/%.svg: $(DOCS_DIAG)/%.d2 $(STYLES)
	d2 --layout=elk "$<" "$@"
	@echo "  generated $@"

# Rule for docs/monads/diagrams/ diagrams (depend on styles.d2)
$(MONAD_DIAG)/%.svg: $(MONAD_DIAG)/%.d2 $(STYLES)
	d2 --layout=elk "$<" "$@"
	@echo "  generated $@"

# Rule for docs/optics/diagrams/ diagrams (depend on styles.d2)
$(OPTIC_DIAG)/%.svg: $(OPTIC_DIAG)/%.d2 $(STYLES)
	d2 --layout=elk "$<" "$@"
	@echo "  generated $@"

## Format D2 source files (uses d2 fmt built-in)
fmt-d2:
	d2 fmt $(D2_FILES_ALL) $(STYLES)
	@echo "  formatted D2 files"

## Format Markdown files
fmt-md: $(NODE_BIN)/prettier
	$(NODE_BIN)/prettier --write "$(REPO_ROOT)/**/*.md"

## Lint Markdown files
lint-md: $(NODE_BIN)/markdownlint-cli2
	$(NODE_BIN)/markdownlint-cli2 "$(REPO_ROOT)/**/*.md" "!$(REPO_ROOT)/.tools/node_modules/**"

## Check language-example sections are complete and in the correct order
lint-langs:
	node --experimental-strip-types $(REPO_ROOT)/.tools/check-lang-order.ts

## Check Markdown formatting without writing (for CI)
check-md: $(NODE_BIN)/prettier
	$(NODE_BIN)/prettier --check "$(REPO_ROOT)/**/*.md"

## Format everything
fmt: fmt-d2 fmt-md

## Run vitest snapshot tests against the SVG corpus
test:
	cd $(REPO_ROOT)/.tools && npx vitest run

## Refresh SVG snapshots from current renderer output
test-update:
	cd $(REPO_ROOT)/.tools && npx vitest run -u

## Type-check all .tools/ TypeScript sources without emitting
typecheck:
	cd $(REPO_ROOT)/.tools && npx tsc --noEmit

## Regenerate the Langium parser from sysml.langium
langium-gen:
	cd $(REPO_ROOT)/.tools && npx langium generate

## Build the local VS Code extension (syntax highlighting + LSP server)
vscode-ext: langium-gen
	cd $(REPO_ROOT)/.tools/vscode-sysml && npm install --no-audit --no-fund
	mkdir -p $(REPO_ROOT)/.tools/vscode-sysml/syntaxes
	cp $(REPO_ROOT)/.tools/sysml/sysml.tmLanguage.json $(REPO_ROOT)/.tools/vscode-sysml/syntaxes/sysml.tmLanguage.json
	cd $(REPO_ROOT)/.tools/vscode-sysml && npx tsc -p .

## Symlink the built extension into the per-user extensions folder
vscode-ext-link: vscode-ext
	mkdir -p $$HOME/.vscode/extensions
	ln -sfn $(REPO_ROOT)/.tools/vscode-sysml $$HOME/.vscode/extensions/fp-local.sysml-fp-local-0.0.1
	@echo "  linked $$HOME/.vscode/extensions/fp-local.sysml-fp-local-0.0.1 -> $(REPO_ROOT)/.tools/vscode-sysml"
	@echo "  reload VS Code window to activate."

## Run everything
all: svgs sysml fmt lint-md lint-langs typecheck test

# Guard: remind to run install if node_modules is missing
$(NODE_BIN)/prettier $(NODE_BIN)/markdownlint-cli2:
	@echo "npm dependencies not installed. Run: make -C .tools install"
	@exit 1
