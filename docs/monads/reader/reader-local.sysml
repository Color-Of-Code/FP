// SysML v2 — Reader local: implementation activity
// local :: (r ⟶ r) ⟶ Reader r a ⟶ Reader r a
//
// Run an inner reader with a transformed environment.  The transformation
// f is applied to the incoming r, and the inner reader sees only f(r).
// Outside callers still pass the original environment.

package ReaderLocalImpl {
    private import FpDiagram::*;

    action def Local {
        in  f  : "r ⟶ r";
        in  ma : "Reader r a";
        out mb : "Reader r a";   // = \r -> runReader ma (f r)
    }

    action def ReaderLocalProcess {
        #FpNodePresentation { role = "value"; tooltip = "f : r ⟶ r — environment transformer (e.g. add a key, strip a layer, swap config)."; }
        item f  : "r ⟶ r";
        #FpNodePresentation { role = "value"; tooltip = "ma : Reader r a — the inner reader to be run with the transformed environment."; }
        item ma : "Reader r a";
        #FpNodePresentation { role = "function"; tooltip = "Local: build \\r -> runReader ma (f r). The outer caller still supplies the original r; only ma sees f(r)."; }
        action lcl : Local;
        #FpNodePresentation { role = "type"; tooltip = "Reader r a — same outer signature, but executions of ma are scoped to the transformed environment."; }
        item mb : "Reader r a";

        flow from f  to lcl;
        flow from ma to lcl;
        flow from lcl to mb : "\\r -> runReader ma (f r)";
    }
    #FpViewPresentation { name = "local"; }
    view diagram : FpActivityView {
        doc /*local :: (r ⟶ r) ⟶ Reader r a ⟶ Reader r a   (run inner reader with modified environment) — primitive*/
        expose ReaderLocalProcess;
        render fpActivityDiagram;
    }
}

