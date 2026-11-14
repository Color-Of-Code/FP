// SysML v2 — Prob monad IBD: inside bind
// (>>=) :: Prob a ⟶ (a ⟶ Prob b) ⟶ Prob b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. Like List, but every branch carries
// a weight:
//   • each outcome a (probability pa) is fed to f; pa bypasses f
//   • f returns a distribution over b; its probabilities are scaled by pa
//   • all scaled branches are merged — the law of total probability
//     P(B=b) = sum over a of P(B=b | A=a) * P(A=a)

package ProbSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Prob a = [(a, p)] — each possible outcome a paired with its probability p. Probabilities sum to 1."; }
        port in  ma : "Prob a";
        #FpNodePresentation { tooltip = "f : a ⟶ Prob b — user code; conditional distribution: given outcome a, a distribution over b"; }
        port in  f  : "a ⟶ Prob b";
        #FpNodePresentation { tooltip = "Prob b — the marginal distribution over b"; }
        port out mb : "Prob b";

        #FpNodePresentation { role = "function"; tooltip = "Fan-out over the outcomes: each (a, pa) is emitted separately; the probability pa is kept apart from the value."; }
        part outcomes : "(a, pa) in ma" {
            port in  _  : "Prob a";
            port out a  : "a";
            port out pa : "pa";
        }
        #FpNodePresentation { role = "function"; tooltip = "Applied once per outcome; returns the conditional distribution P(B | A=a)."; }
        part call : "f a" {
            port in  f : "a ⟶ Prob b";
            port in  a : "a";
            port out _ : "Prob b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Multiply every probability pb in f a by pa: each (b, pb) becomes (b, pa*pb)."; }
        part weight : "scale by pa" {
            port in  d  : "Prob b";
            port in  pa : "pa";
            port out _  : "Prob b";
        }
        #FpNodePresentation { role = "function"; tooltip = "The Prob-specific join: concatenate all weighted branches and add the weights of equal outcomes b."; }
        part merge_branches : "concat, add equal b" {
            port in  _ : "Prob b";
            port out _ : "Prob b";
        }

        connection connect ma          to outcomes._ : "wrapped";
        connection connect f           to call.f : "user code";
        connection connect outcomes.a  to call.a : "once per outcome";
        connection connect call._      to weight.d : "P(B | A=a)";
        connection connect outcomes.pa to weight.pa : "pa bypasses f";
        connection connect weight._    to merge_branches._ : "weighted branch";
        connection connect merge_branches._ to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Prob a ⟶ (a ⟶ Prob b) ⟶ Prob b — inside bind: each outcome is fed to f, its branch is scaled by pa, and all branches are merged — also called: flatMap, SelectMany, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
