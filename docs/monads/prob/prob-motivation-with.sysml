// SysML v2 — Prob motivation: WITH the Prob monad
//
// A Prob distribution is a list of (value, probability) pairs.  bind
// applies the next conditional distribution to each branch and
// multiplies the probabilities — the joint distribution falls out of
// the chain for free.

package ProbMotivationWith {

    action def BiasedCoin {
        out result : "Prob CoinFace";
    }

    action def RollDie {
        in  coin   : "CoinFace";
        out result : "Prob Int";
    }

    activity def CoinThenDieWith {
        action biasedCoin : BiasedCoin;
        action rollDie    : RollDie;
        object outResult        : "Prob Int";

        flow from biasedCoin to rollDie : ">>= bind";
        flow from rollDie    to outResult     : "runProb";
    }
}

#diagram {
    type  = activity
    title = "With Prob: bind multiplies probabilities and flattens the joint distribution"
    name  = "coinThenDie"
    show biasedCoin as function
    show rollDie    as function
    show outResult        as type
    tooltip biasedCoin = "biasedCoin :: Prob CoinFace — distribution over the coin outcomes."
    tooltip rollDie    = "rollDie :: CoinFace -> Prob Int — conditional distribution over die outcomes given the coin face.  bind applies this to every branch."
    tooltip outResult        = "Prob Int — the joint distribution.  bind has multiplied probabilities and flattened the nested list automatically."
}
