// SysML v2 — State get: implementation activity
// get :: State s s
//
// Read the current state and produce it as the result.  The state itself
// is unchanged.  Equivalent to \s -> (s, s).

package StateGetImpl {

    action def Get {
        out gs : "State s s";   // = \s -> (s, s)
    }

    activity def StateGetProcess {
        action get : Get;
        object gs  : "State s s";

        flow from get to gs : "\\s -> (s, s)";
    }
}

#diagram {
    type  = activity
    title = "get :: State s s   (return the current state as the result; state unchanged) — primitive"
    name  = "get"
    show get as function
    show gs  as type
    tooltip get = "Get: build \\s -> (s, s) — value and outgoing state are both the incoming state."
    tooltip gs  = "State s s — a stateful computation that observes s without modifying it."
}
