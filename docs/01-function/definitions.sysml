// SysML v2 — total vs partial activity diagram
// Concept: classification by whether the function is defined for every input.

package FunctionDefinitionsActivity {
    private import FpDiagram::*;

  action def TotalityConcept {
    #FpNodePresentation { role = "function"; tooltip = "A function under discussion."; }
    item f       : "f :: a ⟶ b";
    #FpNodePresentation { role = "decision"; tooltip = "A total function returns a result for every input in the domain."; }
    decide total : "defined for every a?";
    #FpNodePresentation { role = "value"; tooltip = "Total — defined for all values of type a."; }
    item safe    : "total";
    #FpNodePresentation { role = "value"; tooltip = "Partial — undefined for some values of type a."; }
    item partial : "partial";

    flow from f     to total;
    flow from total to safe    : "yes";
    flow from total to partial : "no";
  }
    #FpViewPresentation { name = "totality"; }
    view diagram : FpActivityView {
        doc /*Total vs partial*/
        expose TotalityConcept;
        render fpActivityDiagram;
    }
}

