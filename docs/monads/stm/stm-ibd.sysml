// SysML v2 — STM monad IBD: inside bind
// (>>=) :: STM a ⟶ (a ⟶ STM b) ⟶ STM b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. The call interface is the same for every
// monad — ma and f in, mb out. An STM value is a transaction recipe, so inside the block we
// see its script as atomically executes it. Here fmap and join are fused into what STM
// actually does — IO-style sequencing inside ONE transaction:
//   • both steps read and write TVars through the same transaction log
//   • nothing is visible to other threads until the whole log commits
//   • a conflict (or retry) in either step discards the log and re-runs everything

package STMSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "STM a — an atomic action on TVars (transactional variables). Not yet committed."; }
        port in  ma : "STM a";
        #FpNodePresentation { tooltip = "f : a ⟶ STM b — user code; given result a of the first action, constructs the next atomic step"; }
        port in  f  : "a ⟶ STM b";
        #FpNodePresentation { tooltip = "STM b — the composed atomic action. Runs inside atomically :: STM a -> IO a."; }
        port out mb : "STM b";

        #FpNodePresentation { role = "value"; tooltip = "The transaction log: TVar reads and tentative writes are recorded here, not applied. One log is shared by both steps."; }
        part log : "transaction log";

        #FpNodePresentation { role = "function"; tooltip = "Run the first action against the log, producing a."; }
        part run_ma : "run ma" {
            port in  m   : "STM a";
            port in  log : "log";
            port out _   : "a";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the result: yields the next atomic action, not yet run."; }
        part call : "f a" {
            port in  f : "a ⟶ STM b";
            port in  a : "a";
            port out _ : "STM b";
        }
        #FpNodePresentation { role = "function"; tooltip = "The STM-specific join: run the action f built against the SAME log, so both steps form one atomic unit."; }
        part run_next : "run (f a)" {
            port in  m   : "STM b";
            port in  log : "log";
            port out _   : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "atomically: validate the log against the current TVar values. If nothing conflicts, publish all writes at once; otherwise (or on retry) discard the log and start over."; }
        part commit : "commit or retry" {
            port in  _ : "b";
            port out _ : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Package the whole script as one atomic action, to be run by atomically."; }
        part wrap : "atomic action" {
            port in  _ : "b";
            port out _ : "STM b";
        }

        connection connect ma         to run_ma.m : "wrapped";
        connection connect log        to run_ma.log : "shared log";
        connection connect run_ma._   to call.a : "result";
        connection connect f          to call.f : "user code";
        connection connect call._     to run_next.m : "next action";
        connection connect log        to run_next.log : "same log";
        connection connect run_next._ to commit._ : "tentative result";
        connection connect commit._   to wrap._ : "committed";
        connection connect wrap._     to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: STM a ⟶ (a ⟶ STM b) ⟶ STM b — inside bind: both actions run against one shared transaction log that commits or retries as a whole — also called: >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
