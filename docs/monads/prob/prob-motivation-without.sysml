// SysML v2 — Prob motivation: WITHOUT the Prob monad (bind)
//
// Joint distribution computed by hand: outer loop over the coin
// distribution, inner loop over the conditional die distribution,
// multiply probabilities, then flatten the nested list.  Probability
// arithmetic is manual; an off-by-one in the multiplication produces
// a result that still LOOKS like a distribution but doesn't sum to 1.

package ProbMotivationWithout {
    private import FpDiagram::*;

    action def OuterLoop {
        in  coin : "Prob CoinFace";
        out _    : "(CoinFace, p_coin)";
    }

    action def Multiply {
        in  pCoin  : "Float";
        in  pScore : "Float";
        out _      : "Float";
    }

    action def Flatten {
        in  nested : "[[ (Int, Float) ]]";
        out _      : "[(Int, Float)]";
    }

    action def CoinThenDieWithout {
        // input
        #FpNodePresentation { role = "type"; tooltip = "Prob CoinFace — the coin distribution as a list of (face, probability) pairs."; }
        item coin : "Prob CoinFace";

        // manual outer loop, manual multiply, manual flatten
        #FpNodePresentation { role = "function"; tooltip = "for (face, p_coin) in coin — opens an outer loop; the inner loop over the die's conditional distribution is implied inside multiply."; }
        action outer    : OuterLoop;
        #FpNodePresentation { role = "function"; tooltip = "p_coin * p_score — multiply marginal × conditional by hand. Off-by-one here is invisible until totals don't sum to one."; }
        action multiply : Multiply;
        #FpNodePresentation { role = "function"; tooltip = "Flatten the nested [[ (Int, Float) ]] back into a single distribution."; }
        action flatten  : Flatten;

        // output
        #FpNodePresentation { role = "type"; tooltip = "[(Int, Float)] — the joint distribution, hand-built."; }
        item outResult : "[(Int, Float)]";

        flow from coin     to outer;
        flow from outer    to multiply : "for (face, p_coin)";
        flow from multiply to flatten  : "p_coin * p_score";
        flow from flatten  to outResult;
    }
    #FpViewPresentation { name = "coinThenDie"; }
    view diagram : FpActivityView {
        doc /*Without bind: manual nested loop and probability arithmetic*/
        expose CoinThenDieWithout;
        render fpActivityDiagram;
    }
}

