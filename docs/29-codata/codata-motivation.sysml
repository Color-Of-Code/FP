package CodataMotivation {
    private import FpDiagram::*;

    action def UnfoldStream {
        in  seed : Int;
        out stream : "Stream Int";
    }

    action def ObserveHead {
        in  stream : "Stream Int";
        out head : Int;
    }

    action def ObserveTail {
        in  stream : "Stream Int";
        out tail : "Stream Int";
    }

    action def StreamObservations {
        #FpNodePresentation { role = "value"; tooltip = "A seed determines the next observable piece of the stream."; }
        item seed : Int;
        #FpNodePresentation { role = "function"; tooltip = "The anamorphism produces one stream layer and a new seed on demand."; }
        action ana : UnfoldStream;
        item stream : "Stream Int";

        #FpNodePresentation { role = "function"; tooltip = "Each observation reveals a finite piece; the stream need not terminate."; }
        action head : ObserveHead;
        item value : Int;
        action tail : ObserveTail;
        item rest : "Stream Int";

        flow from seed to ana;
        flow from ana to stream;
        flow from stream to head;
        flow from head to value;
        flow from stream to tail;
        flow from tail to rest;
    }

    #FpViewPresentation { name = "coinduction"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*codata motivation*/
        expose StreamObservations;
        render fpActivityDiagram;
    }
}
