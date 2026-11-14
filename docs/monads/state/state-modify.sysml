// SysML v2 — State modify: implementation activity
// modify :: (s ⟶ s) ⟶ State s ()
//
// Apply f to the current state, install the result as the new state, and
// produce unit.  Defined as: modify f = get >>= put . f.

package StateModifyImpl {
    private import FpDiagram::*;

    action def Modify {
        in  f   : "s ⟶ s";
        out su  : "State s ()";   // = \s -> ((), f s)
    }

    action def StateModifyProcess {
        #FpNodePresentation { role = "value"; tooltip = "f : s ⟶ s — pure state-update function (e.g. (+1), Map.insert k v, addLog)."; }
        item f   : "s ⟶ s";
        #FpNodePresentation { role = "function"; tooltip = "Modify: build \\s -> ((), f s). Equivalent to: do { s <- get; put (f s) }."; }
        action mdf : Modify;
        #FpNodePresentation { role = "type"; tooltip = "State s () — unit value, new state is f(prev). Reads and writes happen in a single step."; }
        item su  : "State s ()";

        flow from f   to mdf;
        flow from mdf to su : "\\s -> ((), f s)";
    }
    #FpViewPresentation { name = "modify"; }
    view diagram : FpActivityView {
        doc /*modify :: (s ⟶ s) ⟶ State s ()   (transform the state in place; result is unit) — primitive*/
        expose StateModifyProcess;
        render fpActivityDiagram;
    }
}

