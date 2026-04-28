// SysML v2 — Writer tell: implementation activity
// tell :: w ⟶ Writer w ()
//
// Append a log fragment w0 to the writer's accumulated log without
// producing any meaningful value (the result is unit).  This is the core
// "logging" primitive of the Writer monad.

package WriterTellImpl {

    action def Tell {
        in  w0  : w;
        out wu  : "Writer w ()";   // = ((), w0)
    }

    activity def WriterTellProcess {
        object w0 : w;
        action tell : Tell;
        object wu : "Writer w ()";

        flow from w0   to tell;
        flow from tell to wu : "((), w0)";
    }
}

#diagram {
    type  = activity
    title = "tell :: w ⟶ Writer w ()   (append w0 to the log; result is unit) — primitive"
    name  = "tell"
    show w0   as value
    show tell as function
    show wu   as type
    tooltip w0   = "w0 — a log fragment of monoid type w (e.g. \"step done\\n\", [event], 1)."
    tooltip tell = "Tell: emit w0 into the Writer log. The value component is unit ()."
    tooltip wu   = "Writer w () = ((), w0). Subsequent bind concatenates this fragment with later logs via the monoid <>."
}
