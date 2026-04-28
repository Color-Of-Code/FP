// SysML v2 — Cont callCC: implementation activity
// callCC :: ((a ⟶ Cont r b) ⟶ Cont r a) ⟶ Cont r a
//
// "call with current continuation" — capture the surrounding
// continuation k and hand it to the user's function f as an escape
// procedure.  Calling that escape with a value short-circuits to the
// outer continuation, skipping any pending work.

package ContCallCCImpl {

    action def CallCC {
        in  f  : "(a ⟶ Cont r b) ⟶ Cont r a";
        out ca : "Cont r a";
    }

    activity def ContCallCCProcess {
        object f  : "(a ⟶ Cont r b) ⟶ Cont r a";
        action cc : CallCC;
        object ca : "Cont r a";

        flow from f  to cc;
        flow from cc to ca : "\\k -> runCont (f (\\a -> \\_ -> k a)) k";
    }
}

#diagram {
    type  = activity
    title = "callCC :: ((a ⟶ Cont r b) ⟶ Cont r a) ⟶ Cont r a   (capture the current continuation as an escape) — primitive"
    name  = "callCC"
    show f  as value
    show cc as function
    show ca as type
    tooltip f  = "f — user-supplied function that receives the captured escape (a ⟶ Cont r b) and returns the body's continuation."
    tooltip cc = "CallCC: pack the outer k so that calling escape(a) bypasses any code following callCC and resumes the outer continuation with a."
    tooltip ca = "Cont r a — same outer type as f's result; control flow may exit early via the escape."
}
