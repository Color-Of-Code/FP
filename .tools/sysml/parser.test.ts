/**
 * Snapshot tests for the SysML → AST parser.
 *
 * Captures the parsed Model for every fixture under docs/ so parser changes
 * surface as reviewable JSON diffs independently from the renderer's SVG
 * snapshots.  Update with `npx vitest run -u` after intentional grammar
 * changes.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { parse } from "./parser.ts";
import { requireAt } from "./lib/fp.ts";
import { findSysmlFiles, repoRoot } from "./test-utils/fixtures.ts";

const here = path.dirname(fileURLToPath(import.meta.url));
const snapshotDir = path.join(here, "__ast_snapshots__");

describe("SysML → AST snapshots", () => {
  const files = findSysmlFiles();
  if (files.length === 0) {
    it("finds at least one SysML source", () => {
      throw new Error("No .sysml fixtures found under docs/");
    });
    return;
  }

  files.forEach(file => {
    const rel = path.relative(repoRoot, file);
    it(rel, async () => {
      const src   = fs.readFileSync(file, "utf8");
      const model = parse(src);
      const json  = JSON.stringify(model, null, 2) + "\n";
      const base  = path.basename(file, ".sysml");
      await expect(json).toMatchFileSnapshot(path.join(snapshotDir, `${base}.json`));
    });
  });

  describe("standard SysML views", () => {
    it("adapts a view, rendering, node metadata, and lane order", () => {
      const source = `
  package Example {
    private import FpDiagram::*;

    action def Chain {
      #FpNodePresentation {
        role = "hof";
        tooltip = "Function argument";
        laneId = "plain";
        laneLabel = "Plain values";
        laneOrder = "0";
        laneMemberOrder = "0";
      }
      item f : "a ⟶ b";
      #FpNodePresentation {
        role = "function";
        laneId = "plain";
        laneLabel = "Plain values";
        laneOrder = "0";
        laneMemberOrder = "1";
      }
      action map : Map;
      flow from f to map;
    }

    #FpViewPresentation { name = "example"; direction = "TB"; }
    view diagram : FpActivityView {
      doc /*Example flow*/
      expose Chain;
      render fpActivityDiagram;
    }
  }
  `;
      const model = parse(source);
      expect(model.diagram).toEqual({
        diagType: "activity",
        title: "Example flow",
        name: "example",
        direction: "TB",
        render: "Chain",
        shows: { f: "hof", map: "function" },
        tooltips: { f: "Function argument" },
      });
      expect(requireAt(requireAt(model.packages, 0).activityDefs, 0).lanes).toEqual([
        { kind: "lane", id: "plain", label: "Plain values", members: ["f", "map"] },
      ]);
    });
  });
});
