// SysML v2 — Prob bind: implementation activity (law of total probability)
// For each outcome (a, pa) in the distribution, apply f to get a sub-distribution,
// then weight each (b, pb) by pa. Collect all weighted outcomes into Prob b.
// This is P(B=b) = Σ_a P(B=b | A=a) · P(A=a) — Bayes / law of total probability.

package ProbBindImpl {

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

    activity def ProbBindProcess {
        object dist_a  : "Prob a";
        object f       : "a ⟶ Prob b";
        // two representative branches (pattern repeats ∀ a in dist_a)
        object a1      : a;
        object pa1     : Double;        // P(A = a1)
        object a2      : a;
        object pa2     : Double;        // P(A = a2)
        action branch1 : ApplyBranch;
        action branch2 : ApplyBranch;
        object sub1    : "Prob b";
        object sub2    : "Prob b";
        action weight1 : WeightBranch;
        action weight2 : WeightBranch;
        object w1      : "[(b, pa1·pb)]";
        object w2      : "[(b, pa2·pb)]";
        action merge   : Merge;
        object dist_b  : "Prob b";

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
}

#diagram {
    type  = activity
    title = "Prob bind: apply f per outcome, weight by pa, merge — law of total probability — also called: flatMap, SelectMany, >>="
    name  = "bind"
    show dist_a  as type
    show f       as hof
    show a1      as value
    show pa1     as value
    show a2      as value
    show pa2     as value
    show branch1 as function
    show branch2 as function
    show sub1    as type
    show sub2    as type
    show weight1 as function
    show weight2 as function
    show w1      as value
    show w2      as value
    show merge   as function
    show dist_b  as type
    tooltip dist_a  = "Prob a = [(a, p)] — each (a, pa) is an outcome with probability pa. Repeats for every element (∀ a)."
    tooltip f       = "(a ⟶ Prob b) — conditional distribution: given each outcome a, returns a distribution over b"
    tooltip a1      = "Outcome a1 from Prob a"
    tooltip pa1     = "P(A = a1) — probability of outcome a1"
    tooltip a2      = "Outcome a2 from Prob a"
    tooltip pa2     = "P(A = a2) — probability of outcome a2"
    tooltip branch1 = "Apply f(a1): get the conditional distribution Prob b given A = a1"
    tooltip branch2 = "Apply f(a2): get the conditional distribution Prob b given A = a2"
    tooltip sub1    = "Prob b — conditional distribution for branch a1"
    tooltip sub2    = "Prob b — conditional distribution for branch a2"
    tooltip weight1 = "Scale: each (b, pb) in sub1 gets weight pa1 * pb — P(B=b | A=a1) * P(A=a1)"
    tooltip weight2 = "Scale: each (b, pb) in sub2 gets weight pa2 * pb — P(B=b | A=a2) * P(A=a2)"
    tooltip w1      = "[(b, pa1·pb)] — weighted outcomes for branch a1"
    tooltip w2      = "[(b, pa2·pb)] — weighted outcomes for branch a2"
    tooltip merge   = "Concatenate: w1 ++ w2 (and repeat for all other branches). Result is the marginal distribution P(B)."
    tooltip dist_b  = "Prob b — the marginal distribution: P(B=b) = Σ_a P(B=b|A=a)·P(A=a)"
}
