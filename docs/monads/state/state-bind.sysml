// SysML v2 — State bind: implementation activity
// Key insight: s1 (the TRANSFORMED state from step 1) flows into step 2 — NOT s0.
// Each step threads the state forward. Contrast with Reader where the SAME env is reused.

package StateBindImpl {

    action def RunSA {
        in  sa  : "State s a";  // s ⟶ (a, s)
        in  s0  : s;            // current state going IN
        out a   : a;            // value result
        out s1  : s;            // state AFTER running sa (≠ s0 in general)
    }

    action def ApplyF {
        in  a   : a;
        in  f   : "a ⟶ State s b";
        out sb  : "State s b";  // s ⟶ (b, s)
    }

    action def RunSB {
        in  sb  : "State s b";  // s ⟶ (b, s)
        in  s1  : s;            // s1 from step 1 — NOT s0
        out b   : b;            // value result
        out s2  : s;            // state AFTER running f(a)
    }

    activity def StateBindProcess {
        object sa     : "State s a";
        object f      : "a ⟶ State s b";
        object s0     : s;               // initial state
        action run_sa  : RunSA;
        object s1      : s;              // state after step 1 — NOT s0
        action apply_f : ApplyF;
        action run_sb  : RunSB;
        object b       : b;
        object s2      : s;              // final state after step 2

        flow from sa    to run_sa;
        flow from s0    to run_sa;       // initial state enters
        flow from run_sa to apply_f : "a";
        flow from run_sa to s1;          // transformed state exits step 1
        flow from f     to apply_f;
        flow from apply_f to run_sb : "State s b";
        flow from s1    to run_sb;       // s1 (NOT s0) flows into step 2
        flow from run_sb to b;
        flow from run_sb to s2;          // further transformed state

        succession run_sa then apply_f;
        succession apply_f then run_sb;
    }
}

#diagram {
    type  = activity
    title = "State bind: s0 → run sa → (a, s1) → run f(a)(s1) → (b, s2) — also called: flatMap, >>="
    name  = "bind"
    show sa      as type
    show f       as hof
    show s0      as value
    show run_sa  as function
    show s1      as value
    show apply_f as function
    show run_sb  as function
    show b       as value
    show s2      as value
    tooltip sa      = "State s a — a computation: given state s returns (a, s')"
    tooltip f       = "(a ⟶ State s b) — the continuation; given result a, builds the next state computation"
    tooltip s0      = "s — the initial state entering the bind. Flows into run_sa."
    tooltip run_sa  = "Run sa(s0): execute the first computation. Produces BOTH result a AND new state s1."
    tooltip s1      = "s — the state AFTER running sa. This is s1 ≠ s0. It is s1 (not s0) that flows to run_sb. Critical difference from Reader."
    tooltip apply_f = "Apply f(a): build the next computation State s b — a function not yet run, applied to s1 by run_sb."
    tooltip run_sb  = "Run f(a)(s1): execute the second computation with the UPDATED state s1. s0 is not used here."
    tooltip b       = "b — the final value result"
    tooltip s2      = "s — the final state after both steps. s0 ≠ s1 ≠ s2 in general; each step transforms the state."
}
