// SysML v2 — State monad IBD: what happens inside bind
// (>>=) :: State s a ⟶ (a ⟶ State s b) ⟶ State s b      m >>= f = join (fmap f m)
//
// State s a = s ⟶ (a, s) — a computation that reads and updates the state s.
//   • fmap applies f to the result and passes the state through unchanged
//   • join runs the outer computation, then runs the State it produced with the
//     state the outer one left behind — this is where the state is threaded
// Unlike Reader, s IS modified: each step sees what the previous step left.

package StateSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "State s a — a computation: given state s returns (a, s')"; }
        port in  ma : "State s a";
        #FpNodePresentation { tooltip = "f : a ⟶ State s b — user code; given result a, produces a new state computation"; }
        port in  f  : "a ⟶ State s b";
        #FpNodePresentation { tooltip = "State s b — the composed computation; when run it produces (b, s''). Never State s (State s b)."; }
        port out mb : "State s b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: State s a ⟶ State s (State s b)\nfmap f sa = \\s -> let (a, s') = sa s in (f a, s')\nThe state s' passes through untouched; the result is the next State computation, not yet run."; }
        part fmap : "State s a ⟶ State s (State s b)" {
            port in  f : "a ⟶ State s b";
            port in  _ : "State s a";
            port out _ : "State s (State s b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: State s (State s b) ⟶ State s b — the State-specific part\njoin mm = \\s -> let (m, s') = mm s   -- run the outer computation\n                in  m s'              -- run the inner one with the NEW state s'"; }
        part join : "State s (State s b) ⟶ State s b" {
            port in  _ : "State s (State s b)";
            port out _ : "State s b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: State s a ⟶ (a ⟶ State s b) ⟶ State s b — inside bind: fmap f, then join threads the state from outer to inner — also called: flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
