// SysML v2 — currying as an internal block diagram
// curriedAdd :: Int ⟶ (Int ⟶ Int)    curriedAdd a b = a + b
//
// Reading guide:
//   • currying fixes NO value — it only splits the call interface into stages
//   • each stage has exactly one parameter port, filled by its own call
//   • stage 1 returns a function value that captures a; stage 2 completes the sum
//   • stopping after stage 1 IS partial application: curriedAdd 5 = add5

package Function2Currying {
    private import FpDiagram::*;

    part def curriedAdd {
        #FpNodePresentation { tooltip = "a : Int — actual parameter of the first call: curriedAdd 5"; }
        port in  a      : Int;
        #FpNodePresentation { tooltip = "b : Int — actual parameter of the second call: (curriedAdd 5) 3"; }
        port in  b      : Int;
        #FpNodePresentation { tooltip = "result : Int — available only after both calls"; }
        port out result : Int;

        #FpNodePresentation { role = "function"; tooltip = "Stage 1 : Int ⟶ (Int ⟶ Int) — takes a and returns a closure that remembers it"; }
        part call1 : "a ⟶ (b ⟶ c)" {
            port in  a : Int;
            port out _ : "Int ⟶ Int";
        }
        #FpNodePresentation { role = "function"; tooltip = "Stage 2 : Int ⟶ Int — the returned closure (add5 when a = 5); takes b and computes a + b"; }
        part call2 : "b ⟶ c" {
            port in  fn  : "Int ⟶ Int";
            port in  b   : Int;
            port out _   : Int;
        }

        connection connect a         to call1.a  : "1st call";
        connection connect call1._   to call2.fn : "closure (captures a)";
        connection connect b         to call2.b  : "2nd call";
        connection connect call2._   to result;
    }

    #FpViewPresentation { name = "currying"; }
    view diagram : FpIbdView {
        doc /*Currying: (a,b) ⟶ c  ⟹  a ⟶ (b ⟶ c) — one input port per call, no value fixed yet*/
        expose curriedAdd;
        render fpIbdDiagram;
    }
}
