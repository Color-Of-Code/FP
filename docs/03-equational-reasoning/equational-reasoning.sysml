package EquationalReasoning {
    private import FpDiagram::*;

    action def UnfoldInner {
        in expression : "double (double 3)";
        out _ : "double (3 + 3)";
    }
    action def EvaluateInner {
        in expression : "double (3 + 3)";
        out _ : "double 6";
    }
    action def UnfoldOuter {
        in expression : "double 6";
        out _ : "6 + 6";
    }
    action def Arithmetic {
        in expression : "6 + 6";
        out _ : "12";
    }

    action def Reduction {
        #FpNodePresentation { role = "value"; }
        item expression : "double (double 3)";
        action unfoldInner : UnfoldInner;
        action evaluateInner : EvaluateInner;
        action unfoldOuter : UnfoldOuter;
        action arithmetic : Arithmetic;

        flow from expression to unfoldInner;
        flow from unfoldInner to evaluateInner;
        flow from evaluateInner to unfoldOuter;
        flow from unfoldOuter to arithmetic;
    }

    view diagram : FpActivityView {
        doc /* Equational reasoning by substitution */
        expose Reduction;
        render fpActivityDiagram;
    }
}
