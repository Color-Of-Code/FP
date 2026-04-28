// SysML v2 — State put: implementation activity
// put :: s ⟶ State s ()
//
// Replace the current state with s' and produce unit.  The new state is
// independent of whatever state was incoming.

package StatePutImpl {

    action def Put {
        in  sNew : s;
        out su   : "State s ()";   // = \_ -> ((), sNew)
    }

    activity def StatePutProcess {
        object sNew : s;
        action put  : Put;
        object su   : "State s ()";

        flow from sNew to put;
        flow from put  to su : "\\_ -> ((), sNew)";
    }
}

#diagram {
    type  = activity
    title = "put :: s ⟶ State s ()   (overwrite the state with s'; result is unit) — primitive"
    name  = "put"
    show sNew as value
    show put  as function
    show su   as type
    tooltip sNew = "sNew — the new state value to install (replaces whatever state was current)."
    tooltip put  = "Put: build \\_ -> ((), sNew) — discards incoming state, emits sNew as outgoing state."
    tooltip su   = "State s () — value is unit, state is now sNew. Subsequent steps see sNew."
}
