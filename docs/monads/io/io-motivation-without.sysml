// SysML v2 — IO motivation: WITHOUT the IO monad
//
// compute :: Int → Int looks pure.  The type system says: takes an Int,
// returns an Int, no side effects.  The body lies — it reads
// config.txt and writes to the log.  Callers cannot tell from the
// signature, equational reasoning is broken, and order of evaluation
// matters where it shouldn't.

package IOMotivationWithout {

    action def Compute {
        in  x      : Int;
        out result : Int;
    }

    activity def ComputeWithout {
        object x       : Int;
        action compute : Compute;
        object result  : Int;

        // hidden side effects — same compute action, but its body
        // performs IO that the type signature does not advertise
        action hiddenReadConfig  : "reads config.txt";
        action hiddenWriteLog    : "writes to log";

        flow from x       to compute;
        flow from compute to result;
        flow from compute to hiddenReadConfig : "hidden";
        flow from compute to hiddenWriteLog   : "hidden";
    }
}

#diagram {
    type  = activity
    title = "Without IO: side effects hidden inside a pure-looking type"
    name  = "compute"
    show x                as value
    show compute          as function
    show result           as type
    show hiddenReadConfig as function
    show hiddenWriteLog   as function
    tooltip x                = "x : Int — the only input the caller sees."
    tooltip compute          = "compute :: Int → Int — the type promises a pure function.  The implementation breaks that promise."
    tooltip result           = "result : Int — looks like a pure return, but its computation depended on a file and a log call."
    tooltip hiddenReadConfig = "Hidden effect: reads config.txt during execution.  Not visible in the type."
    tooltip hiddenWriteLog   = "Hidden effect: writes to a log during execution.  Not visible in the type."
}
