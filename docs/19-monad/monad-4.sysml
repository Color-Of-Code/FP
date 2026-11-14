// SysML v2 — List monad: bind (abstract multiplicity)
// Expresses ∀ a processing without enumerating N concrete steps.

package ListMonadExample {
    private import FpDiagram::*;

    action def ListBindOp {
        in  la : "List a";          // List a — each element processed abstractly
        in  f  : "a ⟶ List b";  // effectful fn, HOF input
        out lb : "List b";
    }

    action def ListBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "List a — each element processed by f (∀ a)"; }
        item La   : "List a";         // input list — [0..*] elements of type a
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ List b) — applied to every element, producing a list per element"; }
        item f    : "a ⟶ List b";  // effectful fn applied to every element
        #FpNodePresentation { role = "function"; tooltip = ">>= (concatMap): apply f to every element, flatten all resulting lists"; }
        action bind : ListBindOp;
        #FpNodePresentation { role = "type"; tooltip = "List b — the concatenation of all result lists [0..*]"; }
        item Lb   : "List b";         // flat result — all sublists concatenated

        flow from La   to bind : "∀ a";   // each element flows into bind abstractly
        flow from f    to bind;
        flow from bind to Lb   : "[0..*]"; // produces zero or more b per element
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*List Monad: bind :: List a ⟶ (a ⟶ List b) ⟶ List b*/
        expose ListBindProcess;
        render fpActivityDiagram;
    }
}

