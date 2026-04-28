// SysML v2 — List monad IBD: type signature + bind contract
// (>>=) :: List a ⟶ (a ⟶ List b) ⟶ List b
//
// Structurally identical to Maybe/Either — but bind does something fundamentally
// different: it applies f to EVERY element and flattens all results (concatMap).

package ListSignature {

    part def ListBindContext {
        part ma_val : "List a";        // zero or more values of type a
        part f_val  : "a ⟶ List b";  // effectful function (HOF) — may branch
        part bind   : ListBindOp;
        part mb_val : "List b";        // all branches flattened into one list

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
}

#diagram {
    type  = ibd
    title = "bind :: List a ⟶ (a ⟶ List b) ⟶ List b — also called: flatMap, concatMap, SelectMany, List.collect, >>="
    render = ListBindContext
    show ma_val as type
    show f_val  as hof
    show bind   as function
    show mb_val as type
    tooltip ma_val = "List a — zero or more possible values. An empty list short-circuits (no elements to process)."
    tooltip f_val  = "(a ⟶ List b) — applied to EVERY element; each call may return zero, one, or many results"
    tooltip bind   = "concatMap f: apply f to each element, concatenate all resulting lists.\nbind [a1,a2,a3] f  =  f(a1) ++ f(a2) ++ f(a3)"
    tooltip mb_val = "List b — all branches expanded and flattened into a single list"
}
