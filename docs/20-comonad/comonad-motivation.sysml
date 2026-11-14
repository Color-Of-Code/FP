package ComonadMotivation {
    private import FpDiagram::*;

    action def Pure {
        in  a : a;
        out ma : "M a";
    }

    action def Bind {
        in  ma : "M a";
        in  f  : "a -> M b";
        out mb : "M b";
    }

    action def Extract {
        in  wa : "W a";
        out a : a;
    }

    action def Extend {
        in  wa : "W a";
        in  f  : "W a -> b";
        out wb : "W b";
    }

    action def DualOperations {
        item a : a;
        action pure : Pure;
        item ma : "M a";
        #FpNodePresentation { role = "hof"; }
        item mf : "a -> M b";
        action bind : Bind;
        item mb : "M b";

        item wa : "W a";
        action extract : Extract;
        item focused : a;
        #FpNodePresentation { role = "hof"; }
        item wf : "W a -> b";
        action extend : Extend;
        item wb : "W b";

        flow from a to pure;
        flow from pure to ma;
        flow from ma to bind;
        flow from mf to bind;
        flow from bind to mb;
        flow from wa to extract;
        flow from extract to focused;
        flow from wa to extend;
        flow from wf to extend;
        flow from extend to wb;
    }

    #FpViewPresentation { name = "dual operations"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*comonad motivation*/
        expose DualOperations;
        render fpActivityDiagram;
    }
}
