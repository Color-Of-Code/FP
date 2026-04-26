// SysML v2 — monad: pure and bind (single-step) activity diagrams

package MonadPureBind {

    action def PureLift {
        in  a  : a;   // plain value
        out Ma : Ma;  // lifted into monad
    }

    action def BindStep {
        in  ma : Ma;             // monadic value
        in  f  : "a ⟶ Mb";  // effectful fn, HOF input
        out mb : Mb;
    }

    activity def PureProcess {
        object a  : a;    // plain value
        action pur : PureLift;
        object Ma : Ma;   // lifted into monad

        flow from a   to pur;
        flow from pur to Ma;
    }

    activity def BindProcess {
        object Ma   : Ma;            // monadic value to unwrap
        object f    : "a ⟶ Mb";  // effectful function, HOF input
        action bind : BindStep;
        object Mb   : Mb;            // result

        flow from Ma to bind;
        flow from f  to bind;
        flow from bind to Mb;
    }
}

#diagram {
    type   = activity
    title  = "pure :: a ⟶ Ma  |  bind :: Ma ⟶ (a ⟶ Mb) ⟶ Mb"
    name   = "bind"
    render = BindProcess
    show Ma   as type
    show f    as hof
    show bind as function
    show Mb   as type
    tooltip Ma   = "Ma — the monadic value to unwrap"
    tooltip f    = "(a ⟶ Mb) — effectful function, passed as a data token (HOF)"
    tooltip bind = ">>= (bind): unwraps a from Ma, applies f, returns Mb"
    tooltip Mb   = "Mb — the result of applying the effectful function"
}
