// SysML v2 — Prob pure: implementation activity
// pure :: a ⟶ Dist a   ≡   pure a = [(a, 1.0)]
//
// Build the certain (Dirac) distribution: a occurs with probability 1.
// The total mass is 1, so the distribution is normalised. Using any other
// probability would break the monad laws.

package ProbPureImpl {

    action def Dirac {
        in  a   : a;
        out da  : "Dist a";   // [(a, 1.0)]
    }

    activity def ProbPureProcess {
        object a0   : a;
        action wrap : Dirac;
        object da   : "Dist a";

        flow from a0   to wrap;
        flow from wrap to da : "[(a0, 1.0)]";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ Dist a   (Dirac distribution: a0 with probability 1) — also called: return, certainly"
    name  = "pure"
    show a0   as value
    show wrap as function
    show da   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "Dirac: build the singleton distribution [(a0, 1.0)] — all probability mass concentrated on a0."
    tooltip da   = "Dist a — a normalised probability distribution. After bind, mass is redistributed by the conditional distributions f a returns."
}
