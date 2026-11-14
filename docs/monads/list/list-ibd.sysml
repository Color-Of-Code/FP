// SysML v2 — List monad IBD: inside bind
// (>>=) :: List a ⟶ (a ⟶ List b) ⟶ List b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. Here fmap and join are fused into
// what List actually does — a fan-out, then a fan-in:
//   • each element a_i of the input list is fed to f separately (0, 1 or n calls)
//   • every call returns a whole List b; concat joins them, in order, into one list
// Contrast Maybe, where f is called at most once.

package ListSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "List a — zero or more possible values. An empty list means f is never called."; }
        port in  ma : "List a";
        #FpNodePresentation { tooltip = "f : a ⟶ List b — user code; each call may return zero, one, or many results"; }
        port in  f  : "a ⟶ List b";
        #FpNodePresentation { tooltip = "List b — all branches expanded and flattened into a single list"; }
        port out mb : "List b";

        #FpNodePresentation { role = "function"; tooltip = "Fan-out: emits the elements one at a time. [a1, a2, a3] produces three separate a tokens; [] produces none."; }
        part each : "elements of ma" {
            port in  _   : "List a";
            port out a_i : "a";
        }
        #FpNodePresentation { role = "function"; tooltip = "Applied once per element: f(a1), f(a2), f(a3), …\nEach call returns its own List b."; }
        part call : "f a_i" {
            port in  f : "a ⟶ List b";
            port in  a : "a";
            port out _ : "List b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Fan-in: f(a1) ++ f(a2) ++ f(a3) — the per-element lists are concatenated in order. This is the List-specific join."; }
        part flatten : "concat" {
            port in  _ : "List b";
            port out _ : "List b";
        }

        connection connect ma       to each._ : "wrapped";
        connection connect f        to call.f : "user code";
        connection connect each.a_i to call.a : "once per element";
        connection connect call._   to flatten._ : "a List b per element";
        connection connect flatten._ to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: List a ⟶ (a ⟶ List b) ⟶ List b — inside bind: f is applied to every element and the resulting lists are concatenated — also called: flatMap, concatMap, SelectMany, List.collect, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
