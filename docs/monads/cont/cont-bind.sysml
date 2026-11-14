// SysML v2 — Cont bind: implementation activity
// bind m f = \k -> m (\a -> f a k)
//
// The "current step runs last" inversion:
//   1. Build a new inner continuation k2 = \a -> f(a)(k)  (captures f and k in a closure)
//   2. Give k2 to m — m runs with k2 as its downstream continuation
//
// m is NOT run first — it is given a prepared continuation and will call it when ready.
// callCC exploits this to capture k as an escape function.

package ContBindImpl {
    private import FpDiagram::*;

    action def BuildInnerK {
        in  f   : "a ⟶ Cont r b";
        in  k   : "b ⟶ r";          // downstream continuation (what happens after b)
        out k2  : "a ⟶ r";          // inner continuation: \a -> f(a)(k)
    }

    action def RunM {
        in  m   : "Cont r a";        // = (a ⟶ r) ⟶ r — waiting for its continuation
        in  k2  : "a ⟶ r";          // the inner continuation we built
        out r   : r;                 // the final result
    }

    action def ContBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "Cont r a = (a ⟶ r) ⟶ r — m is waiting for its continuation. It does not run yet."; }
        item m   : "Cont r a";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Cont r b) — the continuation step; given a, produces a Cont r b action"; }
        item f   : "a ⟶ Cont r b";
        #FpNodePresentation { role = "value"; tooltip = "(b ⟶ r) — the downstream continuation: what happens after b is produced"; }
        item k   : "b ⟶ r";         // the downstream continuation (final consumer)
        #FpNodePresentation { role = "function"; tooltip = "Build inner continuation k2 = \\a -> f(a)(k)\nThis closure captures both f and k.\nWhen called with a, it: runs f(a) to get Cont r b, then runs that with k."; }
        action compose : BuildInnerK;  // build \a -> f(a)(k)
        #FpNodePresentation { role = "value"; tooltip = "(a ⟶ r) — the composed continuation. When m eventually produces a, it calls k2(a), which runs f(a) and then k."; }
        item k2  : "a ⟶ r";         // composed inner continuation
        #FpNodePresentation { role = "function"; tooltip = "Run m with k2: m(k2). m runs LAST — this is the inversion of control.\nIf callCC is used, k (the downstream continuation) can be captured as an escape function."; }
        action run : RunM;             // give k2 to m; m runs LAST
        #FpNodePresentation { role = "type"; tooltip = "r — the final result of the entire composed computation"; }
        item r   : r;

        flow from f to compose;
        flow from k to compose;        // k is captured in the closure
        flow from compose to k2;
        flow from m  to run;
        flow from k2 to run;           // m is given the composed continuation
        flow from run to r;

        succession compose then run;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*Cont bind: build inner continuation k2 = (a → f(a)(k)), give k2 to m — also called: >>=*/
        expose ContBindProcess;
        render fpActivityDiagram;
    }
}

