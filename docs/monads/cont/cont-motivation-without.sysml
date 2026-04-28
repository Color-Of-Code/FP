// SysML v2 — Cont motivation: WITHOUT callCC
//
// Early-exit is faked with a sentinel value (ABORT).  Every layer must
// inspect the previous step's return value, recognise the sentinel,
// and re-emit it.  One missed check and the sentinel becomes data.

package ContMotivationWithout {

    action def Step1 {
        in  x      : A;
        out result : "B | ABORT";
    }

    action def Step2 {
        in  x      : B;
        out result : "C | ABORT";
    }

    action def Step3 {
        in  x      : C;
        out result : "D | ABORT";
    }

    activity def ContChainWithout {
        object x : A;

        action step1 : Step1;
        action step2 : Step2;
        action step3 : Step3;

        decision check1 : "== ABORT?";
        decision check2 : "== ABORT?";
        decision check3 : "== ABORT?";

        merge abortRail;

        object aborted : "ABORT";
        object final   : "D";

        flow from x      to step1;
        flow from step1  to check1   : "B | ABORT";
        flow from check1 to abortRail : "ABORT";
        flow from check1 to step2    : "b : B";

        flow from step2  to check2   : "C | ABORT";
        flow from check2 to abortRail : "ABORT";
        flow from check2 to step3    : "c : C";

        flow from step3  to check3   : "D | ABORT";
        flow from check3 to abortRail : "ABORT";
        flow from check3 to final    : "d : D";

        flow from abortRail to aborted;
    }
}

#diagram {
    type  = activity
    title = "Without callCC: every caller must propagate the ABORT sentinel"
    name  = "contChain"
    show x       as value
    show step1   as function
    show step2   as function
    show step3   as function
    show aborted as type
    show final   as value
    tooltip x       = "x : A — the input to the chain."
    tooltip step1   = "step1 — may return ABORT.  Caller must check."
    tooltip step2   = "step2 — same protocol.  Skipping the check feeds ABORT into a function expecting B."
    tooltip step3   = "step3 — yet another check.  The same boilerplate, three times."
    tooltip check1  = "Sentinel guard #1 — pattern-matches on ABORT.  Error branch joins abortRail."
    tooltip check2  = "Sentinel guard #2 — same shape, different step."
    tooltip check3  = "Sentinel guard #3 — yet another by-hand check."
    tooltip aborted = "ABORT — produced by any step that wished to short-circuit and re-emitted by every subsequent caller."
    tooltip final   = "D — the happy-path output; reached only when no step aborted."
}
