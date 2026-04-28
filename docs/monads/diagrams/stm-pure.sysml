// SysML v2 — STM pure: implementation activity
// pure :: a ⟶ STM a
//
// Build an STM transaction that performs no read or write — it just
// produces a. When committed, this is a no-op for the transactional log.
// Useful as the trivial leaf of a larger STM computation.

package STMPureImpl {

    action def WrapAsSTM {
        in  a  : a;
        out sa : "STM a";   // empty transaction yielding a
    }

    activity def STMPureProcess {
        object a0   : a;
        action wrap : WrapAsSTM;
        object sa   : "STM a";

        flow from a0   to wrap;
        flow from wrap to sa : "STM (return a0)";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ STM a   (no-read, no-write transaction yielding a0) — also called: return"
    name  = "pure"
    show a0   as value
    show wrap as function
    show sa   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "WrapAsSTM: build a transaction that touches no TVar. Empty read set, empty write set — always commits."
    tooltip sa   = "STM a — a transaction whose only effect is producing a0. Combines with other STM actions via bind / orElse without conflict."
}
