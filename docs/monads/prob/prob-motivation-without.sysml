// SysML v2 — Prob motivation: WITHOUT the Prob monad
//
// Joint distribution computed by hand: outer loop over the coin
// distribution, inner loop over the conditional die distribution,
// multiply probabilities, then flatten the nested list.  Probability
// arithmetic is manual; an off-by-one in the multiplication produces
// a result that still looks like a distribution.

package ProbMotivationWithout {

    action def OuterLoop {
        in  coin : "Prob CoinFace";
        out face : "(CoinFace, p_coin)";
    }

    action def Multiply {
        in  pCoin  : "Float";
        in  pScore : "Float";
        out joint  : "Float";
    }

    action def Flatten {
        in  nested : "[[ (Int, Float) ]]";
        out flat   : "[(Int, Float)]";
    }

    activity def CoinThenDieWithout {
        object coin : "Prob CoinFace";

        action outer    : OuterLoop;
        action multiply : Multiply;
        action flatten  : Flatten;

        object outResult : "[(Int, Float)]";

        flow from coin     to outer;
        flow from outer    to multiply : "for (face, p_coin)";
        flow from multiply to flatten  : "p_coin * p_score";
        flow from flatten  to outResult;
    }
}

#diagram {
    type  = activity
    title = "Without Prob: manual nested loop and probability arithmetic"
    name  = "coinThenDie"
    show coin     as type
    show outer    as function
    show multiply as function
    show flatten  as function
    show outResult      as type
    tooltip coin     = "Prob CoinFace — the coin distribution as a list of (face, probability) pairs."
    tooltip outer    = "for (face, p_coin) in coin — opens an outer loop; the inner loop over the die's conditional distribution is implied inside multiply."
    tooltip multiply = "p_coin * p_score — multiply marginal × conditional by hand.  Off-by-one here is invisible until totals don't sum to one."
    tooltip flatten  = "Flatten the nested [[ (Int, Float) ]] back into a single distribution."
    tooltip outResult      = "[(Int, Float)] — the joint distribution, hand-built."
}
