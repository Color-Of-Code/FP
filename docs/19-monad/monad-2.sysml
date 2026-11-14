// SysML v2 — monad: pure and bind (single-step) activity diagrams

package MonadPureBind {
    private import FpDiagram::*;

    action def PureLift {
        in  a  : a;   // plain value
        out Ma : Ma;  // lifted into monad
    }

    action def BindStep {
        in  ma : Ma;             // monadic value
        in  f  : "a ⟶ Mb";  // effectful fn, HOF input
        out mb : Mb;
    }

    action def PureProcess {
        item a  : a;    // plain value
        action pur : PureLift;
        #FpNodePresentation { role = "type"; tooltip = "Ma — the monadic value to unwrap"; }
        item Ma : Ma;   // lifted into monad

        flow from a   to pur;
        flow from pur to Ma;
    }

    action def BindProcess {
        #FpNodePresentation { role = "type"; tooltip = "Ma — the monadic value to unwrap"; }
        item Ma   : Ma;            // monadic value to unwrap
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Mb) — effectful function, passed as a data token (HOF)"; }
        item f    : "a ⟶ Mb";  // effectful function, HOF input
        #FpNodePresentation { role = "function"; tooltip = "bind: unwraps a from Ma, applies f, returns Mb. Per-language aliases: flatMap, andThen / and_then, SelectMany, .then, >>=."; }
        action bind : BindStep;
        #FpNodePresentation { role = "type"; tooltip = "Mb — the result of applying the effectful function"; }
        item Mb   : Mb;            // result

        flow from Ma to bind;
        flow from f  to bind;
        flow from bind to Mb;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Ma  |  bind :: Ma ⟶ (a ⟶ Mb) ⟶ Mb*/
        expose BindProcess;
        render fpActivityDiagram;
    }
}

