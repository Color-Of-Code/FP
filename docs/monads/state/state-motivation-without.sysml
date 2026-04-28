// SysML v2 — State motivation: WITHOUT the State monad
//
// State is threaded as explicit variables s0, s1, s2, s3.  Every step
// must accept the previous state and return the next.  Passing s1
// where s2 was intended compiles cleanly but is a silent bug.

package StateMotivationWithout {

    action def Step1 {
        in  sIn  : "s0";
        out pair : "(a, s1)";
    }

    action def Step2 {
        in  sIn  : "s1";
        out pair : "(b, s2)";
    }

    action def Step3 {
        in  sIn  : "s2";
        out pair : "(c, s3)";
    }

    activity def StateChainWithout {
        object s0 : "s0 (input)";
        object s1 : "s1";
        object s2 : "s2";
        object s3 : "s3 (final)";

        action step1 : Step1;
        action step2 : Step2;
        action step3 : Step3;

        flow from s0    to step1;
        flow from step1 to s1;
        flow from s1    to step2;
        flow from step2 to s2;
        flow from s2    to step3;
        flow from step3 to s3;
    }
}

#diagram {
    type  = activity
    title = "Without State: state threaded as explicit variables"
    name  = "stateChain"
    show s0    as type
    show s1    as type
    show s2    as type
    show s3    as type
    show step1 as function
    show step2 as function
    show step3 as function
    tooltip s0    = "Initial state, passed in by the caller."
    tooltip s1    = "Intermediate state — must be threaded into step2 by hand."
    tooltip s2    = "Intermediate state — passing s1 here instead of s2 compiles fine but is a silent bug."
    tooltip s3    = "Final state — caller is also responsible for receiving and forwarding it."
    tooltip step1 = "step1(s0) → (a, s1).  Returns a new state alongside the value."
    tooltip step2 = "step2(s1) → (b, s2).  Must be called with the freshest state — easy to get wrong."
    tooltip step3 = "step3(s2) → (c, s3).  Same plumbing, repeated."
}
