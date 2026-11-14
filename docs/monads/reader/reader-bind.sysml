// SysML v2 — Reader bind: implementation activity
// Key insight: the SAME environment r flows into BOTH ra(r) and f(a)(r).
// r is never modified — every step sees the identical environment.
// Contrast with State, where s is transformed at each step.

package ReaderBindImpl {
    private import FpDiagram::*;

    action def RunRA {
        in  ra  : "Reader r a";  // r ⟶ a
        in  env : r;
        out a   : a;
    }

    action def ApplyF {
        in  a   : a;
        in  f   : "a ⟶ Reader r b";
        out rb  : "Reader r b";  // r ⟶ b
    }

    action def RunRB {
        in  rb  : "Reader r b";  // r ⟶ b
        in  env : r;             // THE SAME env as step 1
        out b   : b;
    }

    action def ReaderBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "Reader r a — a suspended computation: a function r ⟶ a, not yet executed"; }
        item ra     : "Reader r a";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Reader r b) — given result a, builds the next computation r ⟶ b"; }
        item f      : "a ⟶ Reader r b";
        #FpNodePresentation { role = "value"; tooltip = "r — the shared read-only environment. The SAME instance flows to both run_ra and run_rb. It is NEVER modified."; }
        item env    : r;              // shared read-only environment
        #FpNodePresentation { role = "function"; tooltip = "Run ra(env): supply env to ra, get result a"; }
        action run_ra  : RunRA;
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a): build the next computation Reader r b from result a"; }
        action apply_f : ApplyF;
        #FpNodePresentation { role = "type"; tooltip = "Reader r b — the second computation (not yet run)"; }
        item rb      : "Reader r b";
        #FpNodePresentation { role = "function"; tooltip = "Run rb(env): supply THE SAME env to f(a) — env is unchanged from step 1. Key difference from State."; }
        action run_rb  : RunRB;
        #FpNodePresentation { role = "value"; tooltip = "b — the final result. The environment was never modified throughout."; }
        item b       : b;

        flow from ra    to run_ra;
        flow from env   to run_ra;          // env supplied to first step
        flow from run_ra to apply_f : "a";
        flow from f     to apply_f;
        flow from apply_f to rb;
        flow from rb    to run_rb;
        flow from env   to run_rb;          // SAME env supplied to second step — unmodified
        flow from run_rb to b;

        succession run_ra then apply_f;
        succession apply_f then run_rb;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*Reader bind: same env r supplied to ra(r) and to f(a)(r) — never modified — also called: flatMap, >>=*/
        expose ReaderBindProcess;
        render fpActivityDiagram;
    }
}

