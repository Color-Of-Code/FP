// SysML v2 — Cont callCC: implementation activity
// callCC :: ((a ⟶ Cont r b) ⟶ Cont r a) ⟶ Cont r a
//
// "call with current continuation" — capture the surrounding
// continuation k and hand it to the user's function f as an escape
// procedure.  Calling that escape with a value short-circuits to the
// outer continuation, skipping any pending work.

package ContCallCCImpl {
    private import FpDiagram::*;

    action def CallCC {
        in  f  : "(a ⟶ Cont r b) ⟶ Cont r a";
        out ca : "Cont r a";
    }

    action def ContCallCCProcess {
        #FpNodePresentation { role = "value"; tooltip = "f — user-supplied function that receives the captured escape (a ⟶ Cont r b) and returns the body's continuation."; }
        item f  : "(a ⟶ Cont r b) ⟶ Cont r a";
        #FpNodePresentation { role = "function"; tooltip = "CallCC: pack the outer k so that calling escape(a) bypasses any code following callCC and resumes the outer continuation with a."; }
        action cc : CallCC;
        #FpNodePresentation { role = "type"; tooltip = "Cont r a — same outer type as f's result; control flow may exit early via the escape."; }
        item ca : "Cont r a";

        flow from f  to cc;
        flow from cc to ca : "\\k -> runCont (f (\\a -> \\_ -> k a)) k";
    }
    #FpViewPresentation { name = "callCC"; }
    view diagram : FpActivityView {
        doc /*callCC :: ((a ⟶ Cont r b) ⟶ Cont r a) ⟶ Cont r a   (capture the current continuation as an escape) — primitive*/
        expose ContCallCCProcess;
        render fpActivityDiagram;
    }
}

