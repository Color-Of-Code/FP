// SysML v2 — List bind: implementation activity (concatMap)
// Shows f applied to EACH element individually, then all results flattened into one list.
// Three concrete elements (a1, a2, a3) make the "every element" contract visible.

package ListBindImpl {
    private import FpDiagram::*;

    action def ApplyToElem {
        in  a_val : a;
        in  f     : "a ⟶ List b";
        out sub_b : "List b";  // per-element sub-list (may be empty, one, or many)
    }

    action def Flatten {
        in  sub1  : "List b";
        in  sub2  : "List b";
        in  sub3  : "List b";
        out flat  : "List b";  // all sub-lists concatenated
    }

    action def ListBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "List a — every element is independently processed. Empty list short-circuits: no elements, no calls."; }
        item la    : "List a";          // input: all elements
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ List b) — called for EVERY element. Each call may return [], [b], or [b1, b2, ...] — any size."; }
        item f     : "a ⟶ List b";
        #FpNodePresentation { role = "value"; tooltip = "First element of List a"; }
        item a1    : a;                 // element 1
        #FpNodePresentation { role = "value"; tooltip = "Second element of List a"; }
        item a2    : a;                 // element 2
        #FpNodePresentation { role = "value"; tooltip = "Third element of List a"; }
        item a3    : a;                 // element 3
        #FpNodePresentation { role = "function"; tooltip = "f(a1) — sub-list of b values for the first element (0 or more results)"; }
        action app1  : ApplyToElem;
        #FpNodePresentation { role = "function"; tooltip = "f(a2) — sub-list of b values for the second element (0 or more results)"; }
        action app2  : ApplyToElem;
        #FpNodePresentation { role = "function"; tooltip = "f(a3) — sub-list of b values for the third element (0 or more results)"; }
        action app3  : ApplyToElem;
        #FpNodePresentation { role = "type"; tooltip = "List b — all b values produced for a1. May be empty."; }
        item sub1  : "List b";          // results for a1
        #FpNodePresentation { role = "type"; tooltip = "List b — all b values produced for a2. May be empty."; }
        item sub2  : "List b";          // results for a2
        #FpNodePresentation { role = "type"; tooltip = "List b — all b values produced for a3. May be empty."; }
        item sub3  : "List b";          // results for a3
        #FpNodePresentation { role = "function"; tooltip = "Concatenate: sub1 ++ sub2 ++ sub3. This is the key step: all branches merged into one flat List b."; }
        action flatten : Flatten;
        #FpNodePresentation { role = "type"; tooltip = "List b — the complete output: sub1 ++ sub2 ++ sub3. Non-determinism is preserved as multiple values."; }
        item lb    : "List b";          // flattened output

        flow from la to a1 : "∀ a";
        flow from la to a2 : "∀ a";
        flow from la to a3 : "∀ a";

        flow from a1  to app1;
        flow from f   to app1;
        flow from app1 to sub1;

        flow from a2  to app2;
        flow from f   to app2;
        flow from app2 to sub2;

        flow from a3  to app3;
        flow from f   to app3;
        flow from app3 to sub3;

        flow from sub1 to flatten;
        flow from sub2 to flatten;
        flow from sub3 to flatten;
        flow from flatten to lb;

        succession app1 then app2;
        succession app2 then app3;
        succession app3 then flatten;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*List bind (concatMap): apply f to every element, concatenate all results — also called: flatMap, SelectMany, List.collect, >>=*/
        expose ListBindProcess;
        render fpActivityDiagram;
    }
}

