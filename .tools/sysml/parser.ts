/**
 * SysML v2 (subset) parser built on Langium.
 *
 * The Langium-generated parser produces its own AST shape (see
 * `generated/ast.ts`).  This module wraps Langium's services and adapts the
 * generated AST to the renderer-facing `Model` type defined in
 * `./types/ast.ts`, so existing callers and the SVG snapshots stay stable.
 *
 * Public API:
 *   parse(src: string): Model
 */

import {
  EmptyFileSystem, inject, DefaultValueConverter,
  type CstNode, type GrammarAST, type ValueType,
} from "langium";
import { createDefaultCoreModule, createDefaultSharedCoreModule } from "langium";
import { SysmlGeneratedModule, SysmlGeneratedSharedModule } from "./generated/module.ts";
import type * as G from "./generated/ast.ts";
import type { Model } from "./types.ts";
import { adaptPackage, adaptDiagramMeta } from "./parser/adapters.ts";

// ── Langium services bootstrap ──────────────────────────────────────────────

/**
 * Custom value converter: keep STRING values exactly as the previous
 * hand-rolled parser did — strip the surrounding quotes and unescape `\"`,
 * but leave other escape sequences (`\n`, `\t`, …) as literal two-character
 * sequences.  This preserves the existing SVG snapshot output.
 */
class SysmlValueConverter extends DefaultValueConverter {
  protected override runConverter(
    rule: GrammarAST.AbstractRule,
    input: string,
    cstNode: CstNode,
  ): ValueType {
    if (rule.name === "STRING") {
      return input.slice(1, -1).replace(/\\"/g, '"');
    }
    return super.runConverter(rule, input, cstNode);
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any -- Langium service container types are deeply nested generics
function createSysmlServices(): { Sysml: { parser: { LangiumParser: any } } } {
  const shared = inject(
    createDefaultSharedCoreModule(EmptyFileSystem),
    SysmlGeneratedSharedModule,
  );
  const Sysml = inject(
    createDefaultCoreModule({ shared }),
    SysmlGeneratedModule,
    { parser: { ValueConverter: () => new SysmlValueConverter() } },
  );
  shared.ServiceRegistry.register(Sysml);
  return { Sysml: Sysml };
}

const { Sysml } = createSysmlServices();
const langiumParser = Sysml.parser.LangiumParser;

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Parse SysML v2 (subset) source text into a renderer-facing `Model`.
 * Throws on lexer or parser errors.
 */
export function parse(src: string): Model {
  const result = (langiumParser).parse(src) as {
    value: G.Model;
    lexerErrors: { line?: number; column?: number; message: string }[];
    parserErrors: { message: string; token?: { image: string } }[];
  };
  if (result.lexerErrors.length > 0) {
    const e = result.lexerErrors[0];
    throw new Error(`Lexer error at ${e.line}:${e.column}: ${e.message}`);
  }
  if (result.parserErrors.length > 0) {
    const e = result.parserErrors[0];
    throw new Error(`Parse error: ${e.message} (token '${e.token?.image ?? "<eof>"}')`);
  }
  const m = result.value;
  return {
    packages: m.packages.map(adaptPackage),
    diagram:  adaptDiagramMeta(m.diagram),
  };
}
