package STMOverview {
    private import FpDiagram::*;

    part def TransactionContext {
        #FpNodePresentation { role = "value"; tooltip = "A shared mutable cell, accessed only through STM operations."; }
        part cell : "TVar a";
        #FpNodePresentation { role = "function"; tooltip = "readTVar :: TVar a ⟶ STM a — read the cell value inside a transaction."; }
        part read : ReadTVar;
        #FpNodePresentation { role = "value"; tooltip = "A value to be written tentatively inside the transaction."; }
        part newValue : a;
        #FpNodePresentation { role = "function"; tooltip = "writeTVar :: TVar a ⟶ a ⟶ STM () — record a tentative write."; }
        part write : WriteTVar;
        #FpNodePresentation { role = "type"; tooltip = "The transactional program composes reads and writes before it is run."; }
        part transaction : "STM a";
        #FpNodePresentation { role = "function"; tooltip = "atomically :: STM a ⟶ IO a — commit all writes together or retry the whole transaction."; }
        part commit : Atomically;
        #FpNodePresentation { role = "type"; tooltip = "The result is available in IO only after the transaction commits."; }
        part result : "IO a";

        connection connect cell to read;
        connection connect cell to write;
        connection connect newValue to write;
        connection connect read to transaction;
        connection connect write to transaction;
        connection connect transaction to commit;
        connection connect commit to result;
    }

    view diagram : FpIbdView {
        doc /*TVar reads and writes compose into an STM transaction committed by atomically*/
        expose TransactionContext;
        render fpIbdDiagram;
    }
}
