// SysML v2 — Prob motivation: WITH the Prob monad (bind + pure)
//
// A Prob distribution is a list of (value, probability) pairs.
// The producing functions DO NOT COMPOSE naturally:
//   biasedCoin : Prob CoinFace
//   rollDie    : CoinFace → Prob Int     ← expects CoinFace, not Prob CoinFace
//
// Two combinators do all the work:
//   pure  : a → Prob a                              — point mass at a (probability 1)
//   (>>=) : Prob a → (a → Prob b) → Prob b
//
// bind applies the next conditional distribution to each branch and
// MULTIPLIES the probabilities — the joint distribution falls out of
// the chain for free, without manually summing over outcomes.

package ProbMotivationWith {

    action def BiasedCoin {
        out _ : "Prob CoinFace";
    }

    action def RollDie {
        in  coin : "CoinFace";
        out _    : "Prob Int";
    }

    // bind : Prob a → (a → Prob b) → Prob b
    action def Bind {
        in  ma : "Prob a";
        in  f  : "a ⟶ Prob b";
        out _  : "Prob b";
    }

    activity def CoinThenDieWith {
        // entry: biasedCoin is itself a distribution (no input)
        action biasedCoin : BiasedCoin;

        // bind in rollDie as the conditional distribution
        object rollDieFn  : "CoinFace ⟶ Prob Int";
        action bindRoll   : Bind;

        // output
        object outResult  : "Prob Int";

        // main flow runs through the bind nodes
        flow from biasedCoin to bindRoll  : "Prob CoinFace";
        flow from bindRoll   to outResult : "runProb";

        // the conditional distribution is supplied as the f argument
        flow from rollDieFn  to bindRoll;

        // ── Swimlanes ───────────────────────────────────────────────────────
        lane plain : "Plain values & functions" =
            rollDieFn, outResult;
        lane monad : "Prob monad" =
            biasedCoin, bindRoll;
    }
}

#diagram {
    type  = activity
    title = "With pure + bind: bind multiplies probabilities and flattens the joint distribution"
    name  = "coinThenDie"
    show biasedCoin as function
    show bindRoll   as function
    show rollDieFn  as hof
    show outResult  as type
    tooltip biasedCoin = "biasedCoin : Prob CoinFace — distribution over the coin outcomes."
    tooltip bindRoll   = ">>= : applies the conditional distribution to every branch; multiplies probabilities and flattens."
    tooltip rollDieFn  = "rollDie : CoinFace → Prob Int. HOF argument — its input is CoinFace, not Prob CoinFace."
    tooltip outResult  = "Prob Int — the joint distribution. bind has multiplied probabilities and flattened the nested list automatically."
}

