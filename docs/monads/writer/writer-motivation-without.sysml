// SysML v2 — Writer motivation: WITHOUT the Writer monad
//
// The log is threaded by hand alongside every value.  Each step takes
// the previous log, appends to it, and returns a new pair.  Passing
// log1 where log2 was expected silently drops every entry written
// since.

package WriterMotivationWithout {

    action def Step1 {
        in  x      : A;
        out result : "(r1, log1)";
    }

    action def Step2 {
        in  r1     : R1;
        in  log1   : "Log";
        out result : "(r2, log2)";
    }

    action def Step3 {
        in  r2     : R2;
        in  log2   : "Log";
        out result : "(r3, log3)";
    }

    activity def WriterChainWithout {
        action step1 : Step1;
        action step2 : Step2;
        action step3 : Step3;
        object outResult   : "(r3, log3)";

        flow from step1 to step2 : "(r1, log1)";
        flow from step2 to step3 : "(r2, log2)";
        flow from step3 to outResult   : "(r3, log3)";
    }
}

#diagram {
    type  = activity
    title = "Without Writer: log threaded as an explicit variable"
    name  = "writerChain"
    show step1 as function
    show step2 as function
    show step3 as function
    show outResult   as type
    tooltip step1 = "step1(x) → (r1, log1).  Returns the value and the log entries it produced."
    tooltip step2 = "step2(r1, log1) → (r2, log2).  Must accept and return the running log.  Passing log1 instead of log2 silently drops entries."
    tooltip step3 = "step3(r2, log2) → (r3, log3).  Same plumbing repeated.  Adding a step means adding two more parameters everywhere it is called from."
    tooltip outResult   = "(r3, log3) — the caller is responsible for unpacking both."
}
