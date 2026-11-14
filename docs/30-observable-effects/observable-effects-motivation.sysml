package ObservableEffectsMotivation {
    private import FpDiagram::*;

    action def NaiveCompare {
        in  pairs : "Byte Pairs";
        out equal : Boolean;
    }

    action def ConstantTimeCompare {
        in  pairs : "Byte Pairs";
        out equal : Boolean;
    }

    action def ComparisonTiming {
        item pairs : "Byte Pairs";
        #FpNodePresentation { role = "function"; tooltip = "A short-circuiting comparison stops at the first mismatch."; }
        action naive : NaiveCompare;
        item naiveResult : Boolean;

        #FpNodePresentation { role = "function"; tooltip = "Accumulate differences across every byte without a secret-dependent early exit."; }
        action constantTime : ConstantTimeCompare;
        item constantResult : Boolean;

        flow from pairs to naive;
        flow from naive to naiveResult;
        flow from pairs to constantTime;
        flow from constantTime to constantResult;
    }

    #FpViewPresentation { name = "comparison timing"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*observable effects motivation*/
        expose ComparisonTiming;
        render fpActivityDiagram;
    }
}
