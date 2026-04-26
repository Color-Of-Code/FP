// SysML v2 — State monad IBD: type signature + bind contract
// (>>=) :: State s a ⟶ (a ⟶ State s b) ⟶ State s b
//
// s_in and s_out make the state threading explicit: s enters bind, is transformed
// by sa, then threaded as s' into f(a), and emerges as s'' in the output type.
// Unlike Reader, s IS modified — each step sees the state that the previous step left.

package StateSignature {

    part def StateBindContext {
        part sa_val : "State s a";        // s ⟶ (a, s)  — reads state, returns a + new state
        part f_val  : "a ⟶ State s b";  // effectful function (HOF)
        part s_in   : s;                  // current state flowing into bind
        part bind   : StateBindOp;
        part sb_val : "State s b";        // s ⟶ (b, s) — next state computation
        part s_out  : s;                  // updated state flowing out of bind

        connection connect sa_val to bind;
        connection connect f_val  to bind;
        connection connect s_in   to bind;
        connection connect bind   to sb_val;
        connection connect bind   to s_out;  // transformed state continues to next step
    }
}

#diagram {
    type  = ibd
    title = "(>>=) :: State s a ⟶ (a ⟶ State s b) ⟶ State s b"
    render = StateBindContext
    show sa_val as type
    show f_val  as hof
    show s_in   as value
    show bind   as function
    show sb_val as type
    show s_out  as value
    tooltip sa_val = "State s a — a computation: given state s returns (a, s')"
    tooltip f_val  = "(a ⟶ State s b) — continuation: given result a, produces a new state computation"
    tooltip s_in   = "s — current state entering bind. The value side and the state side are both threaded."
    tooltip bind   = "bind sa f = \\s ->\n  let (a, s')  = sa(s)    -- run sa: get result a and new state s'\n      (b, s'') = f(a)(s') -- run f(a) with s': get b and final state s''\n  in  (b, s'')"
    tooltip sb_val = "State s b — the composed computation; when run it produces (b, s'')"
    tooltip s_out  = "s — the transformed state after both sa and f(a) have run. Different from s_in."
}
