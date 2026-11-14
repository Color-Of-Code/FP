package TraversableMotivation {
    private import FpDiagram::*;

    action def ManualTraverse {
        in  xs : "List Int";
        in  validate : "Int -> Maybe Int";
        out result : "Maybe (List Int)";
    }

    action def Traverse {
        in  xs : "List Int";
        in  validate : "Int -> Maybe Int";
        out result : "Maybe (List Int)";
    }

    action def ValidationComparison {
        #FpNodePresentation { role = "type"; }
        item xs : "List Int";
        #FpNodePresentation { role = "hof"; tooltip = "A validation that may fail for each element."; }
        item validate : "Int -> Maybe Int";

        #FpNodePresentation { role = "function"; tooltip = "The manual loop checks each result and reconstructs the list."; }
        action manual : ManualTraverse;
        item manualResult : "Maybe (List Int)";

        #FpNodePresentation { role = "function"; tooltip = "traverse performs the same walk and combines the Maybe effects."; }
        action traverse : Traverse;
        item traversedResult : "Maybe (List Int)";

        flow from xs to manual;
        flow from validate to manual;
        flow from manual to manualResult;
        flow from xs to traverse;
        flow from validate to traverse;
        flow from traverse to traversedResult;
    }

    #FpViewPresentation { name = "traverse"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*traversable motivation*/
        expose ValidationComparison;
        render fpActivityDiagram;
    }
}
