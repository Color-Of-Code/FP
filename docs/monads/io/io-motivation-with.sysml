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
    private import FpDiagram::*;

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

    action def ComputeWith {
        // input
        #FpNodePresentation { role = "value"; tooltip = "FilePath — plain input. Pure callers see only this in the API."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item path        : "FilePath";

        // lift the plain path into IO — entry point of the chain
        #FpNodePresentation { role = "function"; tooltip = "pure : FilePath → IO FilePath. Lifts the plain path so the chain can start uniformly with bind."; laneId = "monad"; laneLabel = "IO monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action purePath    : Pure;

        // bind in readFile
        #FpNodePresentation { role = "hof"; tooltip = "readFile : FilePath → IO Config. HOF argument — its input is FilePath, not IO FilePath, so it cannot sit on the main flow."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }
        item readFileFn  : "FilePath ⟶ IO Config";
        #FpNodePresentation { role = "function"; tooltip = ">>= : sequences readFile after pure. The runtime guarantees this effect happens before the next bind."; laneId = "monad"; laneLabel = "IO monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindRead    : Bind;

        // bind in the log-then-compute continuation (a single function
        // because both effects need cfg in scope)
        #FpNodePresentation { role = "hof"; tooltip = "λcfg. logMessage cfg >> compute cfg : Config → IO Int. HOF argument — runs both side-effects in order, both seeing cfg."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "2"; }
        item logCompFn   : "Config ⟶ IO Int";
        #FpNodePresentation { role = "function"; tooltip = ">>= : sequences the (logMessage cfg >> compute cfg) continuation. Effect order is deterministic."; laneId = "monad"; laneLabel = "IO monad"; laneOrder = "1"; laneMemberOrder = "2"; }
        action bindLogComp : Bind;

        // output
        #FpNodePresentation { role = "type"; tooltip = "IO Int — the final described program. The runtime (main) is the only thing that actually executes it."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "3"; }
        item ioResult    : "IO Int";

        // main flow runs through the bind nodes
        flow from path        to purePath;
        flow from purePath    to bindRead    : "IO FilePath";
        flow from bindRead    to bindLogComp : "IO Config";
        flow from bindLogComp to ioResult    : "IO Int";

        // each effectful function is supplied to its bind as the f argument
        flow from readFileFn  to bindRead;
        flow from logCompFn   to bindLogComp;

        // ── Swimlanes ───────────────────────────────────────────────────────


    }
    #FpViewPresentation { name = "compute"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: effects in the type, sequenced explicitly through bind*/
        expose ComputeWith;
        render fpActivityDiagram;
    }
}

