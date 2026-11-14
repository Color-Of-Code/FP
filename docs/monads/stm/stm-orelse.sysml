// SysML v2 — STM orElse: implementation activity
// orElse :: STM a ⟶ STM a ⟶ STM a
//
// Try the first transaction; if it calls retry, discard its effects and
// run the second transaction instead.  Provides composable choice without
// resorting to exceptions.

package STMOrElseImpl {
    private import FpDiagram::*;

    action def OrElse {
        in  s1 : "STM a";
        in  s2 : "STM a";
        out sr : "STM a";
    }

    action def STMOrElseProcess {
        #FpNodePresentation { role = "value"; tooltip = "s1 : STM a — primary transaction.  If it commits, sr is its result."; }
        item s1 : "STM a";
        #FpNodePresentation { role = "value"; tooltip = "s2 : STM a — alternative transaction tried only if s1 calls retry."; }
        item s2 : "STM a";
        #FpNodePresentation { role = "function"; tooltip = "OrElse: a left-biased choice. Reads from s1 are still tracked even when s2 runs, so the combined transaction blocks if both retry."; }
        action oe : OrElse;
        #FpNodePresentation { role = "type"; tooltip = "STM a — result of whichever branch commits.  Never blocks unless both branches retry."; }
        item sr : "STM a";

        flow from s1 to oe;
        flow from s2 to oe;
        flow from oe to sr : "run s1; on retry, run s2";
    }
    #FpViewPresentation { name = "orElse"; }
    view diagram : FpActivityView {
        doc /*orElse :: STM a ⟶ STM a ⟶ STM a   (try s1; on retry, fall back to s2) — primitive*/
        expose STMOrElseProcess;
        render fpActivityDiagram;
    }
}

