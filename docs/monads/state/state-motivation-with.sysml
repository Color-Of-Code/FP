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
    private import FpDiagram::*;

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

    action def StateChainWith {
        // input
        #FpNodePresentation { role = "value"; tooltip = "Plain input value of type A — does not include the state."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item initial   : A;

        // lift the plain value into State — entry point
        #FpNodePresentation { role = "function"; tooltip = "pure : A → State s A. Returns (a, s) — leaves s untouched."; laneId = "monad"; laneLabel = "State monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action pureA     : Pure;

        // each subsequent step is bind + a producing function (HOF argument)
        #FpNodePresentation { role = "hof"; tooltip = "step1 : A → State s B. HOF argument — its input is A, not State s A."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }
        item step1Fn   : "A ⟶ State s B";
        #FpNodePresentation { role = "function"; tooltip = ">>= : runs the State action, threads s' into step1, returns step1's (b, s'')."; laneId = "monad"; laneLabel = "State monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindStep1 : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "step2 : B → State s C. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "2"; }

        item step2Fn   : "B ⟶ State s C";
        #FpNodePresentation { role = "function"; tooltip = ">>= : threads the latest state into step2 automatically. No way to supply the wrong state."; laneId = "monad"; laneLabel = "State monad"; laneOrder = "1"; laneMemberOrder = "2"; }
        action bindStep2 : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "step3 : C → State s D. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "3"; }

        item step3Fn   : "C ⟶ State s D";
        #FpNodePresentation { role = "function"; tooltip = ">>= : threads the latest state into step3 automatically."; laneId = "monad"; laneLabel = "State monad"; laneOrder = "1"; laneMemberOrder = "3"; }
        action bindStep3 : Bind;

        // output
        #FpNodePresentation { role = "type"; tooltip = "runState s0 supplies the initial state and returns the final value alongside the final state."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "4"; }
        item outResult : "(D, sFinal)";

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

        // ── Swimlanes ───────────────────────────────────────────────────────


    }
    #FpViewPresentation { name = "stateChain"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: state threads automatically; using a stale state is impossible*/
        expose StateChainWith;
        render fpActivityDiagram;
    }
}

