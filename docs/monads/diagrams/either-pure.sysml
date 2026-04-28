// SysML v2 — Either pure: implementation activity
// pure :: a ⟶ Either e a
//
// Always wraps the input value in Right. Never returns Left.
// pure is the monadic identity: it injects a successful value into the
// Either context with no error path involved. Wrapping in Left would
// violate the left-identity law (pure a >>= f ≡ f a).

package EitherPureImpl {

    action def WrapInRight {
        in  a       : a;
        out either_a : "Either e a";
    }

    activity def EitherPureProcess {
        object a0       : a;
        action wrap     : WrapInRight;
        object right_a0 : "Either e a";

        flow from a0   to wrap;
        flow from wrap to right_a0 : "Right a0";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ Either e a   (always wraps in Right, never Left) — also called: return, ok, Ok"
    name  = "pure"
    show a0       as value
    show wrap     as function
    show right_a0 as type
    tooltip a0       = "a0 — any plain value to lift into the Either context (the success branch)."
    tooltip wrap     = "WrapInRight: place a0 in the Right constructor. The error type e is unused but appears in the type."
    tooltip right_a0 = "Right a0 : Either e a — always Right. Producing Left here would break the monad laws."
}
