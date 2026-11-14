// SysML v2 — value activity diagram
// Concept: a concrete value a0 inhabits the type a.

package FunctionValueActivity {
    private import FpDiagram::*;

    action def ValueConcept {
        #FpNodePresentation { role = "value"; tooltip = "a0 — one concrete representative, or witness, of type a."; }
        item a0 : "a0 : a";
        #FpNodePresentation { role = "type"; tooltip = "type a — the classification that a0 belongs to."; }
        item a  : "type a";

        flow from a0 to a : "inhabits";
    }
    #FpViewPresentation { name = "value"; }
    view diagram : FpActivityView {
        doc /*Value a0 of type a*/
        expose ValueConcept;
        render fpActivityDiagram;
    }
}

