// SysML v2 — application activity diagram
// Concept: applying f to a concrete value a0 yields a concrete result b0.

package FunctionApplicationActivity {
    private import FpDiagram::*;

  action def ApplyOp {
    in  a : a;
    out b : b;
  }

  action def ApplicationConcept {
    #FpNodePresentation { role = "value"; tooltip = "a0 — a concrete input value of type a"; }
    item a0;
    #FpNodePresentation { role = "function"; tooltip = "Apply f to the input value"; }
    action f  : ApplyOp;
    #FpNodePresentation { role = "value"; tooltip = "b0 — the resulting value of type b"; }
    item b0;

    flow from a0 to f;
    flow from f  to b0;
  }
    #FpViewPresentation { name = "apply"; }
    view diagram : FpActivityView {
        doc /*Application f(a0) = b0*/
        expose ApplicationConcept;
        render fpActivityDiagram;
    }
}

