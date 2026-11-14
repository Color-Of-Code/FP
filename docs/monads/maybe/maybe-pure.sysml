// SysML v2 — Maybe pure: implementation activity
// pure :: a ⟶ Maybe a
//
// Always wraps the input value in Just.  Never returns Nothing.
// This is the lifting operation — it places any plain value into the
// Maybe context so it can participate in bind chains.
// Pairs with bind to complete the Maybe monad interface.

package MaybePureImpl {
    private import FpDiagram::*;

    action def WrapInJust {
        in  a      : a;
        out maybe_a : "Maybe a";
    }

    action def MaybePureProcess {
        // input: any plain value
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value to be lifted into the Maybe context."; }
        item a0 : a;

        // wrap in Just
        #FpNodePresentation { role = "function"; tooltip = "WrapInJust: place a0 inside Just. This is the only thing pure does — no logic, no failure."; }
        action wrap : WrapInJust;

        // output: always Just a0, never Nothing
        #FpNodePresentation { role = "type"; tooltip = "Just a0 : Maybe a — always Just. pure never produces Nothing; that would violate the monad laws."; }
        item just_a0 : "Maybe a";

        flow from a0 to wrap;
        flow from wrap to just_a0 : "Just a0";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Maybe a   (always wraps in Just, never Nothing) — also called: return, of, Some, Just*/
        expose MaybePureProcess;
        render fpActivityDiagram;
    }
}

