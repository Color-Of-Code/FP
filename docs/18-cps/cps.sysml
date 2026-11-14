package CpsStructure {
    private import FpDiagram::*;

    action def DirectStep {
        in  value : Int;
        out result : Int;
    }

    action def CpsStep {
        in  value : Int;
        in  next : "Int -> Result";
        out result : Result;
    }

    action def CpsProcess {
        item x : Int;
        action h : DirectStep;
        action g : DirectStep;
        action f : DirectStep;
        item directResult : Int;

        #FpNodePresentation { role = "hof"; tooltip = "The continuation says what to do with h's result; here it represents the rest of the computation."; }
        item next : "Int -> Result";
        #FpNodePresentation { role = "function"; tooltip = "In CPS the function calls its continuation instead of returning an intermediate value."; }
        action hCps : CpsStep;
        item cpsResult : Result;

        flow from x to h;
        flow from h to g;
        flow from g to f;
        flow from f to directResult;
        flow from x to hCps;
        flow from next to hCps;
        flow from hCps to cpsResult;
    }

    #FpViewPresentation { name = "CPS"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*CPS structure*/
        expose CpsProcess;
        render fpActivityDiagram;
    }
}
