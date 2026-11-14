// SysML v2 — Maybe monad: bind example

package MaybeMonadExample {
    private import FpDiagram::*;

    action def MaybeBindOp {
        in  ma : MaybeA;           // Maybe a — Just a or Nothing
        in  f  : "a ⟶ Maybe b";  // effectful fn, HOF input
        out mb : MaybeB;
    }

    action def MaybeBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "Maybe<a> — Nothing propagates automatically (short-circuit)"; }
        item Ma   : MaybeA;           // Maybe a — Just a or Nothing
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Maybe<b>) — effectful function, applied only if Ma is Just"; }
        item f    : "a ⟶ Maybe b";  // effectful fn, HOF input
        #FpNodePresentation { role = "function"; tooltip = ">>= : Nothing → Nothing ; Just a → f a"; }
        action bind : MaybeBindOp;
        #FpNodePresentation { role = "type"; tooltip = "Maybe<b> — Nothing or Just (result of f a)"; }
        item Mb   : MaybeB;           // Maybe b — result

        flow from Ma to bind;
        flow from f  to bind;
        flow from bind to Mb;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*Maybe Monad: bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b*/
        expose MaybeBindProcess;
        render fpActivityDiagram;
    }
}

