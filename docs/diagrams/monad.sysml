// SysML v2 — monad bind activity diagram
// Concept: bind (>>=) :: Ma ⟶ (a ⟶ Mb) ⟶ Mb, and chaining
// Diagram type: activity — shows monadic value + HOF flowing into bind, chain

package MonadActivity {

    action def BindOp {
        in  ma : Ma;             // monadic value
        in  f  : "a ⟶ Mb";  // effectful fn, HOF input
        out mb : Mb;
    }

    activity def MonadChain {
        // input values
        object Ma  : Ma;           // initial wrapped value
        object f   : "a ⟶ Mb";  // HOF: first step function
        object g   : "b ⟶ Mc";  // HOF: second step function

        // bind actions
        action bind1 : BindOp;
        action bind2 : BindOp;

        // intermediate and final monadic values
        object Mb  : Mb;           // result of first bind
        object Mc  : Mc;           // result of second bind (final)

        // object flows — data token movement
        flow from Ma   to bind1;
        flow from f    to bind1;
        flow from bind1 to Mb;

        flow from Mb   to bind2;
        flow from g    to bind2;
        flow from bind2 to Mc;

        // control flow — bind1 completes before bind2 begins
        succession bind1 then bind2;
    }
}

#diagram {
    type  = activity
    title = "Monad: Ma >>= (a ⟶ Mb) >>= (b ⟶ Mc)"
    name  = ">>=" 
    show Ma    as type
    show f     as hof
    show g     as hof
    show bind1 as function
    show bind2 as function
    show Mb    as type
    show Mc    as type
    tooltip Ma    = "Ma — the initial wrapped value"
    tooltip f     = "(a ⟶ Mb) — effectful function, received as a data token (HOF)"
    tooltip g     = "(b ⟶ Mc) — second step function, also a HOF input"
    tooltip bind1 = ">>= : unwraps Ma, applies f, produces Mb"
    tooltip bind2 = ">>= : unwraps Mb, applies g, produces Mc"
    tooltip Mc    = "Mc — final result, effects from all steps collected"
}
