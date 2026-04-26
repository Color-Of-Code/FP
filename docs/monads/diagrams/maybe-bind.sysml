// SysML v2 — Maybe bind: implementation activity
// Shows the decision (pattern match on ma) that determines the outcome.
//
// Decision node branches on Just/Nothing.  The Just path unwraps a,
// applies f, and produces Maybe b.  The Nothing path skips f entirely.
// A merge node joins both paths into a single Maybe b result.

package MaybeBindImpl {

    action def UnwrapJust {
        in  ma : "Maybe a";
        out a  : a;
    }

    action def ApplyF {
        in  a  : a;
        in  f  : "a ⟶ Maybe b";
        out mb : "Maybe b";
    }

    activity def MaybeBindProcess {
        // inputs
        object ma   : "Maybe a";
        object f    : "a ⟶ Maybe b";

        // decision: pattern match on ma
        decision matchMa;

        // Just path: unwrap then apply f
        action unwrap  : UnwrapJust;
        action apply_f : ApplyF;

        // Nothing path: no action, value passes through
        object nothing : Nothing;

        // merge both paths
        merge joinResult;

        // output
        object mb : "Maybe b";

        // main flow
        flow from ma to matchMa;

        // Just branch
        flow from matchMa to unwrap  : "Just a";
        flow from unwrap to apply_f;
        flow from f to apply_f;
        flow from apply_f to joinResult;

        // Nothing branch
        flow from matchMa to nothing : "Nothing";
        flow from nothing to joinResult;

        // single output
        flow from joinResult to mb;
    }
}

#diagram {
    type  = activity
    title = "Maybe >>= : pattern match on ma determines the path"
    name  = ">>="
    show ma         as type
    show f          as hof
    show unwrap     as function
    show apply_f    as function
    show nothing    as type
    show mb         as type
    tooltip ma          = "Maybe a — the input value. Either Just a or Nothing."
    tooltip f           = "(a ⟶ Maybe b) — the continuation. Only called when ma is Just a."
    tooltip matchMa     = "Pattern match: is ma = Just a  or  Nothing?"
    tooltip unwrap      = "Unwrap: extract the a from Just a."
    tooltip apply_f     = "Apply f(a). Returns Maybe b — may itself be Just b or Nothing."
    tooltip nothing     = "Nothing — propagated unchanged. f is never called."
    tooltip joinResult  = "Merge: both paths produce Maybe b (Just-path result or Nothing)."
    tooltip mb          = "Maybe b — the single result of bind."
}
