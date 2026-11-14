// SysML v2 — Prob pure: implementation activity
// pure :: a ⟶ Dist a   ≡   pure a = [(a, 1.0)]
//
// Build the certain (Dirac) distribution: a occurs with probability 1.
// The total mass is 1, so the distribution is normalised. Using any other
// probability would break the monad laws.

package ProbPureImpl {
    private import FpDiagram::*;

    action def Dirac {
        in  a   : a;
        out da  : "Dist a";   // [(a, 1.0)]
    }

    action def ProbPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0   : a;
        #FpNodePresentation { role = "function"; tooltip = "Dirac: build the singleton distribution [(a0, 1.0)] — all probability mass concentrated on a0."; }
        action wrap : Dirac;
        #FpNodePresentation { role = "type"; tooltip = "Dist a — a normalised probability distribution. After bind, mass is redistributed by the conditional distributions f a returns."; }
        item da   : "Dist a";

        flow from a0   to wrap;
        flow from wrap to da : "[(a0, 1.0)]";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Dist a   (Dirac distribution: a0 with probability 1) — also called: return, certainly*/
        expose ProbPureProcess;
        render fpActivityDiagram;
    }
}

