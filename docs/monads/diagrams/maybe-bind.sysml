// SysML v2 — Maybe bind: implementation activity
// Explicit two-path structure: Just continues, Nothing short-circuits (f never called)
//
// The two output flows from bind make the skip structurally visible:
// f connects only to the "Just" output path — it has NO path to nothing_out.

package MaybeBindImpl {

    action def MaybeBindOp {
        in  ma        : "Maybe a";
        in  f         : "a ⟶ Maybe b";  // HOF — may not be called
        out mb_just   : "Maybe b";        // Just path: result of f(unwrapped a)
        out mb_nothing : Nothing;         // Nothing path: f was NOT invoked
    }

    activity def MaybeBindProcess {
        object ma          : "Maybe a";
        object f           : "a ⟶ Maybe b";
        action bind        : MaybeBindOp;
        object mb_just     : "Maybe b";    // produced only when ma = Just a
        object mb_nothing  : Nothing;      // produced only when ma = Nothing

        flow from ma to bind;
        flow from f  to bind;
        flow from bind to mb_just    : "Just a  →  f(a)";
        flow from bind to mb_nothing : "Nothing →  Nothing  (f skipped)";
    }
}

#diagram {
    type  = activity
    title = "Maybe bind implementation: Just → f(a)  |  Nothing → Nothing  (f skipped)"
    name  = ">>="
    show ma          as type
    show f           as hof
    show bind        as function
    show mb_just     as type
    show mb_nothing  as type
    tooltip ma         = "Maybe a — the monad value. Can be Just a (has a value) or Nothing (absent)."
    tooltip f          = "(a ⟶ Maybe b) — the continuation. Only invoked when ma is Just a."
    tooltip bind       = "Pattern match on ma:\n  Just a  → unwrap a, call f(a), return its result\n  Nothing → return Nothing immediately\nf is never called in the Nothing case."
    tooltip mb_just    = "Maybe b — the result of f(unwrapped a). May itself be Just b or Nothing."
    tooltip mb_nothing = "Nothing — f was NOT called. The absent value propagates unchanged through the entire chain."
}
