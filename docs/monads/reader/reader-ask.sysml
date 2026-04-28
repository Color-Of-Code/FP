// SysML v2 — Reader ask: implementation activity
// ask :: Reader r r
//
// Retrieve the entire environment as the result.  ask is the function
// \r -> r — when run with environment r, it returns r itself.

package ReaderAskImpl {

    action def Ask {
        out ra : "Reader r r";   // = \r -> r
    }

    activity def ReaderAskProcess {
        action ask : Ask;
        object ra  : "Reader r r";

        flow from ask to ra : "\\r -> r";
    }
}

#diagram {
    type  = activity
    title = "ask :: Reader r r   (return the environment as the result) — primitive"
    name  = "ask"
    show ask as function
    show ra  as type
    tooltip ask = "Ask: build the function \\r -> r — when run, returns the environment unchanged."
    tooltip ra  = "Reader r r — a reader whose result is the environment itself.  Use 'asks f' for a projected field."
}
