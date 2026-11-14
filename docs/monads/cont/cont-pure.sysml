// SysML v2 — Cont pure: implementation activity
// pure :: a ⟶ Cont r a   ≡   pure a = \k -> k a
//
// Build a continuation that immediately invokes its consumer k with a.
// "Just call the continuation" is the simplest possible continuation —
// no callback transformation, no early exit.

package ContPureImpl {
    private import FpDiagram::*;

    action def ApplyK {
        in  a  : a;
        out ca : "Cont r a";   // = \k -> k a
    }

    action def ContPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0   : a;
        #FpNodePresentation { role = "function"; tooltip = "ApplyK: build the function \\k -> k a0. The continuation k is applied directly to a0 — no extra control flow."; }
        action wrap : ApplyK;
        #FpNodePresentation { role = "type"; tooltip = "Cont r a = ((a ⟶ r) ⟶ r). When run with consumer k, evaluates k(a0). Identity element for Cont bind."; }
        item ca   : "Cont r a";

        flow from a0   to wrap;
        flow from wrap to ca : "\\k -> k a0";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Cont r a   (immediately call the continuation with a0) — also called: return*/
        expose ContPureProcess;
        render fpActivityDiagram;
    }
}

