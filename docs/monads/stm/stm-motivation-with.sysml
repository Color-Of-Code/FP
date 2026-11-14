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
    private import FpDiagram::*;

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

    action def TransferWith {
        // entry: readA is itself an STM action (no input)
        #FpNodePresentation { role = "function"; tooltip = "readTVar accountA : STM Int — STM action. Read tracked, not committed alone."; laneId = "monad"; laneLabel = "STM monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action readA       : ReadA;

        // bind in writeA-then-readB-then-writeB as a single continuation
        // (writeA captures aVal; readB and writeB chain naturally)
        #FpNodePresentation { role = "hof"; tooltip = "λaVal. writeTVar accountA (aVal - delta) >> readTVar accountB. HOF argument — captures aVal in scope."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item writeAThenFn : "Int ⟶ STM Int";
        #FpNodePresentation { role = "function"; tooltip = ">>= : sequences writeA(-delta) and the readB step. Reads/writes accumulate in the transaction."; laneId = "monad"; laneLabel = "STM monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindWriteA  : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "λbVal. writeTVar accountB (bVal + delta). HOF argument — captures bVal."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }

        item writeBFn    : "Int ⟶ STM ()";
        #FpNodePresentation { role = "function"; tooltip = ">>= : sequences writeB(+delta). Final step before commit."; laneId = "monad"; laneLabel = "STM monad"; laneOrder = "1"; laneMemberOrder = "2"; }
        action bindWriteB  : Bind;

        // output
        #FpNodePresentation { role = "type"; tooltip = "atomically — commits all four operations as one unit, or restarts the whole transaction on conflict. No deadlock possible."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "2"; }
        item commit      : "IO ()";

        // main flow runs through the bind nodes
        flow from readA       to bindWriteA : "STM Int";
        flow from bindWriteA  to bindWriteB : "STM Int";
        flow from bindWriteB  to commit     : "atomically";

        // each STM continuation is supplied as the f argument
        flow from writeAThenFn to bindWriteA;
        flow from writeBFn     to bindWriteB;

        // ── Swimlanes ───────────────────────────────────────────────────────


    }
    #FpViewPresentation { name = "transfer"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: STM actions compose freely; runtime commits atomically or retries*/
        expose TransferWith;
        render fpActivityDiagram;
    }
}

