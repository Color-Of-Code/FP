// SysML v2 — List monad: bind (abstract multiplicity)
// Expresses ∀ a processing without enumerating N concrete steps.

package ListMonadExample {

    action def ListBindOp {
        in  la : "List a";          // List a — each element processed abstractly
        in  f  : "a ⟶ List b";  // effectful fn, HOF input
        out lb : "List b";
    }

    activity def ListBindProcess {
        object La   : "List a";         // input list — [0..*] elements of type a
        object f    : "a ⟶ List b";  // effectful fn applied to every element
        action bind : ListBindOp;
        object Lb   : "List b";         // flat result — all sublists concatenated

        flow from La   to bind : "∀ a";   // each element flows into bind abstractly
        flow from f    to bind;
        flow from bind to Lb   : "[0..*]"; // produces zero or more b per element
    }
}

#diagram {
    type   = activity
    title  = "List Monad: bind :: List a ⟶ (a ⟶ List b) ⟶ List b"
    name   = "bind"
    show La   as type
    show f    as hof
    show bind as function
    show Lb   as type
    tooltip La   = "List a — each element processed by f (∀ a)"
    tooltip f    = "(a ⟶ List b) — applied to every element, producing a list per element"
    tooltip bind = ">>= (concatMap): apply f to every element, flatten all resulting lists"
    tooltip Lb   = "List b — the concatenation of all result lists [0..*]"
}
