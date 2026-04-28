// SysML v2 — Either monad IBD: type signature + bind contract
// (>>=) :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b
//
// Same shape as Maybe — but the Left carries the error value e, preserved intact.
// "Right" is success; "Left" is failure with a reason.

package EitherSignature {

    part def EitherBindContext {
        part ma_val : "Either e a";        // Right a (success) | Left e (failure)
        part f_val  : "a ⟶ Either e b";  // effectful function (HOF)
        part bind   : EitherBindOp;
        part mb_val : "Either e b";

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
}

#diagram {
    type  = ibd
    title = "bind :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b — also called: andThen / and_then, Bind, flatMap, >>="
    render = EitherBindContext
    show ma_val as type
    show f_val  as hof
    show bind   as function
    show mb_val as type
    tooltip ma_val = "Either e a — Right a (carry a) or Left e (carry error e). Unlike Maybe, the error value is preserved."
    tooltip f_val  = "(a ⟶ Either e b) — called only when ma_val is Right a; may itself return Left e"
    tooltip bind   = "Right a →  f a          (unwrap, apply, return result)\nLeft e  →  Left e       (short-circuit: skip f, propagate the error value unchanged)"
    tooltip mb_val = "Either e b — Right b (all steps succeeded) or Left e (first error propagated, unchanged)"
}
