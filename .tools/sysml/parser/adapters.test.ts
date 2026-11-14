import { describe, it, expect } from "vitest";
import { strOrIdent, optionalStrOrIdent, adaptPackage, adaptDiagramMeta } from "./adapters.ts";

// ── strOrIdent ──────────────────────────────────────────────────────────────

describe("strOrIdent", () => {
  it("returns bare identifiers unchanged", () => {
    expect(strOrIdent("foo")).toBe("foo");
  });

  it("strips surrounding quotes", () => {
    expect(strOrIdent('"hello"')).toBe("hello");
  });

  it("unescapes backslash-quotes inside quoted strings", () => {
    expect(strOrIdent('"say \\"hi\\""')).toBe('say "hi"');
  });

  it("returns empty string for undefined", () => {
    expect(strOrIdent(undefined)).toBe("");
  });

  it("returns empty string for empty string", () => {
    expect(strOrIdent("")).toBe("");
  });
});

// ── optionalStrOrIdent ──────────────────────────────────────────────────────

describe("optionalStrOrIdent", () => {
  it("normalises a defined value", () => {
    expect(optionalStrOrIdent('"quoted"')).toBe("quoted");
  });

  it("returns undefined for undefined input when no fallback", () => {
    expect(optionalStrOrIdent(undefined)).toBeUndefined();
  });

  it("returns fallback for undefined input", () => {
    expect(optionalStrOrIdent(undefined, "fb")).toBe("fb");
  });

  it("ignores fallback when value is defined", () => {
    expect(optionalStrOrIdent("x", "fb")).toBe("x");
  });
});

// ── adaptPackage (integration via Langium round-trip) ───────────────────────

// Minimal synthetic AST stubs — just enough for the adapter to process.
// Uses the $type discriminator that Langium's generated isX guards check.

const stub = <T>(type: string, props: Record<string, unknown> = {}): T =>
  ({ $type: type, ...props }) as unknown as T;

