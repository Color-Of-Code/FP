// SysML v2 — Writer motivation: WITH the Writer monad
//
// Each step returns Writer w a — a value with an attached log.  bind
// concatenates logs automatically using the monoid instance for w.
// Drops are impossible: the only way to advance is to thread the log.

package WriterMotivationWith {

    action def Step1 {
        in  x      : A;
        out result : "Writer w r1";
    }

    action def Step2 {
        in  r1     : R1;
        out result : "Writer w r2";
    }

    action def Step3 {
        in  r2     : R2;
        out result : "Writer w r3";
    }

    activity def WriterChainWith {
        action step1 : Step1;
        action step2 : Step2;
        action step3 : Step3;
        object outResult   : "(r3, log123)";

        flow from step1 to step2 : ">>= bind";
        flow from step2 to step3 : ">>= bind";
        flow from step3 to outResult   : "runWriter";
    }
}

#diagram {
    type  = activity
    title = "With Writer: log accumulation is automatic"
    name  = "writerChain"
    show step1 as function
    show step2 as function
    show step3 as function
    show outResult   as type
    tooltip step1 = "step1 :: A → Writer w R1.  Step appends to the log via tell; the log itself is never visible in the user code."
    tooltip step2 = "step2 :: R1 → Writer w R2.  bind concatenates this step's log onto step1's automatically."
    tooltip step3 = "step3 :: R2 → Writer w R3.  Same again — the log just accumulates."
    tooltip outResult   = "runWriter returns the final value and the combined log in order.  Drops are impossible by construction."
}
