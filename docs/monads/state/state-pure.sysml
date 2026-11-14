// SysML v2 — State pure: implementation activity
// pure :: a ⟶ State s a   ≡   pure a = \s -> (a, s)
//
// Build a state computation that returns a unchanged AND leaves the state
// untouched. The state passes straight through. Modifying s here would
// break the left-identity law.

package StatePureImpl {
    private import FpDiagram::*;

    action def IdentityState {
        in  a  : a;
        out sa : "State s a";   // = \s -> (a, s)
    }

    action def StatePureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0   : a;
        #FpNodePresentation { role = "function"; tooltip = "IdentityState: build the function \\s -> (a0, s). State entering = state leaving; only the value is provided."; }
        action wrap : IdentityState;
        #FpNodePresentation { role = "type"; tooltip = "State s a = (s ⟶ (a, s)). Run this with any state s and you get (a0, s) — the state is preserved exactly."; }
        item sa   : "State s a";

        flow from a0   to wrap;
        flow from wrap to sa : "\\s -> (a0, s)";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ State s a   (identity on state, returns a0) — also called: return*/
        expose StatePureProcess;
        render fpActivityDiagram;
    }
}

