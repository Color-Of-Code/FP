// SysML v2 — Cont motivation: WITH callCC
//
// callCC captures the current continuation and binds it to a local
// name (commonly k or exit).  Calling exit a inside the chain jumps
// straight to the runCont call site, skipping every step in between.
// No sentinel value, no propagation by hand.

package ContMotivationWith {

    action def CallCC {
        in  body : "(b -> r) -> Cont r b";
        out cont : "Cont r b";
    }

    action def Step1 {
        in  cont : "Cont r b";
        out next : "Cont r b";
    }

    action def Step2 {
        in  cont : "Cont r b";
        out next : "Cont r b";
    }

    action def Step3 {
        in  cont : "Cont r b";
        out next : "Cont r b";
    }

    activity def ContChainWith {
        action callCC : CallCC;
        action step1  : Step1;
        action step2  : Step2;
        action step3  : Step3;
        object outVal : "r";

        flow from callCC to step1  : ">>= bind";
        flow from step1  to step2  : ">>= bind";
        flow from step2  to step3  : ">>= bind";
        flow from step3  to outVal : "runCont";

        // the captured continuation: exit a leaps directly to runCont
        flow from callCC to outVal : "exit a — direct jump";
    }
}

#diagram {
    type  = activity
    title = "With callCC: the escape function jumps directly to the runCont call site"
    name  = "contChain"
    show callCC as function
    show step1  as function
    show step2  as function
    show step3  as function
    show outVal as type
    tooltip callCC = "callCC \\exit -> ...  Captures the current continuation and binds it to exit.  Inside the body, calling exit a aborts the chain and returns a immediately."
    tooltip step1  = "step1 — runs only if no earlier exit has fired.  Composes via bind like any other Cont."
    tooltip step2  = "step2 — likewise.  No knowledge of the escape path is required."
    tooltip step3  = "step3 — likewise."
    tooltip outVal = "r — the final continuation result.  Reached either by completing the chain or by the exit shortcut from callCC."
}
