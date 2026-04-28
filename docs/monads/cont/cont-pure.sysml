// SysML v2 — Cont pure: implementation activity
// pure :: a ⟶ Cont r a   ≡   pure a = \k -> k a
//
// Build a continuation that immediately invokes its consumer k with a.
// "Just call the continuation" is the simplest possible continuation —
// no callback transformation, no early exit.

package ContPureImpl {

    action def ApplyK {
        in  a  : a;
        out ca : "Cont r a";   // = \k -> k a
    }

    activity def ContPureProcess {
        object a0   : a;
        action wrap : ApplyK;
        object ca   : "Cont r a";

        flow from a0   to wrap;
        flow from wrap to ca : "\\k -> k a0";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ Cont r a   (immediately call the continuation with a0) — also called: return"
    name  = "pure"
    show a0   as value
    show wrap as function
    show ca   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "ApplyK: build the function \\k -> k a0. The continuation k is applied directly to a0 — no extra control flow."
    tooltip ca   = "Cont r a = ((a ⟶ r) ⟶ r). When run with consumer k, evaluates k(a0). Identity element for Cont bind."
}
