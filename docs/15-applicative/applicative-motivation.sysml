package ApplicativeMotivation {
    private import FpDiagram::*;

    action def ParseInt {
        out result : "Maybe Int";
    }

    action def ManualCombine {
        in  x : "Maybe Int";
        in  y : "Maybe Int";
        out result : "Maybe Int";
    }

    action def ApplyFirst {
        in  fn : "Maybe (Int -> Int -> Int)";
        in  x  : "Maybe Int";
        out partial : "Maybe (Int -> Int)";
    }

    action def ApplyNext {
        in  fn : "Maybe (Int -> Int)";
        in  y  : "Maybe Int";
        out result : "Maybe Int";
    }

    action def ApplicativeComparison {
        action parseX : ParseInt;
        action parseY : ParseInt;
        item parsedX : "Maybe Int";
        item parsedY : "Maybe Int";

        #FpNodePresentation { role = "function"; tooltip = "Manual nested case analysis combines both independent parse results."; }
        action manual : ManualCombine;
        item manualResult : "Maybe Int";

        #FpNodePresentation { role = "hof"; tooltip = "The addition function lifted into Maybe."; }
        item wrappedPlus : "Maybe (Int -> Int -> Int)";
        #FpNodePresentation { role = "function"; tooltip = "<*> applies a wrapped function to a wrapped value."; }
        action apFirst : ApplyFirst;
        item partial : "Maybe (Int -> Int)";
        action apNext : ApplyNext;
        item applicativeResult : "Maybe Int";

        flow from parseX to parsedX;
        flow from parseY to parsedY;
        flow from parsedX to manual;
        flow from parsedY to manual;
        flow from manual to manualResult;
        flow from wrappedPlus to apFirst;
        flow from parsedX to apFirst;
        flow from apFirst to partial;
        flow from partial to apNext;
        flow from parsedY to apNext;
        flow from apNext to applicativeResult;
    }

    #FpViewPresentation { name = "applicative"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*applicative motivation*/
        expose ApplicativeComparison;
        render fpActivityDiagram;
    }
}
