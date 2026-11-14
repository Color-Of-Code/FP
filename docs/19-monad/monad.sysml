// SysML v2 — monad bind activity diagram
// Concept: bind (>>=) :: Ma ⟶ (a ⟶ Mb) ⟶ Mb, and chaining
// Diagram type: activity — shows monadic value + HOF flowing into bind, chain

package MonadActivity {
    private import FpDiagram::*;

    action def BindOp {
        in  ma : Ma;             // monadic value
        in  f  : "a ⟶ Mb";  // effectful fn, HOF input
        out mb : Mb;
    }

    action def MonadChain {
        // input values
        #FpNodePresentation { role = "type"; tooltip = "Ma — the initial wrapped value"; }
        item Ma  : Ma;           // initial wrapped value
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Mb) — effectful function, received as a data token (HOF)"; }
        item f   : "a ⟶ Mb";  // HOF: first step function
        #FpNodePresentation { role = "hof"; tooltip = "(b ⟶ Mc) — second step function, also a HOF input"; }
        item g   : "b ⟶ Mc";  // HOF: second step function

        // bind actions
        #FpNodePresentation { role = "function"; tooltip = ">>= : unwraps Ma, applies f, produces Mb"; }
        action bind1 : BindOp;
        #FpNodePresentation { role = "function"; tooltip = ">>= : unwraps Mb, applies g, produces Mc"; }
        action bind2 : BindOp;

        // intermediate and final monadic values
        #FpNodePresentation { role = "type"; }
        item Mb  : Mb;           // result of first bind
        #FpNodePresentation { role = "type"; tooltip = "Mc — final result, effects from all steps collected"; }
        item Mc  : Mc;           // result of second bind (final)

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
    #FpViewPresentation { name = ">>="; }
    view diagram : FpActivityView {
        doc /*Monad: Ma >>= (a ⟶ Mb) >>= (b ⟶ Mc)*/
        expose MonadChain;
        render fpActivityDiagram;
    }
}

