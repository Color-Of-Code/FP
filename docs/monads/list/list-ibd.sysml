// SysML v2 — List monad IBD: what happens inside bind
// (>>=) :: List a ⟶ (a ⟶ List b) ⟶ List b      m >>= f = join (fmap f m)
//
// Same fmap → join shape as every monad — only the join differs:
//   • fmap applies f to EVERY element, giving a list of lists
//   • join (concat) flattens that list of lists into one list
// Together they are concatMap.

package ListSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "List a — zero or more possible values. An empty list short-circuits (no elements to process)."; }
        port in  ma : "List a";
        #FpNodePresentation { tooltip = "f : a ⟶ List b — user code; each call may return zero, one, or many results"; }
        port in  f  : "a ⟶ List b";
        #FpNodePresentation { tooltip = "List b — all branches expanded and flattened into a single list; never List (List b)"; }
        port out mb : "List b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: List a ⟶ List (List b)\nmap f [a1, a2, a3]  =  [f a1, f a2, f a3]\nOne inner list per element; the outer structure is kept."; }
        part fmap : "List a ⟶ List (List b)" {
            port in  f : "a ⟶ List b";
            port in  _ : "List a";
            port out _ : "List (List b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: List (List b) ⟶ List b — the List-specific part\nconcat [[b1, b2], [], [b3]]  =  [b1, b2, b3]\nInner lists are concatenated in order."; }
        part join : "List (List b) ⟶ List b" {
            port in  _ : "List (List b)";
            port out _ : "List b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: List a ⟶ (a ⟶ List b) ⟶ List b — inside bind: map f, then concat — also called: flatMap, concatMap, SelectMany, List.collect, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
