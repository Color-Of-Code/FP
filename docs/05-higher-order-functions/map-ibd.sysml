// SysML v2 — higher-order functions IBD: what happens inside map
// map :: (a ⟶ b) ⟶ Container a ⟶ Container b
//
// Reading guide:
//   • the «block» frame is map; its boundary ports are its whole call interface:
//     the function f, the container xs, the container ys of results
//   • the container is split into its elements and its shape (size, order, structure)
//   • f is applied to each element separately — it never sees the shape
//   • the shape bypasses f on its own wire and is refilled with the results, so the
//     output has exactly the same shape as the input
//   • this is why map cannot add, drop or reorder elements — only fold, filter and
//     friends can

package MapSignature {
    private import FpDiagram::*;

    part def map {
        #FpNodePresentation { tooltip = "f : a ⟶ b — plain function applied to every element"; }
        port in  f  : "a ⟶ b";
        #FpNodePresentation { tooltip = "xs : Container a — list, tree, Maybe, …"; }
        port in  xs : "Container a";
        #FpNodePresentation { tooltip = "ys : Container b — same shape as xs, new elements"; }
        port out ys : "Container b";

        #FpNodePresentation { role = "function"; tooltip = "Take the container apart: elements one at a time, and the shape (how many, in what order) kept aside."; }
        part split : "elements + shape" {
            port in  _     : "Container a";
            port out a_i   : "a";
            port out shape : "shape";
        }
        #FpNodePresentation { role = "function"; tooltip = "Applied once per element. f sees only the element, never the shape."; }
        part call : "f a_i" {
            port in  f : "a ⟶ b";
            port in  a : "a";
            port out _ : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Refill the shape with the results, in the original positions."; }
        part refill : "shape + results" {
            port in  shape : "shape";
            port in  b_i   : "b";
            port out _     : "Container b";
        }

        connection connect xs          to split._ : "container";
        connection connect f           to call.f : "function";
        connection connect split.a_i   to call.a : "once per element";
        connection connect split.shape to refill.shape : "shape bypasses f";
        connection connect call._      to refill.b_i : "results";
        connection connect refill._    to ys;
    }

    #FpViewPresentation { name = "map"; }
    view diagram : FpIbdView {
        doc /*map :: (a ⟶ b) ⟶ Container a ⟶ Container b — inside map: f is applied to each element; the shape bypasses f and is refilled with the results*/
        expose map;
        render fpIbdDiagram;
    }
}
