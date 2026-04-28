// SysML v2 — Maybe bind: implementation activity
// Pattern match on ma simultaneously tests the constructor and
// destructures the payload.  The Just branch carries a : a (already
// unwrapped); f is applied and returns Maybe b directly — no re-wrap.
// The Nothing branch short-circuits: the same constructor is propagated
// as Nothing (: Maybe b) without calling f.  Wrapping is pure's job.

package MaybeBindImpl {

    action def ApplyF {
        in  a0 : a;
        in  f  : "a ⟶ Maybe b";
        out mb : "Maybe b";
    }

    activity def MaybeBindProcess {
        // inputs
        object ma   : "Maybe a";
        object f    : "a ⟶ Maybe b";

        // decision: pattern match — tests constructor AND destructures in one step
        // Just branch  → a : a  (payload already unwrapped by the match)
        // Nothing branch → short-circuit directly to output
        decision matchMa;

        // Just path: f consumes the unwrapped payload directly — no separate object
        action apply_f : ApplyF;

        // merge both paths
        merge joinResult;

        // output
        object mb : "Maybe b";

        // main flow
        flow from ma to matchMa;

        // Just branch: decision destructures; the type 'a0 : a' rides on the edge
        flow from matchMa to apply_f : "Just a0  (a0 : a)";
        flow from f       to apply_f;
        flow from apply_f to joinResult;

        // Nothing branch: short-circuit — same constructor, type shifts to Maybe b
        flow from matchMa to joinResult : "Nothing (: Maybe b)";

        // single output
        flow from joinResult to mb;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Maybe bind: pattern match unwraps Just or short-circuits Nothing — also called: flatMap, andThen / and_then, SelectMany, chain, >>="
    name  = "bind"
    show ma         as type
    show f          as hof
    show apply_f    as function
    show mb         as type
    tooltip ma         = "Maybe a — the input value. Either Just a0 or Nothing."
    tooltip f          = "(a ⟶ Maybe b) — the continuation. Only called when ma is Just a0."
    tooltip matchMa    = "Pattern match: simultaneously tests the constructor and destructures the payload.\nJust a0 → a0 (: a) flows directly to f — no separate unwrap step.\nNothing → skip f entirely."
    tooltip apply_f    = "Apply f(a0). Returns Maybe b directly — bind never re-wraps. Wrapping is pure's job."
    tooltip joinResult = "Merge: both paths produce Maybe b (Just-path result or Nothing short-circuit)."
    tooltip mb         = "Maybe b — the single result of bind."
}
