// SysML v2 — Writer tell: implementation activity
// tell :: w ⟶ Writer w ()
//
// Append a log fragment w0 to the writer's accumulated log without
// producing any meaningful value (the result is unit).  This is the core
// "logging" primitive of the Writer monad.

package WriterTellImpl {
    private import FpDiagram::*;

    action def Tell {
        in  w0  : w;
        out wu  : "Writer w ()";   // = ((), w0)
    }

    action def WriterTellProcess {
        #FpNodePresentation { role = "value"; tooltip = "w0 — a log fragment of monoid type w (e.g. \"step done\\n\", [event], 1)."; }
        item w0 : w;
        #FpNodePresentation { role = "function"; tooltip = "Tell: emit w0 into the Writer log. The value component is unit ()."; }
        action tell : Tell;
        #FpNodePresentation { role = "type"; tooltip = "Writer w () = ((), w0). Subsequent bind concatenates this fragment with later logs via the monoid <>."; }
        item wu : "Writer w ()";

        flow from w0   to tell;
        flow from tell to wu : "((), w0)";
    }
    #FpViewPresentation { name = "tell"; }
    view diagram : FpActivityView {
        doc /*tell :: w ⟶ Writer w ()   (append w0 to the log; result is unit) — primitive*/
        expose WriterTellProcess;
        render fpActivityDiagram;
    }
}

