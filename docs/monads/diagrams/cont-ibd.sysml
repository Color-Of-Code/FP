// SysML v2 — Cont monad IBD: type signature + bind contract
// (>>=) :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b
//
// Cont r a = (a ⟶ r) ⟶ r — a computation waiting for "what to do next" (the continuation k).
// bind composes continuations: the current step runs LAST, handing its result into the chain.
// This inversion of control enables callCC, early exit, exceptions, and coroutines.

package ContSignature {

    part def ContBindContext {
        part m_val  : "Cont r a";        // (a ⟶ r) ⟶ r  — waiting for a continuation
        part f_val  : "a ⟶ Cont r b";  // effectful function (HOF)
        part bind   : ContBindOp;
        part res    : "Cont r b";        // (b ⟶ r) ⟶ r  — composed continuation

        connection connect m_val to bind;
        connection connect f_val to bind;
        connection connect bind  to res;
    }
}

#diagram {
    type  = ibd
    title = "(>>=) :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b"
    render = ContBindContext
    show m_val as type
    show f_val as hof
    show bind  as function
    show res   as type
    tooltip m_val = "Cont r a = (a ⟶ r) ⟶ r — a suspended computation waiting for its continuation k"
    tooltip f_val = "(a ⟶ Cont r b) — given result a, builds the next continuation-based step"
    tooltip bind  = "bind m f = \\k -> m (\\a -> f a k)\nGive m a continuation that: feeds a into f, then passes original k to the result.\nThe current step runs last — this is continuation composition."
    tooltip res   = "Cont r b = (b ⟶ r) ⟶ r — the composed computation; callCC can capture k here for early exit"
}
