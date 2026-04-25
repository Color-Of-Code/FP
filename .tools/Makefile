# Tooling for the FP repository
# Run from anywhere: make -C .tools <target>
# Or: cd .tools && make <target>

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BASICS     := $(REPO_ROOT)/basics
NODE_BIN   := $(REPO_ROOT)/.tools/node_modules/.bin

D2_FILES   := $(wildcard $(BASICS)/*.d2)
SVG_FILES  := $(D2_FILES:.d2=.svg)

# Exclude styles.d2 — it is an import-only file, not a standalone diagram
DIAGRAM_D2  := $(filter-out $(BASICS)/styles.d2, $(D2_FILES))
DIAGRAM_SVG := $(DIAGRAM_D2:.d2=.svg)

.PHONY: all svgs fmt-d2 fmt-md lint-md lint-langs check-md fmt install help

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
	@echo "  all         svgs + fmt + lint-md"
	@echo ""

## Install npm dependencies
install:
	cd $(REPO_ROOT)/.tools && npm install

## Regenerate all SVG diagrams
svgs: $(DIAGRAM_SVG)

$(BASICS)/%.svg: $(BASICS)/%.d2 $(BASICS)/styles.d2
	d2 --layout=elk "$<" "$@"
	@echo "  generated $@"

## Format D2 source files (uses d2 fmt built-in)
fmt-d2:
	d2 fmt $(D2_FILES)
	@echo "  formatted D2 files"

## Format Markdown files
fmt-md: $(NODE_BIN)/prettier
	$(NODE_BIN)/prettier --write "$(REPO_ROOT)/**/*.md"

## Lint Markdown files
lint-md: $(NODE_BIN)/markdownlint-cli2
	$(NODE_BIN)/markdownlint-cli2 "$(REPO_ROOT)/**/*.md" "!$(REPO_ROOT)/.tools/node_modules/**"

## Check language-example sections are complete and in the correct order
lint-langs:
	node $(REPO_ROOT)/.tools/check-lang-order.js

## Check Markdown formatting without writing (for CI)
check-md: $(NODE_BIN)/prettier
	$(NODE_BIN)/prettier --check "$(REPO_ROOT)/**/*.md"

## Format everything
fmt: fmt-d2 fmt-md

## Run everything
all: svgs fmt lint-md lint-langs

# Guard: remind to run install if node_modules is missing
$(NODE_BIN)/prettier $(NODE_BIN)/markdownlint-cli2:
	@echo "npm dependencies not installed. Run: make -C .tools install"
	@exit 1
