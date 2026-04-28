// SysML v2 — Reader local: implementation activity
// local :: (r ⟶ r) ⟶ Reader r a ⟶ Reader r a
//
// Run an inner reader with a transformed environment.  The transformation
// f is applied to the incoming r, and the inner reader sees only f(r).
// Outside callers still pass the original environment.

package ReaderLocalImpl {

    action def Local {
        in  f  : "r ⟶ r";
        in  ma : "Reader r a";
        out mb : "Reader r a";   // = \r -> runReader ma (f r)
    }

    activity def ReaderLocalProcess {
        object f  : "r ⟶ r";
        object ma : "Reader r a";
        action lcl : Local;
        object mb : "Reader r a";

        flow from f  to lcl;
        flow from ma to lcl;
        flow from lcl to mb : "\\r -> runReader ma (f r)";
    }
}

#diagram {
    type  = activity
    title = "local :: (r ⟶ r) ⟶ Reader r a ⟶ Reader r a   (run inner reader with modified environment) — primitive"
    name  = "local"
    show f   as value
    show ma  as value
    show lcl as function
    show mb  as type
    tooltip f   = "f : r ⟶ r — environment transformer (e.g. add a key, strip a layer, swap config)."
    tooltip ma  = "ma : Reader r a — the inner reader to be run with the transformed environment."
    tooltip lcl = "Local: build \\r -> runReader ma (f r). The outer caller still supplies the original r; only ma sees f(r)."
    tooltip mb  = "Reader r a — same outer signature, but executions of ma are scoped to the transformed environment."
}
