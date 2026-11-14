// SysML v2 — Either pure: implementation activity
// pure :: a ⟶ Either e a
//
// Always wraps the input value in Right. Never returns Left.
// pure is the monadic identity: it injects a successful value into the
// Either context with no error path involved. Wrapping in Left would
// violate the left-identity law (pure a >>= f ≡ f a).

package EitherPureImpl {
    private import FpDiagram::*;

    action def WrapInRight {
        in  a       : a;
        out either_a : "Either e a";
    }

    action def EitherPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value to lift into the Either context (the success branch)."; }
        item a0       : a;
        #FpNodePresentation { role = "function"; tooltip = "WrapInRight: place a0 in the Right constructor. The error type e is unused but appears in the type."; }
        action wrap     : WrapInRight;
        #FpNodePresentation { role = "type"; tooltip = "Right a0 : Either e a — always Right. Producing Left here would break the monad laws."; }
        item right_a0 : "Either e a";

        flow from a0   to wrap;
        flow from wrap to right_a0 : "Right a0";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Either e a   (always wraps in Right, never Left) — also called: return, ok, Ok*/
        expose EitherPureProcess;
        render fpActivityDiagram;
    }
}

