// SysML v2 — type activity diagram
// Concept: a type describes the space of values that may inhabit it.

package FunctionTypeActivity {
    private import FpDiagram::*;

  action def TypeConcept {
    #FpNodePresentation { role = "value"; tooltip = "A type can be seen as the set of values that may inhabit it."; }
    item values : "{a0, a1, ...}";
    #FpNodePresentation { role = "type"; tooltip = "type a — used to describe the domain or codomain of a function."; }
    item a      : "type a";

    flow from values to a : "all possible values";
  }
    #FpViewPresentation { name = "type"; }
    view diagram : FpActivityView {
        doc /*Type a*/
        expose TypeConcept;
        render fpActivityDiagram;
    }
}

