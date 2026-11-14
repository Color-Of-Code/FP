// SysML v2 — Prob monad IBD: type signature + bind contract
// (>>=) :: Prob a ⟶ (a ⟶ Prob b) ⟶ Prob b
//
// Prob a = [(a, Double)] — a discrete probability distribution.
// bind implements conditional probability (law of total probability):
// P(B=b) = sum over a of P(B=b | A=a) * P(A=a)
// The output distribution is the weighted cartesian product of input and f(a).

package ProbSignature {
    private import FpDiagram::*;

    part def ProbBindContext {
        #FpNodePresentation { role = "type"; tooltip = "Prob a = [(a, p)] — each possible outcome a paired with its probability p. Probabilities sum to 1."; }
        part dist_a : "Prob a";        // [(a, p_a)] — distribution over a
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Prob b) — conditional distribution: given outcome a, returns a new distribution over b"; }
        part f_val  : "a ⟶ Prob b";  // conditional distribution (HOF)
        #FpNodePresentation { role = "function"; tooltip = "[(b, pa*pb) | (a, pa) <- dist, (b, pb) <- f a]\nFor each outcome a (probability pa), apply f to get a distribution over b.\nEach (b, pb) gets weight pa * pb — law of total probability."; }
        part bind   : ProbBindOp;
        #FpNodePresentation { role = "type"; tooltip = "Prob b — the marginal distribution over b, weighting each branch by the probability of reaching it"; }
        part dist_b : "Prob b";        // [(b, p_a*p_b)] — joint distribution over b

        connection connect dist_a to bind;
        connection connect f_val  to bind;
        connection connect bind   to dist_b;
    }
    view diagram : FpIbdView {
        doc /*bind :: Prob a ⟶ (a ⟶ Prob b) ⟶ Prob b — also called: flatMap, SelectMany, >>=*/
        expose ProbBindContext;
        render fpIbdDiagram;
    }
}

