// SysML v2 — IO pure: implementation activity
// pure :: a ⟶ IO a   (Haskell calls this 'return')
//
// Build an IO description that, when executed by the runtime, yields a
// without performing any side effect. pure is the trivial recipe — no
// console, no file system, no network — just "produce this value".

package IOPureImpl {

    action def WrapAsIO {
        in  a  : a;
        out ia : "IO a";   // a no-op recipe that yields a
    }

    activity def IOPureProcess {
        object a0  : a;
        action wrap : WrapAsIO;
        object ia  : "IO a";

        flow from a0  to wrap;
        flow from wrap to ia : "IO (return a0)";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ IO a   (effect-free description that yields a0) — also called: return, IO.pure"
    name  = "pure"
    show a0   as value
    show wrap as function
    show ia   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "WrapAsIO: build a no-op IO description that, when executed, returns a0. No real I/O happens at construction OR execution."
    tooltip ia   = "IO a — a description carrying a0. Sequencing with bind preserves a0 unchanged (left identity)."
}
