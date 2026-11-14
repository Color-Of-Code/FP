package LazyEvaluation {
    private import FpDiagram::*;

    action def EvaluateNow {
        in arguments : "1 + 1, 2 * 3";
        out _ : "2, 6";
    }
    action def CallWithValues {
        in arguments : "2, 6";
        out _ : "f(2, 6)";
    }
    action def Defer {
        in arguments : "1 + 1, 2 * 3";
        out _ : "thunks";
    }
    action def Demand {
        in thunks : "thunks";
        out _ : "only the demanded argument is forced";
    }
    action def Take {
        in stream : "0 : 1 : 2 : …";
        in count : "5";
        out _ : "[0, 1, 2, 3, 4]";
    }

    action def EvaluationStrategies {
        item expressions : "f(1 + 1, 2 * 3)";
        action eager : EvaluateNow;
        action call : CallWithValues;
        action defer : Defer;
        action demand : Demand;
        item naturals : "nats = 0 : 1 : 2 : …";
        item count : "5";
        action takeFive : Take;

        flow from expressions to eager;
        flow from eager to call;
        flow from expressions to defer;
        flow from defer to demand;
        flow from naturals to takeFive;
        flow from count to takeFive;
    }

    view diagram : FpActivityView {
        doc /* Eager and lazy evaluation defer work differently */
        expose EvaluationStrategies;
        render fpActivityDiagram;
    }
}
