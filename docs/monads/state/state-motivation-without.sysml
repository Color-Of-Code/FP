// SysML v2 — State motivation: WITHOUT the State monad (bind)
//
// State is threaded as explicit variables s0, s1, s2, s3.  Every step
// must accept the previous state and return the next.  Passing s1
// where s2 was intended compiles cleanly but is a silent bug.
//
// We use "(X, s)" pairs here — the same shape as State s X in the
// with-monad diagram (State s a IS s → (a, s) under the hood).  What
// differs is HOW the state is threaded: explicit s0/s1/s2/s3
// plumbing vs. automatic via bind.

package StateMotivationWithout {

    action def Step1 {
        in  a    : A;
        in  sIn  : "s";
        out _    : "(B, s)";
    }

    action def Step2 {
        in  b    : B;
        in  sIn  : "s";
        out _    : "(C, s)";
    }

    action def Step3 {
        in  c    : C;
        in  sIn  : "s";
        out _    : "(D, s)";
    }

    activity def StateChainWithout {
        // input
        object a0 : A;
        object s0 : "s0 (initial)";

        // intermediate states must be threaded by hand
        object s1 : "s1";
        object s2 : "s2";
        object sFinal : "s3 (final)";

        action step1 : Step1;
        action step2 : Step2;
        action step3 : Step3;

        // output
        object outResult : "(D, sFinal)";

        flow from a0    to step1;
        flow from s0    to step1;
        flow from step1 to s1     : "(b, s1)";
        flow from s1    to step2;
        flow from step2 to s2     : "(c, s2)";
        flow from s2    to step3;
        flow from step3 to sFinal : "(d, sFinal)";
        flow from step3 to outResult;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without bind: state threaded as explicit s0/s1/s2/s3 variables"
    name  = "stateChain"
    show a0        as value
    show s0        as type
    show s1        as type
    show s2        as type
    show sFinal    as type
    show step1     as function
    show step2     as function
    show step3     as function
    show outResult as type
    tooltip a0        = "Plain input value of type A."
    tooltip s0        = "Initial state, passed in by the caller."
    tooltip s1        = "Intermediate state — must be threaded into step2 by hand."
    tooltip s2        = "Intermediate state — passing s1 here instead of s2 compiles fine but is a silent bug."
    tooltip sFinal    = "Final state — caller is also responsible for receiving and forwarding it."
    tooltip step1     = "step1(a, s0) → (b, s1). Returns a new state alongside the value."
    tooltip step2     = "step2(b, s1) → (c, s2). Must be called with the freshest state — easy to get wrong."
    tooltip step3     = "step3(c, s2) → (d, s3). Same plumbing, repeated."
    tooltip outResult = "(d, sFinal) — caller unpacks both."
}

