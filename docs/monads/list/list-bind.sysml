// SysML v2 — List bind: implementation activity (concatMap)
// Shows f applied to EACH element individually, then all results flattened into one list.
// Three concrete elements (a1, a2, a3) make the "every element" contract visible.

package ListBindImpl {

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

    activity def ListBindProcess {
        object la    : "List a";          // input: all elements
        object f     : "a ⟶ List b";
        object a1    : a;                 // element 1
        object a2    : a;                 // element 2
        object a3    : a;                 // element 3
        action app1  : ApplyToElem;
        action app2  : ApplyToElem;
        action app3  : ApplyToElem;
        object sub1  : "List b";          // results for a1
        object sub2  : "List b";          // results for a2
        object sub3  : "List b";          // results for a3
        action flatten : Flatten;
        object lb    : "List b";          // flattened output

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
}

#diagram {
    type  = activity
    title = "List bind (concatMap): apply f to every element, concatenate all results — also called: flatMap, SelectMany, List.collect, >>="
    name  = "bind"
    show la      as type
    show f       as hof
    show a1      as value
    show a2      as value
    show a3      as value
    show app1    as function
    show app2    as function
    show app3    as function
    show sub1    as type
    show sub2    as type
    show sub3    as type
    show flatten as function
    show lb      as type
    tooltip la      = "List a — every element is independently processed. Empty list short-circuits: no elements, no calls."
    tooltip f       = "(a ⟶ List b) — called for EVERY element. Each call may return [], [b], or [b1, b2, ...] — any size."
    tooltip a1      = "First element of List a"
    tooltip a2      = "Second element of List a"
    tooltip a3      = "Third element of List a"
    tooltip app1    = "f(a1) — sub-list of b values for the first element (0 or more results)"
    tooltip app2    = "f(a2) — sub-list of b values for the second element (0 or more results)"
    tooltip app3    = "f(a3) — sub-list of b values for the third element (0 or more results)"
    tooltip sub1    = "List b — all b values produced for a1. May be empty."
    tooltip sub2    = "List b — all b values produced for a2. May be empty."
    tooltip sub3    = "List b — all b values produced for a3. May be empty."
    tooltip flatten = "Concatenate: sub1 ++ sub2 ++ sub3. This is the key step: all branches merged into one flat List b."
    tooltip lb      = "List b — the complete output: sub1 ++ sub2 ++ sub3. Non-determinism is preserved as multiple values."
}
