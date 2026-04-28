// SysML v2 — STM retry: implementation activity
// retry :: STM a
//
// Abort and roll back the current transaction, then block until at least
// one TVar in the read set changes; only then re-run the transaction.
// retry is the STM equivalent of "wait for the world to be ready".

package STMRetryImpl {

    action def Retry {
        out sa : "STM a";   // never produces a value on this branch
    }

    activity def STMRetryProcess {
        action retry : Retry;
        object sa    : "STM a";

        flow from retry to sa : "block; rollback; re-run on TVar change";
    }
}

#diagram {
    type  = activity
    title = "retry :: STM a   (abort + block until a watched TVar changes; then restart) — primitive"
    name  = "retry"
    show retry as function
    show sa    as type
    tooltip retry = "Retry: discard the transaction's pending writes, suspend the thread, wake when any TVar in the read set is written by another thread."
    tooltip sa    = "STM a — type-polymorphic in a because retry never returns through the value channel; the runtime handles the resumption."
}
