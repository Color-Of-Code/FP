// SysML v2 — Writer monad IBD: what happens inside bind
// (>>=) :: (a, w1) ⟶ (a ⟶ (b, w2)) ⟶ (b, w1<>w2)      m >>= f = join (fmap f m)
//
// Same fmap → join shape as every monad — only the join differs:
//   • fmap applies f to the value and keeps the outer log w1: ((b, w2), w1)
//   • join merges the two logs with the monoid append (<>)

package WriterSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "(a, w1) — a result value a paired with a log fragment w1"; }
        port in  ma : "(a, w1)";
        #FpNodePresentation { tooltip = "f : a ⟶ (b, w2) — user code; given a, produces result b alongside a new log fragment w2"; }
        port in  f  : "a ⟶ (b, w2)";
        #FpNodePresentation { tooltip = "(b, w1<>w2) — result b with the complete log: w1 from the first step appended with w2 from f"; }
        port out mb : "(b, w1<>w2)";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: (a, w1) ⟶ ((b, w2), w1)\nApplies f to the value; the outer log w1 stays where it is, the new log w2 sits inside."; }
        part fmap : "(a, w1) ⟶ ((b, w2), w1)" {
            port in  f : "a ⟶ (b, w2)";
            port in  _ : "(a, w1)";
            port out _ : "((b, w2), w1)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: ((b, w2), w1) ⟶ (b, w1<>w2) — the Writer-specific part\nMerges the outer and inner log with the monoid append, in execution order: w1 first, then w2."; }
        part join : "((b, w2), w1) ⟶ (b, w1<>w2)" {
            port in  _ : "((b, w2), w1)";
            port out _ : "(b, w1<>w2)";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: (a, w1) ⟶ (a ⟶ (b, w2)) ⟶ (b, w1<>w2) — inside bind: fmap f, then join appends the logs — also called: flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
