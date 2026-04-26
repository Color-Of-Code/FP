// SysML v2 — Either bind: implementation activity
// Same two-path structure as Maybe — but Left e carries the error VALUE, not just absence.
// The error e is preserved exactly; unlike Nothing, it tells you WHY it failed.

package EitherBindImpl {

    action def EitherBindOp {
        in  ea        : "Either e a";
        in  f         : "a ⟶ Either e b";  // HOF — may not be called
        out eb_right  : "Either e b";        // Right path: result of f(unwrapped a)
        out eb_left   : "Left e";            // Left path: f NOT invoked, e preserved
    }

    activity def EitherBindProcess {
        object ea          : "Either e a";
        object f           : "a ⟶ Either e b";
        action bind        : EitherBindOp;
        object eb_right    : "Either e b";   // produced only when ea = Right a
        object eb_left     : "Left e";       // produced only when ea = Left e

        flow from ea to bind;
        flow from f  to bind;
        flow from bind to eb_right : "Right a  →  f(a)";
        flow from bind to eb_left  : "Left e   →  Left e  (e unchanged, f skipped)";
    }
}

#diagram {
    type  = activity
    title = "Either bind: Right a → f(a)  |  Left e → Left e  (error preserved, f skipped)"
    name  = ">>="
    show ea       as type
    show f        as hof
    show bind     as function
    show eb_right as type
    show eb_left  as type
    tooltip ea       = "Either e a — Right a (success, has a value) or Left e (failure, carries error value e)"
    tooltip f        = "(a ⟶ Either e b) — the continuation. Only invoked when ea is Right a."
    tooltip bind     = "Pattern match on ea:\n  Right a → unwrap a, call f(a), return its result\n  Left e  → return Left e immediately — f is never called\nKey difference from Maybe: e carries the reason for failure, not just its presence."
    tooltip eb_right = "Either e b — the result of f(a). May be Right b (success) or Left e (new failure from f)."
    tooltip eb_left  = "Left e — the original error value e propagated UNCHANGED. The error identity is preserved."
}
