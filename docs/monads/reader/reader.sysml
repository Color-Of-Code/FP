package ReaderOverview {
    private import FpDiagram::*;

    action def RunReader {
        in  reader : "Reader r a";
        in  env    : r;
        out result : a;
    }

    action def ReaderProcess {
        #FpNodePresentation { role = "function"; tooltip = "A suspended Reader computation: a function from Config to String."; }
        item reader : "Reader Config String";
        #FpNodePresentation { role = "value"; tooltip = "The shared environment supplied when the Reader computation runs."; }
        item env : Config;
        #FpNodePresentation { role = "function"; tooltip = "Supply the environment to the Reader function; it is not stored or modified by the computation."; }
        action runReader : RunReader;
        #FpNodePresentation { role = "value"; tooltip = "The result produced by applying the Reader computation to this environment."; }
        item result : String;

        flow from reader to runReader : "Reader Config String";
        flow from env to runReader : Config;
        flow from runReader to result : String;
    }

    #FpViewPresentation { name = "Reader"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*Reader runs a computation with an environment to produce a value*/
        expose ReaderProcess;
        render fpActivityDiagram;
    }
}
