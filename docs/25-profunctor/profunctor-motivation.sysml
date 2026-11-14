package ProfunctorMotivation {
    private import FpDiagram::*;

    action def Dimap {
        in  before : "A' -> A";
        in  after : "B -> B'";
        in  pab : "P A B";
        out result : "P A' B'";
    }

    action def AdaptBothEnds {
        #FpNodePresentation { role = "hof"; tooltip = "Pre-map converts the new input A' to the input A expected by P."; }
        item before : "A' -> A";
        #FpNodePresentation { role = "hof"; tooltip = "Post-map converts P's output B to the new output B'."; }
        item after : "B -> B'";
        #FpNodePresentation { role = "type"; }
        item pab : "P A B";
        #FpNodePresentation { role = "function"; tooltip = "dimap adapts the input and output sides independently."; }
        action dimap : Dimap;
        item result : "P A' B'";

        flow from before to dimap;
        flow from after to dimap;
        flow from pab to dimap;
        flow from dimap to result;
    }

    #FpViewPresentation { name = "dimap"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*profunctor motivation*/
        expose AdaptBothEnds;
        render fpActivityDiagram;
    }
}
