// SysML v2 — STM monad IBD: type signature + bind contract
// (>>=) :: STM a ⟶ (a ⟶ STM b) ⟶ STM b
//
// STM a is an atomic action on transactional variables (TVar).
// bind sequences two atomic actions within the same transaction.
// The entire transaction either commits atomically or retries — there is no
// partial commit. Unlike IO, STM actions can call retry and orElse.

package STMSignature {
    private import FpDiagram::*;

    part def STMBindContext {
        #FpNodePresentation { role = "type"; tooltip = "STM a — an atomic action on TVars (transactional variables). Not yet committed."; }
        part sa_val : "STM a";        // atomic action that produces a
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ STM b) — given result a of the first action, constructs the next atomic step"; }
        part f_val  : "a ⟶ STM b";  // effectful function (HOF) — next atomic action
        #FpNodePresentation { role = "function"; tooltip = "Sequences two STM actions within ONE transaction:\n1. run sa to get a\n2. pass a to f to get STM b\n3. run that action\nIf any readTVar conflicts → the entire composed transaction retries from scratch."; }
        part bind   : STMBindOp;
        #FpNodePresentation { role = "type"; tooltip = "STM b — the composed atomic action. Runs inside atomically :: STM a -> IO a."; }
        part sb_val : "STM b";        // composed atomic action

        connection connect sa_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to sb_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: STM a ⟶ (a ⟶ STM b) ⟶ STM b — also called: >>=*/
        expose STMBindContext;
        render fpIbdDiagram;
    }
}

