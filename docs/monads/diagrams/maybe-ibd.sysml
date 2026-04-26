// SysML v2 — Maybe monad IBD: type signature + bind contract
// (>>=) :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b
//
// Structural shape is identical to all other monads — the labels reveal
// what makes Maybe unique: bind propagates Nothing without calling f.

package MaybeSignature {

    part def MaybeBindContext {
        part ma_val : "Maybe a";        // Just a | Nothing
        part f_val  : "a ⟶ Maybe b";  // effectful function (HOF)
        part bind   : MaybeBindOp;
        part mb_val : "Maybe b";

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
}

#diagram {
    type  = ibd
    title = "(>>=) :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b"
    render = MaybeBindContext
    show ma_val as type
    show f_val  as hof
    show bind   as function
    show mb_val as type
    tooltip ma_val = "Maybe a — Just a (has a value) or Nothing (absent). If Nothing, f is never called."
    tooltip f_val  = "(a ⟶ Maybe b) — called only when ma_val is Just a; may itself return Nothing"
    tooltip bind   = "Just a  →  f a        (unwrap, apply, return result)\nNothing →  Nothing   (short-circuit: skip f, propagate Nothing)"
    tooltip mb_val = "Maybe b — Just b (if every step succeeded) or Nothing (first failure propagated)"
}
