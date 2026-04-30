// SysML v2 — STM motivation: WITH the STM monad (bind + pure)
//
// STM actions DO NOT COMPOSE naturally:
//   readA  : STM Int
//   writeA : Int → STM ()        ← expects Int, not STM Int
//   readB  : STM Int
//   writeB : Int → STM ()
//
// Two combinators do all the work:
//   pure  : a → STM a                              — describe a no-effect transaction
//   (>>=) : STM a → (a → STM b) → STM b
//
// bind sequences STM actions; the runtime tracks the read-set and
// write-set and either commits the whole chain atomically or restarts
// the transaction on conflict.  No locks, no manual ordering.

package STMMotivationWith {

    action def ReadA {
        out _ : "STM Int";
    }

    action def ReadB {
        out _ : "STM Int";
    }

    // bind : STM a → (a → STM b) → STM b
    action def Bind {
        in  ma : "STM a";
        in  f  : "a ⟶ STM b";
        out _  : "STM b";
    }

    activity def TransferWith {
        // entry: readA is itself an STM action (no input)
        action readA       : ReadA;

        // bind in writeA-then-readB-then-writeB as a single continuation
        // (writeA captures aVal; readB and writeB chain naturally)
        object writeAThenFn : "Int ⟶ STM Int";
        action bindWriteA  : Bind;

        object writeBFn    : "Int ⟶ STM ()";
        action bindWriteB  : Bind;

        // output
        object commit      : "IO ()";

        // main flow runs through the bind nodes
        flow from readA       to bindWriteA : "STM Int";
        flow from bindWriteA  to bindWriteB : "STM Int";
        flow from bindWriteB  to commit     : "atomically";

        // each STM continuation is supplied as the f argument
        flow from writeAThenFn to bindWriteA;
        flow from writeBFn     to bindWriteB;
    }
}

#diagram {
    type  = activity
    title = "With pure + bind: STM actions compose freely; runtime commits atomically or retries"
    name  = "transfer"
    show readA        as function
    show bindWriteA   as function
    show bindWriteB   as function
    show writeAThenFn as hof
    show writeBFn     as hof
    show commit       as type
    tooltip readA        = "readTVar accountA : STM Int — STM action. Read tracked, not committed alone."
    tooltip bindWriteA   = ">>= : sequences writeA(-delta) and the readB step. Reads/writes accumulate in the transaction."
    tooltip bindWriteB   = ">>= : sequences writeB(+delta). Final step before commit."
    tooltip writeAThenFn = "λaVal. writeTVar accountA (aVal - delta) >> readTVar accountB. HOF argument — captures aVal in scope."
    tooltip writeBFn     = "λbVal. writeTVar accountB (bVal + delta). HOF argument — captures bVal."
    tooltip commit       = "atomically — commits all four operations as one unit, or restarts the whole transaction on conflict. No deadlock possible."
}

