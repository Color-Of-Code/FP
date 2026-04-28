// SysML v2 — IO motivation: WITH the IO monad
//
// Effects appear in the type signature.  compute :: Int → IO Int says
// out loud what the function actually does: it touches the file system
// and the log.  bind orders the effects deterministically — no surprise
// reorderings, no callers caught off-guard.

package IOMotivationWith {

    action def ReadFile {
        in  path  : "FilePath";
        out result : "IO Config";
    }

    action def LogMessage {
        in  cfg   : Config;
        out result : "IO ()";
    }

    action def Compute {
        in  cfg   : Config;
        out result : "IO Int";
    }

    activity def ComputeWith {
        object x          : Int;
        action readFile    : ReadFile;
        object ioCfg       : "IO Config";

        action logMessage  : LogMessage;
        object ioUnit      : "IO ()";

        action compute     : Compute;
        object ioResult    : "IO Int";

        flow from x          to readFile;
        flow from readFile   to ioCfg;
        flow from ioCfg      to logMessage : ">>= bind";
        flow from logMessage to ioUnit;
        flow from ioUnit     to compute    : ">>= bind";
        flow from compute    to ioResult;
    }
}

#diagram {
    type  = activity
    title = "With IO: effects explicit in the return type, ordered by bind"
    name  = "compute"
    show x          as value
    show readFile   as function
    show logMessage as function
    show compute    as function
    show ioCfg      as type
    show ioUnit     as type
    show ioResult   as type
    tooltip x          = "x : Int — the plain input.  Pure callers see only this in the API."
    tooltip readFile   = "readFile(path) → IO Config.  IO in the type warns callers: this touches the file system."
    tooltip logMessage = "logMessage(cfg) → IO ().  IO in the type warns callers: this writes a side log."
    tooltip compute    = "compute(cfg) → IO Int.  Effects are sequenced by bind — never reordered or duplicated."
    tooltip ioCfg      = "IO Config — a description of the effect that produces the config.  Not yet executed."
    tooltip ioUnit     = "IO () — a description of the log-write effect.  Sequenced after readFile by bind."
    tooltip ioResult   = "IO Int — the final described program.  The runtime (main) is the only thing that actually executes it."
}
