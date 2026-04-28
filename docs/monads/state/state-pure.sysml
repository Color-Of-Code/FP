// SysML v2 — State pure: implementation activity
// pure :: a ⟶ State s a   ≡   pure a = \s -> (a, s)
//
// Build a state computation that returns a unchanged AND leaves the state
// untouched. The state passes straight through. Modifying s here would
// break the left-identity law.

package StatePureImpl {

    action def IdentityState {
        in  a  : a;
        out sa : "State s a";   // = \s -> (a, s)
    }

    activity def StatePureProcess {
        object a0   : a;
        action wrap : IdentityState;
        object sa   : "State s a";

        flow from a0   to wrap;
        flow from wrap to sa : "\\s -> (a0, s)";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ State s a   (identity on state, returns a0) — also called: return"
    name  = "pure"
    show a0   as value
    show wrap as function
    show sa   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "IdentityState: build the function \\s -> (a0, s). State entering = state leaving; only the value is provided."
    tooltip sa   = "State s a = (s ⟶ (a, s)). Run this with any state s and you get (a0, s) — the state is preserved exactly."
}
