// SysML v2 — STM motivation: WITHOUT the STM monad (bind)
//
// Concurrency by explicit locking.  Acquire locks in the right order,
// do the work, release them in the reverse order.  A second thread
// that locks B then A can deadlock against this one — invisible in
// any local view, only manifests under contention.  Forgetting an
// unlock is a leak; ordering is contract, not type.

package STMMotivationWithout {
    private import FpDiagram::*;

    action def LockA   { out _ : "Lock"; }
    action def LockB   { out _ : "Lock"; }
    action def UpdateA { in  amt : "Int"; }
    action def UpdateB { in  amt : "Int"; }
    action def UnlockB { in  token : "Lock"; }
    action def UnlockA { in  token : "Lock"; }

    action def TransferWithout {
        #FpNodePresentation { role = "function"; tooltip = "lock(accountA) — must be acquired in a globally agreed order."; }
        action lockA   : LockA;
        #FpNodePresentation { role = "function"; tooltip = "lock(accountB) — second lock. A thread that takes B before A can deadlock against this one."; }
        action lockB   : LockB;
        #FpNodePresentation { role = "function"; tooltip = "accountA -= amount — only safe inside both locks."; }
        action updateA : UpdateA;
        #FpNodePresentation { role = "function"; tooltip = "accountB += amount — likewise."; }
        action updateB : UpdateB;
        #FpNodePresentation { role = "function"; tooltip = "unlock(accountB) — release in reverse order; forgetting is a leak."; }
        action unlockB : UnlockB;
        #FpNodePresentation { role = "function"; tooltip = "unlock(accountA) — also reverse-order; ordering is contract, not type."; }
        action unlockA : UnlockA;

        flow from lockA   to lockB;
        flow from lockB   to updateA;
        flow from updateA to updateB : "accountA -= amount";
        flow from updateB to unlockB : "accountB += amount";
        flow from unlockB to unlockA;
    }
    #FpViewPresentation { name = "transfer"; }
    view diagram : FpActivityView {
        doc /*Without STM: explicit locks require careful ordering to avoid deadlock*/
        expose TransferWithout;
        render fpActivityDiagram;
    }
}

