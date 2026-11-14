// SysML v2 — STM pure: implementation activity
// pure :: a ⟶ STM a
//
// Build an STM transaction that performs no read or write — it just
// produces a. When committed, this is a no-op for the transactional log.
// Useful as the trivial leaf of a larger STM computation.

package STMPureImpl {
    private import FpDiagram::*;

    action def WrapAsSTM {
        in  a  : a;
        out sa : "STM a";   // empty transaction yielding a
    }

    action def STMPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0   : a;
        #FpNodePresentation { role = "function"; tooltip = "WrapAsSTM: build a transaction that touches no TVar. Empty read set, empty write set — always commits."; }
        action wrap : WrapAsSTM;
        #FpNodePresentation { role = "type"; tooltip = "STM a — a transaction whose only effect is producing a0. Combines with other STM actions via bind / orElse without conflict."; }
        item sa   : "STM a";

        flow from a0   to wrap;
        flow from wrap to sa : "STM (return a0)";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ STM a   (no-read, no-write transaction yielding a0) — also called: return*/
        expose STMPureProcess;
        render fpActivityDiagram;
    }
}

