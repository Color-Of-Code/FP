// SysML v2 — IO motivation: WITH the IO monad (bind + pure)
//
// The effectful functions DO NOT COMPOSE naturally:
//   readFile   : FilePath → IO Config
//   logMessage : Config   → IO ()        ← expects Config, not IO Config
//   compute    : Config   → IO Int       ← expects Config, not IO ()
//
// (The chain re-uses cfg between logMessage and compute via a let;
//  bind threads it through together with effect-ordering.)
//
// Two combinators do all the work:
//   pure  : a → IO a                          — describe a no-effect computation
//   (>>=) : IO a → (a → IO b) → IO b
//
// pure lifts the plain FilePath into IO.  Each bind sequences effects
// deterministically: no surprise reorderings, no callers caught off
// guard.  IO appears in every signature so callers cannot ignore it.

package IOMotivationWith {

    action def ReadFile {
        in  path : "FilePath";
        out _    : "IO Config";
    }

    action def LogAndCompute {
        in  cfg  : Config;
        out _    : "IO Int";
    }

    // pure : a → IO a
    action def Pure {
        in  a : a;
        out _ : "IO a";
    }

    // bind : IO a → (a → IO b) → IO b
    action def Bind {
        in  ma : "IO a";
        in  f  : "a ⟶ IO b";
        out _  : "IO b";
    }

    activity def ComputeWith {
        // input
        object path        : "FilePath";

        // lift the plain path into IO — entry point of the chain
        action purePath    : Pure;

        // bind in readFile
        object readFileFn  : "FilePath ⟶ IO Config";
        action bindRead    : Bind;

        // bind in the log-then-compute continuation (a single function
        // because both effects need cfg in scope)
        object logCompFn   : "Config ⟶ IO Int";
        action bindLogComp : Bind;

        // output
        object ioResult    : "IO Int";

        // main flow runs through the bind nodes
        flow from path        to purePath;
        flow from purePath    to bindRead    : "IO FilePath";
        flow from bindRead    to bindLogComp : "IO Config";
        flow from bindLogComp to ioResult    : "IO Int";

        // each effectful function is supplied to its bind as the f argument
        flow from readFileFn  to bindRead;
        flow from logCompFn   to bindLogComp;

        // ── Swimlanes ───────────────────────────────────────────────────────
        lane plain : "Plain values & functions" =
            path, readFileFn, logCompFn, ioResult;
        lane monad : "IO monad" =
            purePath, bindRead, bindLogComp;
    }
}

#diagram {
    type  = activity
    title = "With pure + bind: effects in the type, sequenced explicitly through bind"
    name  = "compute"
    show path        as value
    show purePath    as function
    show bindRead    as function
    show bindLogComp as function
    show readFileFn  as hof
    show logCompFn   as hof
    show ioResult    as type
    tooltip path        = "FilePath — plain input. Pure callers see only this in the API."
    tooltip purePath    = "pure : FilePath → IO FilePath. Lifts the plain path so the chain can start uniformly with bind."
    tooltip bindRead    = ">>= : sequences readFile after pure. The runtime guarantees this effect happens before the next bind."
    tooltip bindLogComp = ">>= : sequences the (logMessage cfg >> compute cfg) continuation. Effect order is deterministic."
    tooltip readFileFn  = "readFile : FilePath → IO Config. HOF argument — its input is FilePath, not IO FilePath, so it cannot sit on the main flow."
    tooltip logCompFn   = "λcfg. logMessage cfg >> compute cfg : Config → IO Int. HOF argument — runs both side-effects in order, both seeing cfg."
    tooltip ioResult    = "IO Int — the final described program. The runtime (main) is the only thing that actually executes it."
}

