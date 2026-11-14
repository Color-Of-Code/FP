// SysML v2 — Prob monad IBD: what happens inside bind
// (>>=) :: Prob a ⟶ (a ⟶ Prob b) ⟶ Prob b      m >>= f = join (fmap f m)
//
// Prob a = [(a, Double)] — a discrete probability distribution.
//   • fmap applies f to every outcome, giving a distribution OVER distributions
//   • join flattens it by the law of total probability:
//     P(B=b) = sum over a of P(B=b | A=a) * P(A=a)

package ProbSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Prob a = [(a, p)] — each possible outcome a paired with its probability p. Probabilities sum to 1."; }
        port in  ma : "Prob a";
        #FpNodePresentation { tooltip = "f : a ⟶ Prob b — user code; conditional distribution: given outcome a, returns a distribution over b"; }
        port in  f  : "a ⟶ Prob b";
        #FpNodePresentation { tooltip = "Prob b — the marginal distribution over b, weighting each branch by the probability of reaching it; never Prob (Prob b)"; }
        port out mb : "Prob b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: Prob a ⟶ Prob (Prob b)\n[(a, pa)]  →  [(f a, pa)]\nEach outcome a keeps its probability pa and is replaced by the distribution f a."; }
        part fmap : "Prob a ⟶ Prob (Prob b)" {
            port in  f : "a ⟶ Prob b";
            port in  _ : "Prob a";
            port out _ : "Prob (Prob b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: Prob (Prob b) ⟶ Prob b — the Prob-specific part\n[(b, pa*pb) | (dist, pa) <- outer, (b, pb) <- dist]\nEach inner outcome is weighted by the probability of its branch — law of total probability."; }
        part join : "Prob (Prob b) ⟶ Prob b" {
            port in  _ : "Prob (Prob b)";
            port out _ : "Prob b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Prob a ⟶ (a ⟶ Prob b) ⟶ Prob b — inside bind: fmap f, then join weights and merges branches — also called: flatMap, SelectMany, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
