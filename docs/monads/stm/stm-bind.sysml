// SysML v2 — STM bind: implementation activity
// Structurally like IO bind — but actions operate on TVars, and the entire chain
// runs inside atomically. If any TVar read within the transaction was changed by
// another thread, ALL writes are discarded and the whole chain restarts from sa.

package STMBindImpl {

    action def RunSA {
        in  sa  : "STM a";  // atomic action — reads/writes TVars
        out a   : a;
    }

    action def BuildNext {
        in  a   : a;
        in  f   : "a ⟶ STM b";
        out sb  : "STM b";  // the next atomic action, built from a
    }

    action def RunSB {
        in  sb  : "STM b";
        out b   : b;
    }

    action def Atomically {
        in  b_in   : b;
        out b_out  : b;   // committed result — or whole chain retries
        out retry  : "STM b";  // conflict detected: restart entire chain
    }

    activity def STMBindProcess {
        object sa      : "STM a";
        object f       : "a ⟶ STM b";
        action run_sa  : RunSA;
        object a       : a;
        action build   : BuildNext;
        object sb      : "STM b";
        action run_sb  : RunSB;
        object b_raw   : b;
        action commit  : Atomically;
        object b       : b;          // committed
        object retry   : "STM b";   // restart: run_sa again if conflict

        flow from sa      to run_sa;
        flow from run_sa  to a;
        flow from a       to build;
        flow from f       to build;
        flow from build   to sb;
        flow from sb      to run_sb;
        flow from run_sb  to b_raw;
        flow from b_raw   to commit;
        flow from commit  to b      : "commit — all writes visible atomically";
        flow from commit  to retry  : "conflict — discard writes, restart entire chain";

        succession run_sa then build;
        succession build  then run_sb;
        succession run_sb then commit;
    }
}

#diagram {
    type  = activity
    title = "STM bind: sequence two TVar actions; atomically commits or retries the whole chain — also called: >>="
    name  = "bind"
    show sa     as type
    show f      as hof
    show run_sa as function
    show a      as value
    show build  as function
    show sb     as type
    show run_sb as function
    show b_raw  as value
    show commit as function
    show b      as value
    show retry  as type
    tooltip sa     = "STM a — an atomic action that reads/writes TVars. Not yet executed."
    tooltip f      = "(a ⟶ STM b) — given result a, builds the next atomic action"
    tooltip run_sa = "Run sa: read/write TVars; result is tentative until atomically commits"
    tooltip a      = "a — the value produced by sa (tentative)"
    tooltip build  = "Apply f(a): build the next atomic action STM b"
    tooltip sb     = "STM b — the next atomic action"
    tooltip run_sb = "Run f(a): read/write TVars; all writes still tentative"
    tooltip b_raw  = "b — the result value (still tentative, not yet committed)"
    tooltip commit = "atomically: check for TVar conflicts.\n  No conflict  → commit all writes at once; b is visible to other threads\n  Conflict     → discard ALL tentative writes; restart the entire chain from run_sa"
    tooltip b      = "b — the committed result. All TVar writes from run_sa and run_sb are now atomically visible."
    tooltip retry  = "Retry path — the entire transaction restarts. No partial state is visible to other threads."
}
