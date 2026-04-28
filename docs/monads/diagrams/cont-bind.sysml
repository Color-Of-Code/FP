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

    activity def ContBindProcess {
        object m   : "Cont r a";
        object f   : "a ⟶ Cont r b";
        object k   : "b ⟶ r";         // the downstream continuation (final consumer)
        action compose : BuildInnerK;  // build \a -> f(a)(k)
        object k2  : "a ⟶ r";         // composed inner continuation
        action run : RunM;             // give k2 to m; m runs LAST
        object r   : r;

        flow from f to compose;
        flow from k to compose;        // k is captured in the closure
        flow from compose to k2;
        flow from m  to run;
        flow from k2 to run;           // m is given the composed continuation
        flow from run to r;

        succession compose then run;
    }
}

#diagram {
    type  = activity
    title = "Cont bind: build inner continuation k2 = (a → f(a)(k)), give k2 to m — also called: >>="
    name  = "bind"
    show m       as type
    show f       as hof
    show k       as value
    show compose as function
    show k2      as value
    show run     as function
    show r       as type
    tooltip m       = "Cont r a = (a ⟶ r) ⟶ r — m is waiting for its continuation. It does not run yet."
    tooltip f       = "(a ⟶ Cont r b) — the continuation step; given a, produces a Cont r b action"
    tooltip k       = "(b ⟶ r) — the downstream continuation: what happens after b is produced"
    tooltip compose = "Build inner continuation k2 = \\a -> f(a)(k)\nThis closure captures both f and k.\nWhen called with a, it: runs f(a) to get Cont r b, then runs that with k."
    tooltip k2      = "(a ⟶ r) — the composed continuation. When m eventually produces a, it calls k2(a), which runs f(a) and then k."
    tooltip run     = "Run m with k2: m(k2). m runs LAST — this is the inversion of control.\nIf callCC is used, k (the downstream continuation) can be captured as an escape function."
    tooltip r       = "r — the final result of the entire composed computation"
}
