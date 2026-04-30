// SysML v2 — STM motivation: WITHOUT the STM monad (bind)
//
// Concurrency by explicit locking.  Acquire locks in the right order,
// do the work, release them in the reverse order.  A second thread
// that locks B then A can deadlock against this one — invisible in
// any local view, only manifests under contention.  Forgetting an
// unlock is a leak; ordering is contract, not type.

package STMMotivationWithout {

    action def LockA   { out _ : "Lock"; }
    action def LockB   { out _ : "Lock"; }
    action def UpdateA { in  amt : "Int"; }
    action def UpdateB { in  amt : "Int"; }
    action def UnlockB { in  token : "Lock"; }
    action def UnlockA { in  token : "Lock"; }

    activity def TransferWithout {
        action lockA   : LockA;
        action lockB   : LockB;
        action updateA : UpdateA;
        action updateB : UpdateB;
        action unlockB : UnlockB;
        action unlockA : UnlockA;

        flow from lockA   to lockB;
        flow from lockB   to updateA;
        flow from updateA to updateB : "accountA -= amount";
        flow from updateB to unlockB : "accountB += amount";
        flow from unlockB to unlockA;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without STM: explicit locks require careful ordering to avoid deadlock"
    name  = "transfer"
    show lockA   as function
    show lockB   as function
    show updateA as function
    show updateB as function
    show unlockB as function
    show unlockA as function
    tooltip lockA   = "lock(accountA) — must be acquired in a globally agreed order."
    tooltip lockB   = "lock(accountB) — second lock. A thread that takes B before A can deadlock against this one."
    tooltip updateA = "accountA -= amount — only safe inside both locks."
    tooltip updateB = "accountB += amount — likewise."
    tooltip unlockB = "unlock(accountB) — release in reverse order; forgetting is a leak."
    tooltip unlockA = "unlock(accountA) — also reverse-order; ordering is contract, not type."
}

