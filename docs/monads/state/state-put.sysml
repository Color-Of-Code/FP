// SysML v2 — State put: implementation activity
// put :: s ⟶ State s ()
//
// Replace the current state with s' and produce unit.  The new state is
// independent of whatever state was incoming.

package StatePutImpl {
    private import FpDiagram::*;

    action def Put {
        in  sNew : s;
        out su   : "State s ()";   // = \_ -> ((), sNew)
    }

    action def StatePutProcess {
        #FpNodePresentation { role = "value"; tooltip = "sNew — the new state value to install (replaces whatever state was current)."; }
        item sNew : s;
        #FpNodePresentation { role = "function"; tooltip = "Put: build \\_ -> ((), sNew) — discards incoming state, emits sNew as outgoing state."; }
        action put  : Put;
        #FpNodePresentation { role = "type"; tooltip = "State s () — value is unit, state is now sNew. Subsequent steps see sNew."; }
        item su   : "State s ()";

        flow from sNew to put;
        flow from put  to su : "\\_ -> ((), sNew)";
    }
    #FpViewPresentation { name = "put"; }
    view diagram : FpActivityView {
        doc /*put :: s ⟶ State s ()   (overwrite the state with s'; result is unit) — primitive*/
        expose StatePutProcess;
        render fpActivityDiagram;
    }
}

