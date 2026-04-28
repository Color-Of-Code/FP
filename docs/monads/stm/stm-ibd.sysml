// SysML v2 — STM monad IBD: type signature + bind contract
// (>>=) :: STM a ⟶ (a ⟶ STM b) ⟶ STM b
//
// STM a is an atomic action on transactional variables (TVar).
// bind sequences two atomic actions within the same transaction.
// The entire transaction either commits atomically or retries — there is no
// partial commit. Unlike IO, STM actions can call retry and orElse.

package STMSignature {

    part def STMBindContext {
        part sa_val : "STM a";        // atomic action that produces a
        part f_val  : "a ⟶ STM b";  // effectful function (HOF) — next atomic action
        part bind   : STMBindOp;
        part sb_val : "STM b";        // composed atomic action

        connection connect sa_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to sb_val;
    }
}

#diagram {
    type  = ibd
    title = "bind :: STM a ⟶ (a ⟶ STM b) ⟶ STM b — also called: >>="
    render = STMBindContext
    show sa_val as type
    show f_val  as hof
    show bind   as function
    show sb_val as type
    tooltip sa_val = "STM a — an atomic action on TVars (transactional variables). Not yet committed."
    tooltip f_val  = "(a ⟶ STM b) — given result a of the first action, constructs the next atomic step"
    tooltip bind   = "Sequences two STM actions within ONE transaction:\n1. run sa to get a\n2. pass a to f to get STM b\n3. run that action\nIf any readTVar conflicts → the entire composed transaction retries from scratch."
    tooltip sb_val = "STM b — the composed atomic action. Runs inside atomically :: STM a -> IO a."
}
