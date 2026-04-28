// SysML v2 — Writer pure: implementation activity
// pure :: a ⟶ (a, mempty)
//
// Pair a with the monoid identity element of the log type w.
// "mempty" is the empty log — "" for String, [] for List, 0 for Sum, mempty
// for any Monoid w. Using anything else (e.g. a sentinel log line) would
// break the left-identity law.

package WriterPureImpl {

    action def PairWithMempty {
        in  a   : a;
        out wa  : "(a, mempty)";
    }

    activity def WriterPureProcess {
        object a0  : a;
        action wrap : PairWithMempty;
        object wa  : "(a, mempty)";

        flow from a0  to wrap;
        flow from wrap to wa;
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ (a, mempty)   (pair with the monoid identity of the log) — also called: return"
    name  = "pure"
    show a0   as value
    show wrap as function
    show wa   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "PairWithMempty: pair a0 with the monoid identity of w (\"\", [], 0, mempty, …). The empty log accumulates correctly when combined with any other log."
    tooltip wa   = "(a0, mempty) : (a, w) — value preserved, log empty. Subsequent bind appends each step's log fragment via <>."
}
