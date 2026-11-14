// SysML v2 — Writer pure: implementation activity
// pure :: a ⟶ (a, mempty)
//
// Pair a with the monoid identity element of the log type w.
// "mempty" is the empty log — "" for String, [] for List, 0 for Sum, mempty
// for any Monoid w. Using anything else (e.g. a sentinel log line) would
// break the left-identity law.

package WriterPureImpl {
    private import FpDiagram::*;

    action def PairWithMempty {
        in  a   : a;
        out wa  : "(a, mempty)";
    }

    action def WriterPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0  : a;
        #FpNodePresentation { role = "function"; tooltip = "PairWithMempty: pair a0 with the monoid identity of w (\"\", [], 0, mempty, …). The empty log accumulates correctly when combined with any other log."; }
        action wrap : PairWithMempty;
        #FpNodePresentation { role = "type"; tooltip = "(a0, mempty) : (a, w) — value preserved, log empty. Subsequent bind appends each step's log fragment via <>."; }
        item wa  : "(a, mempty)";

        flow from a0  to wrap;
        flow from wrap to wa;
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ (a, mempty)   (pair with the monoid identity of the log) — also called: return*/
        expose WriterPureProcess;
        render fpActivityDiagram;
    }
}

