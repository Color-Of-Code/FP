// SysML v2 — STM motivation: WITH STM
//
// Reads and writes are first-class STM actions.  Compose them freely
// with bind; the runtime tracks the read-set and write-set and either
// commits atomically or retries the whole transaction on conflict.
// No locks to acquire, no ordering to remember.

package STMMotivationWith {

    action def ReadA {
        out value : "Int";
    }

    action def WriteA {
        in  delta : "Int";
    }

    action def ReadB {
        out value : "Int";
    }

    action def WriteB {
        in  delta : "Int";
    }

    activity def TransferWith {
        action readA  : ReadA;
        action writeA : WriteA;
        action readB  : ReadB;
        action writeB : WriteB;
        object commit : "IO ()";

        flow from readA  to writeA : ">>= bind";
        flow from writeA to readB  : ">>= bind";
        flow from readB  to writeB : ">>= bind";
        flow from writeB to commit : "atomically";
    }
}

#diagram {
    type  = activity
    title = "With STM: compose reads and writes freely — runtime prevents conflicts"
    name  = "transfer"
    show readA  as function
    show writeA as function
    show readB  as function
    show writeB as function
    show commit as type
    tooltip readA  = "readTVar accountA — STM action.  Reads are tracked, never committed alone."
    tooltip writeA = "writeTVar accountA — STM action.  No lock involved; the runtime decides what is consistent."
    tooltip readB  = "readTVar accountB — composes via bind like any other STM action."
    tooltip writeB = "writeTVar accountB — composes via bind."
    tooltip commit = "atomically — commits all four operations as one unit, or restarts the whole transaction on conflict.  No deadlock possible."
}
