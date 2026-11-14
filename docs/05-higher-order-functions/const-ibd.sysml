// SysML v2 — higher-order functions IBD: the function that const returns
// const :: a ⟶ b ⟶ a      const x y = x
//
// Reading guide:
//   • the «block» frame is the returned function; its boundary ports are its call interface:
//     the argument y in, the result out
//   • x is fixed (captured) when const is applied — it lives inside, not on the boundary
//   • y is wired to a dead end: the function receives it and discards it
//   • the captured x goes straight to the result — every call returns the same x

package ConstSignature {
    private import FpDiagram::*;

    part def constant {
        #FpNodePresentation { tooltip = "y : b — actual parameter, supplied on every call — and never used"; }
        port in  y      : "b";
        #FpNodePresentation { tooltip = "result : a — always the captured x, whatever y is"; }
        port out result : "a";

        #FpNodePresentation { role = "value"; tooltip = "x : a — fixed when const was applied; captured in the closure"; }
        part x : "a — captured";

        #FpNodePresentation { role = "function"; tooltip = "Dead end: y is received and thrown away. Nothing downstream depends on it."; }
        part discard : "ignored" {
            port in  _ : "b";
        }

        connection connect y to discard._ : "dropped";
        connection connect x to result : "captured";
    }

    #FpViewPresentation { name = "const"; }
    view diagram : FpIbdView {
        doc /*const :: a ⟶ b ⟶ a — inside const: the returned function receives y and drops it; x is captured and returned*/
        expose constant;
        render fpIbdDiagram;
    }
}
