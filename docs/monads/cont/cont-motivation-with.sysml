// SysML v2 — Cont motivation: WITH the Cont monad and callCC (bind + pure)
//
// The continuation-producing functions DO NOT COMPOSE naturally:
//   step1 : a → Cont r b
//   step2 : b → Cont r c        ← expects b, not Cont r b
//   step3 : c → Cont r d        ← expects c, not Cont r c
//
// Two combinators do the linear work:
//   pure  : a → Cont r a                              — return: lift into the continuation
//   (>>=) : Cont r a → (a → Cont r b) → Cont r b
//
// callCC captures the current continuation and binds it to a local
// name (commonly k or exit).  Calling exit a inside the chain jumps
// straight to the runCont call site, skipping every step in between —
// no sentinel, no manual propagation.

package ContMotivationWith {

    action def CallCC {
        in  body : "(b ⟶ Cont r b) ⟶ Cont r b";
        out _    : "Cont r b";
    }

    action def Step1 {
        in  a : a;
        out _ : "Cont r b";
    }

    action def Step2 {
        in  b : b;
        out _ : "Cont r c";
    }

    action def Step3 {
        in  c : c;
        out _ : "Cont r d";
    }

    // bind : Cont r a → (a → Cont r b) → Cont r b
    action def Bind {
        in  ma : "Cont r a";
        in  f  : "a ⟶ Cont r b";
        out _  : "Cont r b";
    }

    activity def ContChainWith {
        // entry: callCC seeds the chain with a Cont r b that has
        // captured the current continuation as `exit`
        action callCC    : CallCC;

        // each step is bind + a continuation-producing function
        object step1Fn   : "b ⟶ Cont r c";
        action bindStep1 : Bind;

        object step2Fn   : "c ⟶ Cont r d";
        action bindStep2 : Bind;

        object step3Fn   : "d ⟶ Cont r e";
        action bindStep3 : Bind;

        // output
        object outVal    : "r";

        // main flow runs through the bind nodes
        flow from callCC    to bindStep1 : "Cont r b";
        flow from bindStep1 to bindStep2 : "Cont r c";
        flow from bindStep2 to bindStep3 : "Cont r d";
        flow from bindStep3 to outVal    : "runCont";

        // each step function is supplied to its bind as the f argument
        flow from step1Fn   to bindStep1;
        flow from step2Fn   to bindStep2;
        flow from step3Fn   to bindStep3;

        // ── Swimlanes ───────────────────────────────────────────────────────
        lane plain : "Plain values & functions" =
            step1Fn, step2Fn, step3Fn, outVal;
        lane monad : "Cont monad" =
            callCC, bindStep1, bindStep2, bindStep3;

        // captured continuation: calling exit a inside any step jumps
        // directly to the runCont call site, bypassing every bind
        flow from callCC    to outVal    : "exit a — direct jump (skips all binds)";
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "With callCC + bind: linear steps via bind; exit short-circuits straight to runCont"
    name  = "contChain"
    show callCC    as function
    show bindStep1 as function
    show bindStep2 as function
    show bindStep3 as function
    show step1Fn   as hof
    show step2Fn   as hof
    show step3Fn   as hof
    show outVal    as type
    tooltip callCC    = "callCC : ((b → Cont r b) → Cont r b) → Cont r b. Captures the current continuation as exit and seeds the chain."
    tooltip bindStep1 = ">>= : sequences step1 after callCC. Skipped if exit was already called."
    tooltip bindStep2 = ">>= : sequences step2. Same pattern."
    tooltip bindStep3 = ">>= : sequences step3. Same pattern."
    tooltip step1Fn   = "step1 : b → Cont r c. HOF argument — input is b, not Cont r b."
    tooltip step2Fn   = "step2 : c → Cont r d. HOF argument."
    tooltip step3Fn   = "step3 : d → Cont r e. HOF argument."
    tooltip outVal    = "r — the final continuation result. Reached either by completing the chain or by the exit shortcut."
}

