// SysML v2 — State motivation: WITH the State monad (bind + pure)
//
// The producing functions DO NOT COMPOSE naturally:
//   step1 : A → State s B
//   step2 : B → State s C        ← expects B, not State s B
//   step3 : C → State s D        ← expects C, not State s C
//
// Two combinators do all the work:
//   pure  : a → State s a                            — lift a plain value, leaving s alone
//   (>>=) : State s a → (a → State s b) → State s b
//
// pure starts the chain.  Each bind threads the latest state s'
// through automatically: it runs the previous State s a with the
// current state to get (a, s'), then runs the next function with s'.
// Manually passing the wrong state is structurally impossible.

package StateMotivationWith {

    action def Step1 {
        in  a : A;
        out _ : "State s B";
    }

    action def Step2 {
        in  b : B;
        out _ : "State s C";
    }

    action def Step3 {
        in  c : C;
        out _ : "State s D";
    }

    // pure : a → State s a
    action def Pure {
        in  a : a;
        out _ : "State s a";
    }

    // bind : State s a → (a → State s b) → State s b
    action def Bind {
        in  ma : "State s a";
        in  f  : "a ⟶ State s b";
        out _  : "State s b";
    }

    activity def StateChainWith {
        // input
        object initial   : A;

        // lift the plain value into State — entry point
        action pureA     : Pure;

        // each subsequent step is bind + a producing function (HOF argument)
        object step1Fn   : "A ⟶ State s B";
        action bindStep1 : Bind;

        object step2Fn   : "B ⟶ State s C";
        action bindStep2 : Bind;

        object step3Fn   : "C ⟶ State s D";
        action bindStep3 : Bind;

        // output
        object outResult : "(D, sFinal)";

        // main flow runs through the bind nodes
        flow from initial   to pureA;
        flow from pureA     to bindStep1 : "State s A";
        flow from bindStep1 to bindStep2 : "State s B";
        flow from bindStep2 to bindStep3 : "State s C";
        flow from bindStep3 to outResult : "runState s0";

        // each producing function is supplied to its bind as the f argument
        flow from step1Fn   to bindStep1;
        flow from step2Fn   to bindStep2;
        flow from step3Fn   to bindStep3;
    }
}

#diagram {
    type  = activity
    title = "With pure + bind: state threads automatically; using a stale state is impossible"
    name  = "stateChain"
    show initial   as value
    show pureA     as function
    show bindStep1 as function
    show bindStep2 as function
    show bindStep3 as function
    show step1Fn   as hof
    show step2Fn   as hof
    show step3Fn   as hof
    show outResult as type
    tooltip initial   = "Plain input value of type A — does not include the state."
    tooltip pureA     = "pure : A → State s A. Returns (a, s) — leaves s untouched."
    tooltip bindStep1 = ">>= : runs the State action, threads s' into step1, returns step1's (b, s'')."
    tooltip bindStep2 = ">>= : threads the latest state into step2 automatically. No way to supply the wrong state."
    tooltip bindStep3 = ">>= : threads the latest state into step3 automatically."
    tooltip step1Fn   = "step1 : A → State s B. HOF argument — its input is A, not State s A."
    tooltip step2Fn   = "step2 : B → State s C. Same: supplied to bind as the continuation."
    tooltip step3Fn   = "step3 : C → State s D. Same: supplied to bind as the continuation."
    tooltip outResult = "runState s0 supplies the initial state and returns the final value alongside the final state."
}

