// SysML v2 — State modify: implementation activity
// modify :: (s ⟶ s) ⟶ State s ()
//
// Apply f to the current state, install the result as the new state, and
// produce unit.  Defined as: modify f = get >>= put . f.

package StateModifyImpl {

    action def Modify {
        in  f   : "s ⟶ s";
        out su  : "State s ()";   // = \s -> ((), f s)
    }

    activity def StateModifyProcess {
        object f   : "s ⟶ s";
        action mdf : Modify;
        object su  : "State s ()";

        flow from f   to mdf;
        flow from mdf to su : "\\s -> ((), f s)";
    }
}

#diagram {
    type  = activity
    title = "modify :: (s ⟶ s) ⟶ State s ()   (transform the state in place; result is unit) — primitive"
    name  = "modify"
    show f   as value
    show mdf as function
    show su  as type
    tooltip f   = "f : s ⟶ s — pure state-update function (e.g. (+1), Map.insert k v, addLog)."
    tooltip mdf = "Modify: build \\s -> ((), f s). Equivalent to: do { s <- get; put (f s) }."
    tooltip su  = "State s () — unit value, new state is f(prev). Reads and writes happen in a single step."
}
