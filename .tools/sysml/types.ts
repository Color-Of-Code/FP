/**
 * Barrel re-export — imports from here get everything from the focused
 * sub-modules.
 *
 * Sub-modules:
 *   types/ast.ts       — SysML v2 parser AST types
 *   types/graph.ts     — GNode, GEdge, nodeDims
 *   types/theme.ts     — `theme` object (dims + colours) and flat aliases
 *   types/constants.ts — flat dimension re-exports (legacy)
 *   types/palette.ts   — `COL` palette re-export (legacy)
 */

export * from "./types/ast.ts";
export * from "./types/graph.ts";
export * from "./types/theme.ts";
