// SysML v2 — State motivation: WITH the State monad
//
// Each step is State s a: a function that takes the current state and
// returns (a, newState).  bind threads the state automatically — no
// chance of accidentally passing s1 where s2 was intended.

package StateMotivationWith {

    action def Step1 {
        in  sIn  : "s";
        out pair : "(a, s)";
    }

    action def Step2 {
        in  sIn  : "s";
        out pair : "(b, s)";
    }

    action def Step3 {
        in  sIn  : "s";
        out pair : "(c, s)";
    }

    activity def StateChainWith {
        action step1 : Step1;
        action step2 : Step2;
        action step3 : Step3;
        object outResult   : "((a, b, c), sFinal)";

        flow from step1 to step2 : ">>= bind";
        flow from step2 to step3 : ">>= bind";
        flow from step3 to outResult   : "runState s0";
    }
}

#diagram {
    type  = activity
    title = "With State: state flows automatically through bind"
    name  = "stateChain"
    show step1 as function
    show step2 as function
    show step3 as function
    show outResult   as type
    tooltip step1 = "step1 :: State s a — receives the implicit state, returns (a, s')."
    tooltip step2 = "step2 :: State s b — bind passes the s' from step1 in automatically.  No way to use the wrong state."
    tooltip step3 = "step3 :: State s c — same deal: bind threads the latest state for free."
    tooltip outResult   = "runState s0 supplies the initial state and returns the final value alongside the final state.  Threading is mechanical."
}
