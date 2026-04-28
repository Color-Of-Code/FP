// SysML v2 — STM orElse: implementation activity
// orElse :: STM a ⟶ STM a ⟶ STM a
//
// Try the first transaction; if it calls retry, discard its effects and
// run the second transaction instead.  Provides composable choice without
// resorting to exceptions.

package STMOrElseImpl {

    action def OrElse {
        in  s1 : "STM a";
        in  s2 : "STM a";
        out sr : "STM a";
    }

    activity def STMOrElseProcess {
        object s1 : "STM a";
        object s2 : "STM a";
        action oe : OrElse;
        object sr : "STM a";

        flow from s1 to oe;
        flow from s2 to oe;
        flow from oe to sr : "run s1; on retry, run s2";
    }
}

#diagram {
    type  = activity
    title = "orElse :: STM a ⟶ STM a ⟶ STM a   (try s1; on retry, fall back to s2) — primitive"
    name  = "orElse"
    show s1 as value
    show s2 as value
    show oe as function
    show sr as type
    tooltip s1 = "s1 : STM a — primary transaction.  If it commits, sr is its result."
    tooltip s2 = "s2 : STM a — alternative transaction tried only if s1 calls retry."
    tooltip oe = "OrElse: a left-biased choice. Reads from s1 are still tracked even when s2 runs, so the combined transaction blocks if both retry."
    tooltip sr = "STM a — result of whichever branch commits.  Never blocks unless both branches retry."
}
