// SysML v2 — Reader ask: implementation activity
// ask :: Reader r r
//
// Retrieve the entire environment as the result.  ask is the function
// \r -> r — when run with environment r, it returns r itself.

package ReaderAskImpl {
    private import FpDiagram::*;

    action def Ask {
        out ra : "Reader r r";   // = \r -> r
    }

    action def ReaderAskProcess {
        #FpNodePresentation { role = "function"; tooltip = "Ask: build the function \\r -> r — when run, returns the environment unchanged."; }
        action ask : Ask;
        #FpNodePresentation { role = "type"; tooltip = "Reader r r — a reader whose result is the environment itself.  Use 'asks f' for a projected field."; }
        item ra  : "Reader r r";

        flow from ask to ra : "\\r -> r";
    }
    #FpViewPresentation { name = "ask"; }
    view diagram : FpActivityView {
        doc /*ask :: Reader r r   (return the environment as the result) — primitive*/
        expose ReaderAskProcess;
        render fpActivityDiagram;
    }
}

