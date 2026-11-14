package EquationalReasoningMotivation {
    private import FpDiagram::*;

    action def ImpureCall {
        in x : "x = 1";
        out _ : "x = unknown";
    }
    action def InspectCall {
        in state : "x = unknown";
        out _ : "inspect f and every call it makes";
    }
    action def PureCompute {
        in input : "x = compute(42), y = x + x";
        out _ : "compute(42) + compute(42)";
    }
    action def Substitute {
        in value : "compute(42) + compute(42)";
        out _ : "84";
    }

    action def Comparison {
        item initial : "x = 1";
        action call : ImpureCall;
        action inspect : InspectCall;
        item input : "x = compute(42), y = x + x";
        action compute : PureCompute;
        action substitute : Substitute;

        flow from initial to call;
        flow from call to inspect;
        flow from input to compute;
        flow from compute to substitute;
    }

    view diagram : FpActivityView {
        doc /* Purity makes substitution predictable */
        expose Comparison;
        render fpActivityDiagram;
    }
}
