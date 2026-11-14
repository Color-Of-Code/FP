// SysML v2 — function activity diagram
// Concept: f :: a ⟶ b maps a value from the domain type to the codomain type.

package FunctionActivity {
    private import FpDiagram::*;

  action def FunctionOp {
    in  a : a;
    out b : b;
  }

  action def FunctionConcept {
    #FpNodePresentation { role = "type"; tooltip = "type a — the domain of f"; }
    item a : "type a";
    #FpNodePresentation { role = "function"; tooltip = "f consumes a value of type a and produces a value of type b"; }
    action f : FunctionOp;
    #FpNodePresentation { role = "type"; tooltip = "type b — the codomain of f"; }
    item b : "type b";

    flow from a to f : "domain";
    flow from f to b : "codomain";
  }
    #FpViewPresentation { name = "function"; }
    view diagram : FpActivityView {
        doc /*Function f :: a ⟶ b*/
        expose FunctionConcept;
        render fpActivityDiagram;
    }
}

