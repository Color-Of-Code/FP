package ProbabilityOverview {
    private import FpDiagram::*;

    action def Uniform {
        in  values : "List a";
        out dist   : "Prob a";
    }

    action def Probability {
        in  dist : "Prob a";
        in  pred : "a ⟶ Bool";
        out p    : Double;
    }

    action def ProbabilityProcess {
        #FpNodePresentation { role = "value"; tooltip = "[Heads, Tails]"; }
        item values : "List Outcome";
        #FpNodePresentation { role = "function"; tooltip = "Assign equal weight 1/n to every possible outcome."; }
        action uniform : Uniform;
        #FpNodePresentation { role = "type"; tooltip = "A distribution of outcomes with probabilities that sum to 1."; }
        item dist : "Prob Outcome";
        #FpNodePresentation { role = "hof"; tooltip = "isHeads : Outcome ⟶ Bool"; }
        item predicate : "Outcome ⟶ Bool";
        #FpNodePresentation { role = "function"; tooltip = "Sum the weights of outcomes for which the predicate is true."; }
        action probability : Probability;
        #FpNodePresentation { role = "value"; tooltip = "The total probability of Heads; for a fair two-outcome list this is 0.5."; }
        item p : Double;

        flow from values to uniform : "List Outcome";
        flow from uniform to dist : "Prob Outcome";
        flow from dist to probability : "Prob Outcome";
        flow from predicate to probability : "Outcome ⟶ Bool";
        flow from probability to p : Double;
        succession uniform then probability;
    }

    #FpViewPresentation { name = "Probability"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*uniform assigns weights and probability sums matching outcomes*/
        expose ProbabilityProcess;
        render fpActivityDiagram;
    }
}