describe("adaptPackage", () => {
  it("partitions empty members", () => {
    const pkg = stub("Package", { name: "P", members: [] });
    const result = adaptPackage(pkg as never);
    expect(result).toEqual({
      name: "P",
      portDefs: [],
      partDefs: [],
      actionDefs: [],
      activityDefs: [],
      views: [],
    });
  });

  it("adapts a PortDef member", () => {
    const portDef = stub("PortDef", { name: "Eth" });
    const pkg = stub("Package", { name: "P", members: [portDef] });
    const result = adaptPackage(pkg as never);
    expect(result.portDefs).toEqual([{ kind: "portDef", name: "Eth" }]);
  });

  it("adapts an ActionDef with pins", () => {
    const pin = stub("PinDeclaration", { id: "x", type: '"Int"', direction: "in" });
    const actionDef = stub("ActionDef", { name: "add", members: [pin] });
    const pkg = stub("Package", { name: "P", members: [actionDef] });
    const result = adaptPackage(pkg as never);
    expect(result.actionDefs).toEqual([{
      kind: "actionDef",
      name: "add",
      pins: [{ kind: "port", id: "x", type: "Int", direction: "in" }],
      activity: undefined,
    }]);
  });

  it("adapts a PartDef with mixed members", () => {
    const port = stub("InlinePort", { id: "p1", direction: "in" });
    const part = stub("PartUsage", { id: "cpu", ports: [] });
    const conn = stub("ConnectionUsage", { from: "a", to: "b" });
    const note = stub("NoteUsage", { id: "n1", target: "cpu", text: "note" });
    const partDef = stub("PartDef", { name: "Board", members: [port, part, conn, note] });
    const pkg = stub("Package", { name: "P", members: [partDef] });
    const result = adaptPackage(pkg as never);
    const pd = result.partDefs[0];
    expect(pd.ports).toHaveLength(1);
    expect(pd.parts).toHaveLength(1);
    expect(pd.connections).toHaveLength(1);
    expect(pd.notes).toHaveLength(1);
    expect(pd.shows).toEqual({});
    expect(pd.tooltips).toEqual({});
  });

  it("adapts an action definition with activity members and ordered lane metadata", () => {
    const action = stub("ActionUsage", { id: "a1" });
    const obj = stub("ItemUsage", {
      id: "o1",
      metadata: [stub("NodeMetadata", {
        name: "FpNodePresentation",
        fields: [
          stub("MetadataField", { key: "role", value: '"value"' }),
          stub("MetadataField", { key: "tooltip", value: '"object tip"' }),
          stub("MetadataField", { key: "laneId", value: '"plain"' }),
          stub("MetadataField", { key: "laneLabel", value: '"Plain values"' }),
          stub("MetadataField", { key: "laneOrder", value: '"0"' }),
          stub("MetadataField", { key: "laneMemberOrder", value: '"1"' }),
        ],
      })],
    });
    const decision = stub("DecisionNode", { id: "d1" });
    const merge = stub("MergeNode", { id: "m1" });
    const flow = stub("FlowUsage", { from: "a1", to: "o1", label: '"lbl"' });
    const succ = stub("SuccessionUsage", { from: "a1", to: "d1" });
    const note = stub("NoteUsage", { id: "n1", target: "a1", text: "txt" });
    const actDef = stub("ActionDef", {
      name: "myAct",
      members: [action, obj, decision, merge, flow, succ, note],
    });
    const pkg = stub("Package", { name: "P", members: [actDef] });
    const result = adaptPackage(pkg as never);
    const ad = result.activityDefs[0];
    expect(ad.kind).toBe("activityDef");
    expect(ad.name).toBe("myAct");
    expect(ad.actions).toHaveLength(1);
    expect(ad.objects).toHaveLength(1);
    expect(ad.decisions).toHaveLength(1);
    expect(ad.merges).toHaveLength(1);
    expect(ad.flows).toHaveLength(1);
    expect(ad.flows[0].label).toBe("lbl");
    expect(ad.successions).toHaveLength(1);
    expect(ad.notes).toHaveLength(1);
    expect(ad.lanes).toHaveLength(1);
    expect(ad.lanes[0]).toEqual({
      kind: "lane",
      id: "plain",
      label: "Plain values",
      members: ["o1"],
    });
    expect(ad.shows).toEqual({ o1: "value" });
    expect(ad.tooltips).toEqual({ o1: "object tip" });
  });

  it("uses id as fallback type for ActionUsage without explicit type", () => {
    const action = stub("ActionUsage", { id: "doStuff" });
    const actDef = stub("ActionDef", { name: "A", members: [action] });
    const pkg = stub("Package", { name: "P", members: [actDef] });
    const result = adaptPackage(pkg as never);
    expect(result.activityDefs[0].actions[0].type).toBe("doStuff");
  });

  it("uses explicit type for ActionUsage when provided", () => {
    const action = stub("ActionUsage", { id: "a", type: '"MyAction"' });
    const actDef = stub("ActionDef", { name: "A", members: [action] });
    const pkg = stub("Package", { name: "P", members: [actDef] });
    const result = adaptPackage(pkg as never);
    expect(result.activityDefs[0].actions[0].type).toBe("MyAction");
  });

  it("ObjectNode type is undefined when not provided", () => {
    const obj = stub("ItemUsage", { id: "o" });
    const actDef = stub("ActionDef", { name: "A", members: [obj] });
    const pkg = stub("Package", { name: "P", members: [actDef] });
    const result = adaptPackage(pkg as never);
    expect(result.activityDefs[0].objects[0].type).toBeUndefined();
  });

  it("ConnectionUsage adapts via and label", () => {
    const conn = stub("ConnectionUsage", {
      cid: "c1", from: "a", to: "b", via: "p", label: '"Link"',
    });
    const partDef = stub("PartDef", { name: "X", members: [conn] });
    const pkg = stub("Package", { name: "P", members: [partDef] });
    const result = adaptPackage(pkg as never);
    const c = result.partDefs[0].connections[0];
    expect(c.id).toBe("c1");
    expect(c.via).toBe("p");
    expect(c.label).toBe("Link");
  });
});

// ── adaptDiagramMeta ────────────────────────────────────────────────────────

describe("adaptDiagramMeta", () => {
  it("returns defaults for undefined input", () => {
    const result = adaptDiagramMeta(undefined, undefined);
    expect(result).toEqual({ diagType: "activity", shows: {}, tooltips: {} });
  });

  it("uses the standard view type, documentation and presentation metadata", () => {
    const view = stub("ViewUsage", {
      viewType: "FpIbdView",
      id: "diagram",
      title: "My Title",
      name: "traverse",
      direction: "TB",
      expose: "FmapContext",
      members: [
        stub("Expose", { target: "FmapContext" }),
        stub("RenderUsage", { rendering: "fpIbdDiagram" }),
      ],
    });
    const graph = {
      shows: { f_val: "hof" },
      tooltips: { f_val: "function value" },
    };
    const result = adaptDiagramMeta(view as never, graph as never);
    expect(result.diagType).toBe("ibd");
    expect(result.title).toBe("My Title");
    expect(result.name).toBe("traverse");
    expect(result.direction).toBe("TB");
    expect(result.render).toBe("FmapContext");
    expect(result.shows).toEqual({ f_val: "hof" });
    expect(result.tooltips).toEqual({ f_val: "function value" });
  });
});
