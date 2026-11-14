// SysML v2 — STM bind: implementation activity
// Structurally like IO bind — but actions operate on TVars, and the entire chain
// runs inside atomically. If any TVar read within the transaction was changed by
// another thread, ALL writes are discarded and the whole chain restarts from sa.

package STMBindImpl {
    private import FpDiagram::*;

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

    action def STMBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "STM a — an atomic action that reads/writes TVars. Not yet executed."; }
        item sa      : "STM a";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ STM b) — given result a, builds the next atomic action"; }
        item f       : "a ⟶ STM b";
        #FpNodePresentation { role = "function"; tooltip = "Run sa: read/write TVars; result is tentative until atomically commits"; }
        action run_sa  : RunSA;
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a): build the next atomic action STM b — a not-yet-run TVar action"; }
        action build   : BuildNext;
        #FpNodePresentation { role = "function"; tooltip = "Run f(a): read/write TVars; all writes still tentative"; }
        action run_sb  : RunSB;
        #FpNodePresentation { role = "value"; tooltip = "b — the result value (still tentative, not yet committed)"; }
        item b_raw   : b;
        #FpNodePresentation { role = "function"; tooltip = "atomically: check for TVar conflicts.\n  No conflict  → commit all writes at once; b is visible to other threads\n  Conflict     → discard ALL tentative writes; restart the entire chain from run_sa"; }
        action commit  : Atomically;
        #FpNodePresentation { role = "value"; tooltip = "b — the committed result. All TVar writes from run_sa and run_sb are now atomically visible."; }
        item b       : b;          // committed
        #FpNodePresentation { role = "type"; tooltip = "Retry path — the entire transaction restarts. No partial state is visible to other threads."; }
        item retry   : "STM b";   // restart: run_sa again if conflict

        flow from sa      to run_sa;
        flow from run_sa  to build  : "a";
        flow from f       to build;
        flow from build   to run_sb : "STM b";
        flow from run_sb  to b_raw;
        flow from b_raw   to commit;
        flow from commit  to b      : "commit — all writes visible atomically";
        flow from commit  to retry  : "conflict — discard writes, restart entire chain";

        succession run_sa then build;
        succession build  then run_sb;
        succession run_sb then commit;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*STM bind: sequence two TVar actions; atomically commits or retries the whole chain — also called: >>=*/
        expose STMBindProcess;
        render fpActivityDiagram;
    }
}

