// SysML v2 — Writer motivation: WITHOUT the Writer monad (bind)
//
// The log is threaded by hand alongside every value.  Each step takes
// the previous (value, log) pair, appends to it, and returns a new
// pair.  Concatenation is manual; passing log1 where log2 was expected
// silently drops every entry written since.
//
// We use "(R, Log)" pairs here — the same shape as Writer w R in the
// with-monad diagram (Writer w a IS (a, w) under the hood).  What
// differs is HOW the log is concatenated: manual append at every step
// vs. automatic via the Monoid + bind.

package WriterMotivationWithout {

    action def Step1 {
        in  x    : A;
        in  log0 : "Log";
        out _    : "(R1, Log)";
    }

    action def Step2 {
        in  r1   : R1;
        in  log1 : "Log";
        out _    : "(R2, Log)";
    }

    action def Step3 {
        in  r2   : R2;
        in  log2 : "Log";
        out _    : "(R3, Log)";
    }

    activity def WriterChainWithout {
        // input
        object x         : A;
        object emptyLog  : "Log = []";

        // three steps, each receives AND returns the running log
        action step1     : Step1;
        action step2     : Step2;
        action step3     : Step3;

        // output
        object outResult : "(R3, log123)";

        flow from x        to step1;
        flow from emptyLog to step1;
        flow from step1    to step2     : "(r1, log1)";
        flow from step2    to step3     : "(r2, log2)";
        flow from step3    to outResult : "(r3, log123)";
    }
}

#diagram {
    type  = activity
    title = "Without bind: log threaded as an explicit second parameter at every step"
    name  = "writerChain"
    show x         as value
    show emptyLog  as type
    show step1     as function
    show step2     as function
    show step3     as function
    show outResult as type
    tooltip x         = "Plain input value of type A."
    tooltip emptyLog  = "Initial empty log — caller must pass it in."
    tooltip step1     = "step1(x, log0) → (r1, log0 ++ entries1). Must accept and return the running log."
    tooltip step2     = "step2(r1, log1) → (r2, log1 ++ entries2). Passing log0 instead of log1 silently drops entries."
    tooltip step3     = "step3(r2, log2) → (r3, log2 ++ entries3). Same plumbing repeated. Adding a step means adding two more parameters everywhere it is called from."
    tooltip outResult = "(r3, log123) — caller unpacks both."
}

