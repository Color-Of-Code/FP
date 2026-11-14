// SysML v2 — partial application as an internal block diagram
// add5 = add 5   — fixes a = 5 inside the closure; only b stays open
//
// Reading guide:
//   • the «block» frame is the new function value add5 : Int ⟶ Int
//   • boundary ports are its call interface: the actual argument b in, the result out
//   • the part a is the fixed (captured) value — it lives inside, not on the boundary
//   • add keeps both of its original parameter ports; partial application only
//     changes WHO feeds them

package Function2PartialApplication {
    private import FpDiagram::*;

    part def add5 {
        #FpNodePresentation { tooltip = "b : Int — actual parameter, supplied on every call: add5 3"; }
        port in  b      : Int;
        #FpNodePresentation { tooltip = "result : Int — what each call returns: add5 3 = 8"; }
        port out result : Int;

        #FpNodePresentation { role = "value"; tooltip = "a = 5 — fixed when add5 was created; captured in the closure, never passed again"; }
        part a : "Int = 5";
        #FpNodePresentation { role = "function"; tooltip = "add : (Int, Int) ⟶ Int — the original two-parameter function, unchanged"; }
        part add : "(Int, Int) ⟶ Int" {
            port in  a : Int;
            port in  b : Int;
            port out _ : Int;
        }

        connection connect a     to add.a : "fixed";
        connection connect b     to add.b : "actual";
        connection connect add._ to result;
    }

    #FpViewPresentation { name = "partial application"; }
    view diagram : FpIbdView {
        doc /*Partial application: add5 = add 5 fixes a = 5 inside; only b remains an input port*/
        expose add5;
        render fpIbdDiagram;
    }
}
