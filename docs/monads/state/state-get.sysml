// SysML v2 — State get: implementation activity
// get :: State s s
//
// Read the current state and produce it as the result.  The state itself
// is unchanged.  Equivalent to \s -> (s, s).

package StateGetImpl {
    private import FpDiagram::*;

    action def Get {
        out gs : "State s s";   // = \s -> (s, s)
    }

    action def StateGetProcess {
        #FpNodePresentation { role = "function"; tooltip = "Get: build \\s -> (s, s) — value and outgoing state are both the incoming state."; }
        action get : Get;
        #FpNodePresentation { role = "type"; tooltip = "State s s — a stateful computation that observes s without modifying it."; }
        item gs  : "State s s";

        flow from get to gs : "\\s -> (s, s)";
    }
    #FpViewPresentation { name = "get"; }
    view diagram : FpActivityView {
        doc /*get :: State s s   (return the current state as the result; state unchanged) — primitive*/
        expose StateGetProcess;
        render fpActivityDiagram;
    }
}

