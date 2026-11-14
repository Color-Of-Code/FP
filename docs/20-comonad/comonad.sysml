package ComonadOperations {
    private import FpDiagram::*;

    action def Extract {
        in  wa : "W a";
        out a : a;
    }

    action def Extend {
        in  wa : "W a";
        in  f  : "W a -> b";
        out wb : "W b";
    }

    action def ComonadProcess {
        #FpNodePresentation { role = "type"; tooltip = "A value together with its surrounding context."; }
        item wa : "W a";
        #FpNodePresentation { role = "function"; tooltip = "extract observes the focused value."; }
        action extract : Extract;
        item a : a;

        #FpNodePresentation { role = "hof"; tooltip = "A computation that can inspect the whole context."; }
        item f : "W a -> b";
        #FpNodePresentation { role = "function"; tooltip = "extend applies f at each shifted focus, preserving the context shape."; }
        action extend : Extend;
        item wb : "W b";

        flow from wa to extract;
        flow from extract to a;
        flow from wa to extend;
        flow from f to extend;
        flow from extend to wb;
    }

    #FpViewPresentation { name = "comonad"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*comonad*/
        expose ComonadProcess;
        render fpActivityDiagram;
    }
}
