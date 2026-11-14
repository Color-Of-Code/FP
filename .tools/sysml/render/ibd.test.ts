import { describe, it, expect } from "vitest";
import { parse } from "../parser.ts";
import { modelToSvg } from "./index.ts";

const source = (target: string): string => `
package P {
    part def add5 {
        port in  b      : Int;
        port out result : Int;
        part a : "Int = 5";
        part add : "(Int, Int) ⟶ Int" {
            port in  a : Int;
            port in  b : Int;
            port out _ : Int;
        }
        connection connect a to add.a;
        connection connect b to ${target};
        connection connect add._ to result;
    }
    view diagram : FpIbdView {
        doc /*t*/
        expose add5;
        render fpIbdDiagram;
    }
}`;

describe("renderIbd ports", () => {
  it("routes boundary ports and part ports as connection endpoints", async () => {
    const svg = await modelToSvg(parse(source("add.b")), "t");
    expect(svg.match(/class="port port-left"/g)).toHaveLength(1);
    expect(svg.match(/class="port port-right"/g)).toHaveLength(1);
    expect(svg.match(/class="edge"/g)).toHaveLength(3);
  });

  it("rejects connections to undeclared part ports", async () => {
    await expect(modelToSvg(parse(source("add.c")), "t")).rejects.toThrow("unknown port 'add.c'");
  });
});
