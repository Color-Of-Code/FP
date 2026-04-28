// SysML v2 — Maybe monad: bind example

package MaybeMonadExample {

    action def MaybeBindOp {
        in  ma : MaybeA;           // Maybe a — Just a or Nothing
        in  f  : "a ⟶ Maybe b";  // effectful fn, HOF input
        out mb : MaybeB;
    }

    activity def MaybeBindProcess {
        object Ma   : MaybeA;           // Maybe a — Just a or Nothing
        object f    : "a ⟶ Maybe b";  // effectful fn, HOF input
        action bind : MaybeBindOp;
        object Mb   : MaybeB;           // Maybe b — result

        flow from Ma to bind;
        flow from f  to bind;
        flow from bind to Mb;
    }
}

#diagram {
    type   = activity
    title  = "Maybe Monad: bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b"
    name   = "bind"
    show Ma   as type
    show f    as hof
    show bind as function
    show Mb   as type
    tooltip Ma   = "Maybe<a> — Nothing propagates automatically (short-circuit)"
    tooltip f    = "(a ⟶ Maybe<b>) — effectful function, applied only if Ma is Just"
    tooltip bind = ">>= : Nothing → Nothing ; Just a → f a"
    tooltip Mb   = "Maybe<b> — Nothing or Just (result of f a)"
}
