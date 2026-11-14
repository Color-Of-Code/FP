// SysML v2 — Maybe monad IBD: type signature for bind
// bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b
//
// Structural shape is identical to all other monads — the labels reveal
// what makes Maybe unique: bind propagates Nothing without calling f.
// See maybe-pure.sysml for pure :: a ⟶ Maybe a.

package MaybeSignature {
    private import FpDiagram::*;

    part def MaybeBindContext {
        #FpNodePresentation { role = "type"; tooltip = "Maybe a — Just a (has a value) or Nothing (absent). If Nothing, f is never called."; }
        part ma_val : "Maybe a";        // Just a | Nothing
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Maybe b) — called only when ma_val is Just a; may itself return Nothing"; }
        part f_val  : "a ⟶ Maybe b";  // effectful function (HOF)
        #FpNodePresentation { role = "function"; tooltip = "Just a  →  unwrap a, apply f, return Maybe b (no re-wrap)\nNothing →  short-circuit: skip f, propagate Nothing (: Maybe b)"; }
        part bind   : MaybeBindOp;
        #FpNodePresentation { role = "type"; tooltip = "Maybe b — Just b (if every step succeeded) or Nothing (first failure propagated)"; }
        part mb_val : "Maybe b";

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b — also called: flatMap, andThen / and_then, SelectMany, chain, >>=*/
        expose MaybeBindContext;
        render fpIbdDiagram;
    }
}

