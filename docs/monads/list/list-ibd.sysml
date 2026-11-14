// SysML v2 — List monad IBD: type signature + bind contract
// (>>=) :: List a ⟶ (a ⟶ List b) ⟶ List b
//
// Structurally identical to Maybe/Either — but bind does something fundamentally
// different: it applies f to EVERY element and flattens all results (concatMap).

package ListSignature {
    private import FpDiagram::*;

    part def ListBindContext {
        #FpNodePresentation { role = "type"; tooltip = "List a — zero or more possible values. An empty list short-circuits (no elements to process)."; }
        part ma_val : "List a";        // zero or more values of type a
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ List b) — applied to EVERY element; each call may return zero, one, or many results"; }
        part f_val  : "a ⟶ List b";  // effectful function (HOF) — may branch
        #FpNodePresentation { role = "function"; tooltip = "concatMap f: apply f to each element, concatenate all resulting lists.\nbind [a1,a2,a3] f  =  f(a1) ++ f(a2) ++ f(a3)"; }
        part bind   : ListBindOp;
        #FpNodePresentation { role = "type"; tooltip = "List b — all branches expanded and flattened into a single list"; }
        part mb_val : "List b";        // all branches flattened into one list

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: List a ⟶ (a ⟶ List b) ⟶ List b — also called: flatMap, concatMap, SelectMany, List.collect, >>=*/
        expose ListBindContext;
        render fpIbdDiagram;
    }
}

