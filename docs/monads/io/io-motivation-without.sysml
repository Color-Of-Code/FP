// SysML v2 — IO motivation: WITHOUT the IO monad (bind)
//
// compute :: Int → Int LOOKS pure.  The type system says: takes an Int,
// returns an Int, no side effects.  The body lies — it reads
// config.txt and writes to the log.  Callers cannot tell from the
// signature, equational reasoning is broken, and order of evaluation
// matters where it shouldn't.

package IOMotivationWithout {
    private import FpDiagram::*;

    action def Compute {
        in  x : Int;
        out _ : Int;
    }

    action def ComputeWithout {
        // input
        #FpNodePresentation { role = "value"; tooltip = "x : Int — the only input the caller sees."; }
        item x : Int;

        // single "pure-looking" function
        #FpNodePresentation { role = "function"; tooltip = "compute :: Int → Int — the type promises a pure function. The implementation breaks that promise."; }
        action compute : Compute;

        // output
        #FpNodePresentation { role = "type"; tooltip = "result : Int — looks like a pure return, but its computation depended on a file and a log call."; }
        item result  : Int;

        // hidden side effects — same compute action, but its body
        // performs IO that the type signature does not advertise
        #FpNodePresentation { role = "function"; tooltip = "Hidden effect: reads config.txt during execution. Not visible in the type."; }
        action hiddenReadConfig  : "reads config.txt";
        #FpNodePresentation { role = "function"; tooltip = "Hidden effect: writes to a log during execution. Not visible in the type."; }
        action hiddenWriteLog    : "writes to log";

        flow from x       to compute;
        flow from compute to result;
        flow from compute to hiddenReadConfig : "hidden";
        flow from compute to hiddenWriteLog   : "hidden";
    }
    #FpViewPresentation { name = "compute"; }
    view diagram : FpActivityView {
        doc /*Without IO: side effects hidden inside a pure-looking type*/
        expose ComputeWithout;
        render fpActivityDiagram;
    }
}

