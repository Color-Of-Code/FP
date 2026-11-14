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
    private import FpDiagram::*;

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

    action def CoinThenDieWith {
        // entry: biasedCoin is itself a distribution (no input)
        #FpNodePresentation { role = "function"; tooltip = "biasedCoin : Prob CoinFace — distribution over the coin outcomes."; laneId = "monad"; laneLabel = "Prob monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action biasedCoin : BiasedCoin;

        // bind in rollDie as the conditional distribution
        #FpNodePresentation { role = "hof"; tooltip = "rollDie : CoinFace → Prob Int. HOF argument — its input is CoinFace, not Prob CoinFace."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item rollDieFn  : "CoinFace ⟶ Prob Int";
        #FpNodePresentation { role = "function"; tooltip = ">>= : applies the conditional distribution to every branch; multiplies probabilities and flattens."; laneId = "monad"; laneLabel = "Prob monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindRoll   : Bind;

        // output
        #FpNodePresentation { role = "type"; tooltip = "Prob Int — the joint distribution. bind has multiplied probabilities and flattened the nested list automatically."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }
        item outResult  : "Prob Int";

        // main flow runs through the bind nodes
        flow from biasedCoin to bindRoll  : "Prob CoinFace";
        flow from bindRoll   to outResult : "runProb";

        // the conditional distribution is supplied as the f argument
        flow from rollDieFn  to bindRoll;

        // ── Swimlanes ───────────────────────────────────────────────────────


    }
    #FpViewPresentation { name = "coinThenDie"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: bind multiplies probabilities and flattens the joint distribution*/
        expose CoinThenDieWith;
        render fpActivityDiagram;
    }
}

