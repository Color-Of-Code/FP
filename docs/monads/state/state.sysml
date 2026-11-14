package StateOverview {
    private import FpDiagram::*;

    action def RunState {
        in  computation : "State s a";
        in  initial     : s;
        out resultState : "(a, s)";
    }

    action def StateProcess {
        #FpNodePresentation { role = "function"; tooltip = "A State computation is a function s ⟶ (a, s); this example increments the counter and returns it."; }
        item computation : "State Int Int";
        #FpNodePresentation { role = "value"; tooltip = "Initial counter state s₀ = 0."; }
        item initial : Int;
        #FpNodePresentation { role = "function"; tooltip = "Run the computation with s₀. The output pair contains both the result and final state."; }
        action runState : RunState;
        #FpNodePresentation { role = "value"; tooltip = "(result = 1, final state = 1)"; }
        item result : "(Int, Int)";

        flow from computation to runState : "State Int Int";
        flow from initial to runState : Int;
        flow from runState to result : "(Int, Int)";
    }

    #FpViewPresentation { name = "State"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*Running a State computation returns both its value and updated state*/
        expose StateProcess;
        render fpActivityDiagram;
    }
}
