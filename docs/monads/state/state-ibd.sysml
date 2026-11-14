// SysML v2 — State monad IBD: type signature + bind contract
// (>>=) :: State s a ⟶ (a ⟶ State s b) ⟶ State s b
//
// s_in and s_out make the state threading explicit: s enters bind, is transformed
// by sa, then threaded as s' into f(a), and emerges as s'' in the output type.
// Unlike Reader, s IS modified — each step sees the state that the previous step left.

package StateSignature {
    private import FpDiagram::*;

    part def StateBindContext {
        #FpNodePresentation { role = "type"; tooltip = "State s a — a computation: given state s returns (a, s')"; }
        part sa_val : "State s a";        // s ⟶ (a, s)  — reads state, returns a + new state
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ State s b) — continuation: given result a, produces a new state computation"; }
        part f_val  : "a ⟶ State s b";  // effectful function (HOF)
        #FpNodePresentation { role = "value"; tooltip = "s — current state entering bind. The value side and the state side are both threaded."; }
        part s_in   : s;                  // current state flowing into bind
        #FpNodePresentation { role = "function"; tooltip = "bind sa f = \\s ->\n  let (a, s')  = sa(s)    -- run sa: get result a and new state s'\n      (b, s'') = f(a)(s') -- run f(a) with s': get b and final state s''\n  in  (b, s'')"; }
        part bind   : StateBindOp;
        #FpNodePresentation { role = "type"; tooltip = "State s b — the composed computation; when run it produces (b, s'')"; }
        part sb_val : "State s b";        // s ⟶ (b, s) — next state computation
        #FpNodePresentation { role = "value"; tooltip = "s — the transformed state after both sa and f(a) have run. Different from s_in."; }
        part s_out  : s;                  // updated state flowing out of bind

        connection connect sa_val to bind;
        connection connect f_val  to bind;
        connection connect s_in   to bind;
        connection connect bind   to sb_val;
        connection connect bind   to s_out;  // transformed state continues to next step
    }
    view diagram : FpIbdView {
        doc /*bind :: State s a ⟶ (a ⟶ State s b) ⟶ State s b — also called: flatMap, >>=*/
        expose StateBindContext;
        render fpIbdDiagram;
    }
}

