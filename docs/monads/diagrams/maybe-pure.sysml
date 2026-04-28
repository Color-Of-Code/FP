// SysML v2 — Maybe pure: implementation activity
// pure :: a ⟶ Maybe a
//
// Always wraps the input value in Just.  Never returns Nothing.
// This is the lifting operation — it places any plain value into the
// Maybe context so it can participate in bind chains.
// Pairs with bind to complete the Maybe monad interface.

package MaybePureImpl {

    action def WrapInJust {
        in  a      : a;
        out maybe_a : "Maybe a";
    }

    activity def MaybePureProcess {
        // input: any plain value
        object a0 : a;

        // wrap in Just
        action wrap : WrapInJust;

        // output: always Just a0, never Nothing
        object just_a0 : "Maybe a";

        flow from a0 to wrap;
        flow from wrap to just_a0 : "Just a0";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ Maybe a   (always wraps in Just, never Nothing) — also called: return, of, Some, Just"
    name  = "pure"
    show a0      as value
    show wrap    as function
    show just_a0 as type
    tooltip a0      = "a0 — any plain value to be lifted into the Maybe context."
    tooltip wrap    = "WrapInJust: place a0 inside Just. This is the only thing pure does — no logic, no failure."
    tooltip just_a0 = "Just a0 : Maybe a — always Just. pure never produces Nothing; that would violate the monad laws."
}
