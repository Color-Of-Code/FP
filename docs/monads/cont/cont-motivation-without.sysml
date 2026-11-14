// SysML v2 — Cont motivation: WITHOUT callCC / Cont monad
//
// Early-exit is faked with a sentinel value (ABORT).  Every layer
// must inspect the previous step's return value, recognise the
// sentinel, and re-emit it.  One missed check and the sentinel
// becomes data.

package ContMotivationWithout {
    private import FpDiagram::*;

    action def Step1 {
        in  a : A;
        out _ : "B | ABORT";
    }

    action def Step2 {
        in  b : B;
        out _ : "C | ABORT";
    }

    action def Step3 {
        in  c : C;
        out _ : "D | ABORT";
    }

    action def ContChainWithout {
        // input
        #FpNodePresentation { role = "value"; tooltip = "x : A — the input to the chain."; }
        item x : A;

        // three fallible steps
        #FpNodePresentation { role = "function"; tooltip = "step1 — may return ABORT. Caller must check."; }
        action step1 : Step1;
        #FpNodePresentation { role = "function"; tooltip = "step2 — same protocol. Skipping the check feeds ABORT into a function expecting B."; }
        action step2 : Step2;
        #FpNodePresentation { role = "function"; tooltip = "step3 — yet another check. The same boilerplate, three times."; }
        action step3 : Step3;

        // one ABORT guard per step
        #FpNodePresentation { tooltip = "Sentinel guard #1 — pattern-matches on ABORT. The non-ABORT branch carries b to step2; ABORT joins abortRail."; }
        decide check1 : "ABORT?";
        #FpNodePresentation { tooltip = "Sentinel guard #2 — same shape, different step."; }
        decide check2 : "ABORT?";
        #FpNodePresentation { tooltip = "Sentinel guard #3 — yet another by-hand check."; }
        decide check3 : "ABORT?";

        // all ABORT branches converge here
        merge abortRail;

        // outputs
        #FpNodePresentation { role = "type"; tooltip = "ABORT — produced by any step that wished to short-circuit and re-emitted by every subsequent caller."; }
        item aborted : "ABORT";
        #FpNodePresentation { role = "value"; tooltip = "D — the happy-path output; reached only when no step aborted."; }
        item final   : "D";

        // happy path
        flow from x      to step1;
        flow from step1  to check1    : "B | ABORT";
        flow from check1 to abortRail : "ABORT";
        flow from check1 to step2     : "b : B";

        flow from step2  to check2    : "C | ABORT";
        flow from check2 to abortRail : "ABORT";
        flow from check2 to step3     : "c : C";

        flow from step3  to check3    : "D | ABORT";
        flow from check3 to abortRail : "ABORT";
        flow from check3 to final     : "d : D";

        flow from abortRail to aborted;
    }
    #FpViewPresentation { name = "contChain"; }
    view diagram : FpActivityView {
        doc /*Without callCC: every caller must propagate the ABORT sentinel*/
        expose ContChainWithout;
        render fpActivityDiagram;
    }
}

