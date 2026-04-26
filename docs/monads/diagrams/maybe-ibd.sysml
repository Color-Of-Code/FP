// SysML v2 — Maybe monad IBD: type signature for bind
// bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b
//
// Structural shape is identical to all other monads — the labels reveal
// what makes Maybe unique: bind propagates Nothing without calling f.
// See maybe-pure.sysml for pure :: a ⟶ Maybe a.

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
    title = "bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b"
    render = MaybeBindContext
    show ma_val as type
    show f_val  as hof
    show bind   as function
    show mb_val as type
    tooltip ma_val = "Maybe a — Just a (has a value) or Nothing (absent). If Nothing, f is never called."
    tooltip f_val  = "(a ⟶ Maybe b) — called only when ma_val is Just a; may itself return Nothing"
    tooltip bind   = "Just a  →  unwrap a, apply f, return Maybe b (no re-wrap)\nNothing →  short-circuit: skip f, propagate Nothing (: Maybe b)"
    tooltip mb_val = "Maybe b — Just b (if every step succeeded) or Nothing (first failure propagated)"
}
