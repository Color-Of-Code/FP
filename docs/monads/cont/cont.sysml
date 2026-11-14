package ContOverview {
    private import FpDiagram::*;

    action def RunCont {
        in  computation : "Cont r a";
        in  k           : "a ⟶ r";
        out result      : r;
    }

    action def ContProcess {
        #FpNodePresentation { role = "type"; tooltip = "Cont r a = (a ⟶ r) ⟶ r — a computation waiting for a continuation."; }
        item computation : "Cont r a";
        #FpNodePresentation { role = "hof"; tooltip = "k : a ⟶ r — the rest of the computation, supplied by the caller."; }
        item k : "a ⟶ r";
        #FpNodePresentation { role = "function"; tooltip = "Run the suspended Cont computation by supplying its continuation."; }
        action runCont : RunCont;
        #FpNodePresentation { role = "value"; tooltip = "The final result produced when the computation calls k with its value."; }
        item result : r;

        flow from computation to runCont : "Cont r a";
        flow from k to runCont : "a ⟶ r";
        flow from runCont to result : r;
    }

    #FpViewPresentation { name = "Cont"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*A Cont computation waits for its continuation to produce the final result*/
        expose ContProcess;
        render fpActivityDiagram;
    }
}
