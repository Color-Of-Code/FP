package RecursionSchemesMotivation {
    private import FpDiagram::*;

    action def Cata {
        in  expr : "Fix ExprF";
        in  algebra : "ExprF Int -> Int";
        out result : Int;
    }

    action def EvaluateWithCata {
        #FpNodePresentation { role = "type"; tooltip = "The recursive expression contains the shape and child expressions."; }
        item expr : "Fix ExprF";
        #FpNodePresentation { role = "hof"; tooltip = "evalAlg handles one ExprF layer after the recursive children have been folded."; }
        item evalAlg : "ExprF Int -> Int";
        #FpNodePresentation { role = "function"; tooltip = "cata owns the traversal; the algebra contains no recursive calls."; }
        action cata : Cata;
        item value : Int;

        flow from expr to cata;
        flow from evalAlg to cata;
        flow from cata to value;
    }

    #FpViewPresentation { name = "cata"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*recursion schemes motivation*/
        expose EvaluateWithCata;
        render fpActivityDiagram;
    }
}
