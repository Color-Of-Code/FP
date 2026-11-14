// SysML v2 — Either monad IBD: type signature + bind contract
// (>>=) :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b
//
// Same shape as Maybe — but the Left carries the error value e, preserved intact.
// "Right" is success; "Left" is failure with a reason.

package EitherSignature {
    private import FpDiagram::*;

    part def EitherBindContext {
        #FpNodePresentation { role = "type"; tooltip = "Either e a — Right a (carry a) or Left e (carry error e). Unlike Maybe, the error value is preserved."; }
        part ma_val : "Either e a";        // Right a (success) | Left e (failure)
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Either e b) — called only when ma_val is Right a; may itself return Left e"; }
        part f_val  : "a ⟶ Either e b";  // effectful function (HOF)
        #FpNodePresentation { role = "function"; tooltip = "Right a →  f a          (unwrap, apply, return result)\nLeft e  →  Left e       (short-circuit: skip f, propagate the error value unchanged)"; }
        part bind   : EitherBindOp;
        #FpNodePresentation { role = "type"; tooltip = "Either e b — Right b (all steps succeeded) or Left e (first error propagated, unchanged)"; }
        part mb_val : "Either e b";

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b — also called: andThen / and_then, Bind, flatMap, >>=*/
        expose EitherBindContext;
        render fpIbdDiagram;
    }
}

