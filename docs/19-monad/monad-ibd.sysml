// SysML v2 — monad IBD: type signature
// (>>=) :: Ma ⟶ (a ⟶ Mb) ⟶ Mb

package MonadSignature {
    private import FpDiagram::*;

    part def BindContext {
        // inputs
        #FpNodePresentation { role = "type"; tooltip = "Ma — monadic value, provides unwrapped a to the continuation"; }
        part ma_val : Ma;            // monadic value
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Mb) — the continuation: maps each a to a new monadic Mb"; }
        part f_val  : "a ⟶ Mb";    // continuation / monadic function (HOF)

        // the operation
        #FpNodePresentation { role = "function"; tooltip = ">>= (bind): sequences two monadic actions, threading the value"; }
        part bind   : BindOp;

        // output
        #FpNodePresentation { role = "type"; tooltip = "Mb — final monadic result"; }
        part mb_val : Mb;

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
    view diagram : FpIbdView {
        doc /*(>>=) :: Ma ⟶ (a ⟶ Mb) ⟶ Mb*/
        expose BindContext;
        render fpIbdDiagram;
    }
}

