// SysML v2 — Prob bind: implementation activity (law of total probability)
// For each outcome (a, pa) in the distribution, apply f to get a sub-distribution,
// then weight each (b, pb) by pa. Collect all weighted outcomes into Prob b.
// This is P(B=b) = Σ_a P(B=b | A=a) · P(A=a) — Bayes / law of total probability.

package ProbBindImpl {
    private import FpDiagram::*;

    action def ApplyBranch {
        in  a_val  : a;
        in  pa     : Double;          // probability of this a outcome
        in  f      : "a ⟶ Prob b";
        out sub_b  : "Prob b";        // conditional distribution for this branch
    }

    action def WeightBranch {
        in  sub_b    : "Prob b";
        in  pa       : Double;
        out weighted : "[(b, pa·pb)]"; // each (b, pb) scaled by pa
    }

    action def Merge {
        in  w1     : "[(b, pa·pb)]";
        in  w2     : "[(b, pa·pb)]";
        out dist_b : "Prob b";         // marginal distribution over b
    }

    action def ProbBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "Prob a = [(a, p)] — each (a, pa) is an outcome with probability pa. Repeats for every element (∀ a)."; }
        item dist_a  : "Prob a";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Prob b) — conditional distribution: given each outcome a, returns a distribution over b"; }
        item f       : "a ⟶ Prob b";
        // two representative branches (pattern repeats ∀ a in dist_a)
        #FpNodePresentation { role = "value"; tooltip = "Outcome a1 from Prob a"; }
        item a1      : a;
        #FpNodePresentation { role = "value"; tooltip = "P(A = a1) — probability of outcome a1"; }
        item pa1     : Double;        // P(A = a1)
        #FpNodePresentation { role = "value"; tooltip = "Outcome a2 from Prob a"; }
        item a2      : a;
        #FpNodePresentation { role = "value"; tooltip = "P(A = a2) — probability of outcome a2"; }
        item pa2     : Double;        // P(A = a2)
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a1): get the conditional distribution Prob b given A = a1"; }
        action branch1 : ApplyBranch;
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a2): get the conditional distribution Prob b given A = a2"; }
        action branch2 : ApplyBranch;
        #FpNodePresentation { role = "type"; tooltip = "Prob b — conditional distribution for branch a1"; }
        item sub1    : "Prob b";
        #FpNodePresentation { role = "type"; tooltip = "Prob b — conditional distribution for branch a2"; }
        item sub2    : "Prob b";
        #FpNodePresentation { role = "function"; tooltip = "Scale: each (b, pb) in sub1 gets weight pa1 * pb — P(B=b | A=a1) * P(A=a1)"; }
        action weight1 : WeightBranch;
        #FpNodePresentation { role = "function"; tooltip = "Scale: each (b, pb) in sub2 gets weight pa2 * pb — P(B=b | A=a2) * P(A=a2)"; }
        action weight2 : WeightBranch;
        #FpNodePresentation { role = "value"; tooltip = "[(b, pa1·pb)] — weighted outcomes for branch a1"; }
        item w1      : "[(b, pa1·pb)]";
        #FpNodePresentation { role = "value"; tooltip = "[(b, pa2·pb)] — weighted outcomes for branch a2"; }
        item w2      : "[(b, pa2·pb)]";
        #FpNodePresentation { role = "function"; tooltip = "Concatenate: w1 ++ w2 (and repeat for all other branches). Result is the marginal distribution P(B)."; }
        action merge   : Merge;
        #FpNodePresentation { role = "type"; tooltip = "Prob b — the marginal distribution: P(B=b) = Σ_a P(B=b|A=a)·P(A=a)"; }
        item dist_b  : "Prob b";

        flow from dist_a to a1  : "∀ a";
        flow from dist_a to pa1 : "∀ a";
        flow from dist_a to a2  : "∀ a";
        flow from dist_a to pa2 : "∀ a";

        flow from a1  to branch1;
        flow from pa1 to branch1;
        flow from f   to branch1;
        flow from branch1 to sub1;
        flow from sub1 to weight1;
        flow from pa1  to weight1;
        flow from weight1 to w1;

        flow from a2  to branch2;
        flow from pa2 to branch2;
        flow from f   to branch2;
        flow from branch2 to sub2;
        flow from sub2 to weight2;
        flow from pa2  to weight2;
        flow from weight2 to w2;

        flow from w1 to merge;
        flow from w2 to merge;
        flow from merge to dist_b;

        succession branch1 then weight1;
        succession branch2 then weight2;
        succession weight1 then merge;
        succession weight2 then merge;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*Prob bind: apply f per outcome, weight by pa, merge — law of total probability — also called: flatMap, SelectMany, >>=*/
        expose ProbBindProcess;
        render fpActivityDiagram;
    }
}

