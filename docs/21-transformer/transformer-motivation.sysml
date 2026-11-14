package TransformerMotivation {
    private import FpDiagram::*;

    action def ManualProcess {
        in  input : Input;
        in  state : State;
        in  log : Log;
        out result : "Either Error (Value, State, Log)";
    }

    action def Step {
        in  value : Value;
        out result : Value;
    }

    action def Bind {
        in  ma : "App a";
        in  f  : "a -> App b";
        out mb : "App b";
    }

    action def RunStack {
        in  computation : "App b";
        out result : "Either Error (Value, State, Log)";
    }

    action def ThreadingComparison {
        item input : Input;
        item state : State;
        item log : Log;
        #FpNodePresentation { role = "function"; tooltip = "Manual code threads state and log and checks for failure at every step."; }
        action manual : ManualProcess;
        item manualResult : "Either Error (Value, State, Log)";

        item first : "App a";
        #FpNodePresentation { role = "hof"; tooltip = "Each step returns the same combined effect stack."; }
        item step : "Value -> App Value";
        #FpNodePresentation { role = "function"; tooltip = "bind threads the configured effects and short-circuits on failure."; }
        action bind : Bind;
        item combined : "App Value";
        action run : RunStack;
        item stackResult : "Either Error (Value, State, Log)";

        flow from input to manual;
        flow from state to manual;
        flow from log to manual;
        flow from manual to manualResult;
        flow from first to bind;
        flow from step to bind;
        flow from bind to combined;
        flow from combined to run;
        flow from run to stackResult;
    }

    #FpViewPresentation { name = "transformers"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*transformer motivation*/
        expose ThreadingComparison;
        render fpActivityDiagram;
    }
}
