package FoldMotivation {
    private import FpDiagram::*;

    action def HandWrittenSum {
        in  xs : "List Int";
        out sum : Int;
    }

    action def FoldSum {
        in  xs : "List Int";
        in  f  : "Int -> Int -> Int";
        in  z  : Int;
        out sum : Int;
    }

    action def SumComparison {
        #FpNodePresentation { role = "type"; }
        item xs : "List Int";
        #FpNodePresentation { role = "function"; tooltip = "A dedicated loop repeats the traversal for this aggregation."; }
        action manual : HandWrittenSum;
        item manualSum : Int;

        #FpNodePresentation { role = "hof"; tooltip = "(+) combines the accumulator with each list element."; }
        item plus : "Int -> Int -> Int";
        #FpNodePresentation { role = "value"; }
        item zero : Int;
        #FpNodePresentation { role = "function"; tooltip = "fold reuses the traversal and supplies only the combining function and initial value."; }
        action fold : FoldSum;
        item foldSum : Int;

        flow from xs to manual;
        flow from manual to manualSum;
        flow from xs to fold;
        flow from plus to fold;
        flow from zero to fold;
        flow from fold to foldSum;
    }

    #FpViewPresentation { name = "fold"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*fold motivation*/
        expose SumComparison;
        render fpActivityDiagram;
    }
}
