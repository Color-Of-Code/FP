// SysML v2 — Writer motivation: WITH the Writer monad (bind + pure)
//
// The producing functions DO NOT COMPOSE naturally:
//   step1 : A  → Writer w R1
//   step2 : R1 → Writer w R2     ← expects R1, not Writer w R1
//   step3 : R2 → Writer w R3     ← expects R2, not Writer w R2
//
// Two combinators do all the work:
//   pure  : a → Writer w a                          — lift a plain value with mempty log
//   (>>=) : Writer w a → (a → Writer w b) → Writer w b
//
// pure starts the chain with an empty log.  Each bind concatenates the
// log of the incoming Writer with the log of the function's result —
// using the Monoid instance for w.  The user code never touches the
// log; dropping a log entry is impossible by construction.

package WriterMotivationWith {
    private import FpDiagram::*;

    action def Step1 {
        in  x  : A;
        out _  : "Writer w R1";
    }

    action def Step2 {
        in  r1 : R1;
        out _  : "Writer w R2";
    }

    action def Step3 {
        in  r2 : R2;
        out _  : "Writer w R3";
    }

    // pure : a → Writer w a (with mempty log)
    action def Pure {
        in  a : a;
        out _ : "Writer w a";
    }

    // bind : Writer w a → (a → Writer w b) → Writer w b
    action def Bind {
        in  ma : "Writer w a";
        in  f  : "a ⟶ Writer w b";
        out _  : "Writer w b";
    }

    action def WriterChainWith {
        // input
        #FpNodePresentation { role = "value"; tooltip = "Plain input value of type A."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item x         : A;

        // lift the plain value with an empty log — entry point
        #FpNodePresentation { role = "function"; tooltip = "pure : A → Writer w A. Lifts the plain value with mempty (empty log)."; laneId = "monad"; laneLabel = "Writer monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action pureX     : Pure;

        // each subsequent step is bind + a producing function (HOF argument)
        #FpNodePresentation { role = "hof"; tooltip = "step1 : A → Writer w R1. HOF argument — its input is A, not Writer w A, so it cannot sit on the main flow."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }
        item step1Fn   : "A ⟶ Writer w R1";
        #FpNodePresentation { role = "function"; tooltip = ">>= : runs step1 on the unwrapped value; concatenates the existing log with step1's log."; laneId = "monad"; laneLabel = "Writer monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindStep1 : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "step2 : R1 → Writer w R2. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "2"; }

        item step2Fn   : "R1 ⟶ Writer w R2";
        #FpNodePresentation { role = "function"; tooltip = ">>= : runs step2; concatenates its log onto the running total. Drops are impossible."; laneId = "monad"; laneLabel = "Writer monad"; laneOrder = "1"; laneMemberOrder = "2"; }
        action bindStep2 : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "step3 : R2 → Writer w R3. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "3"; }

        item step3Fn   : "R2 ⟶ Writer w R3";
        #FpNodePresentation { role = "function"; tooltip = ">>= : runs step3; concatenates its log onto the running total."; laneId = "monad"; laneLabel = "Writer monad"; laneOrder = "1"; laneMemberOrder = "3"; }
        action bindStep3 : Bind;

        // output
        #FpNodePresentation { role = "type"; tooltip = "runWriter returns the final value and the combined log."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "4"; }
        item outResult : "(R3, log123)";

        // main flow runs through the bind nodes
        flow from x         to pureX;
        flow from pureX     to bindStep1 : "Writer w A";
        flow from bindStep1 to bindStep2 : "Writer w R1";
        flow from bindStep2 to bindStep3 : "Writer w R2";
        flow from bindStep3 to outResult : "runWriter";

        // each producing function is supplied to its bind as the f argument
        flow from step1Fn   to bindStep1;
        flow from step2Fn   to bindStep2;
        flow from step3Fn   to bindStep3;

        // ── Swimlanes ───────────────────────────────────────────────────────


    }
    #FpViewPresentation { name = "writerChain"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: log accumulation is automatic via the Monoid for w*/
        expose WriterChainWith;
        render fpActivityDiagram;
    }
}

