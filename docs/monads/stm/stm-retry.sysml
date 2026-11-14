// SysML v2 — STM retry: implementation activity
// retry :: STM a
//
// Abort and roll back the current transaction, then block until at least
// one TVar in the read set changes; only then re-run the transaction.
// retry is the STM equivalent of "wait for the world to be ready".

package STMRetryImpl {
    private import FpDiagram::*;

    action def Retry {
        out sa : "STM a";   // never produces a value on this branch
    }

    action def STMRetryProcess {
        #FpNodePresentation { role = "function"; tooltip = "Retry: discard the transaction's pending writes, suspend the thread, wake when any TVar in the read set is written by another thread."; }
        action retry : Retry;
        #FpNodePresentation { role = "type"; tooltip = "STM a — type-polymorphic in a because retry never returns through the value channel; the runtime handles the resumption."; }
        item sa    : "STM a";

        flow from retry to sa : "block; rollback; re-run on TVar change";
    }
    #FpViewPresentation { name = "retry"; }
    view diagram : FpActivityView {
        doc /*retry :: STM a   (abort + block until a watched TVar changes; then restart) — primitive*/
        expose STMRetryProcess;
        render fpActivityDiagram;
    }
}

