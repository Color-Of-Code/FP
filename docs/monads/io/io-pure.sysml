// SysML v2 — IO pure: implementation activity
// pure :: a ⟶ IO a   (Haskell calls this 'return')
//
// Build an IO description that, when executed by the runtime, yields a
// without performing any side effect. pure is the trivial recipe — no
// console, no file system, no network — just "produce this value".

package IOPureImpl {
    private import FpDiagram::*;

    action def WrapAsIO {
        in  a  : a;
        out ia : "IO a";   // a no-op recipe that yields a
    }

    action def IOPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0  : a;
        #FpNodePresentation { role = "function"; tooltip = "WrapAsIO: build a no-op IO description that, when executed, returns a0. No real I/O happens at construction OR execution."; }
        action wrap : WrapAsIO;
        #FpNodePresentation { role = "type"; tooltip = "IO a — a description carrying a0. Sequencing with bind preserves a0 unchanged (left identity)."; }
        item ia  : "IO a";

        flow from a0  to wrap;
        flow from wrap to ia : "IO (return a0)";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ IO a   (effect-free description that yields a0) — also called: return, IO.pure*/
        expose IOPureProcess;
        render fpActivityDiagram;
    }
}

