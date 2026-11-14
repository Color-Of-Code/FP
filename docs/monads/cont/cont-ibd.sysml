// SysML v2 — Cont monad IBD: type signature + bind contract
// (>>=) :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b
//
// Cont r a = (a ⟶ r) ⟶ r — a computation waiting for "what to do next" (the continuation k).
// bind composes continuations: the current step runs LAST, handing its result into the chain.
// This inversion of control enables callCC, early exit, exceptions, and coroutines.

package ContSignature {
    private import FpDiagram::*;

    part def ContBindContext {
        #FpNodePresentation { role = "type"; tooltip = "Cont r a = (a ⟶ r) ⟶ r — a suspended computation waiting for its continuation k"; }
        part m_val  : "Cont r a";        // (a ⟶ r) ⟶ r  — waiting for a continuation
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Cont r b) — given result a, builds the next continuation-based step"; }
        part f_val  : "a ⟶ Cont r b";  // effectful function (HOF)
        #FpNodePresentation { role = "function"; tooltip = "bind m f = \\k -> m (\\a -> f a k)\nGive m a continuation that: feeds a into f, then passes original k to the result.\nThe current step runs last — this is continuation composition."; }
        part bind   : ContBindOp;
        #FpNodePresentation { role = "type"; tooltip = "Cont r b = (b ⟶ r) ⟶ r — the composed computation; callCC can capture k here for early exit"; }
        part res    : "Cont r b";        // (b ⟶ r) ⟶ r  — composed continuation

        connection connect m_val to bind;
        connection connect f_val to bind;
        connection connect bind  to res;
    }
    view diagram : FpIbdView {
        doc /*bind :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b — also called: Bind, >>=*/
        expose ContBindContext;
        render fpIbdDiagram;
    }
}

