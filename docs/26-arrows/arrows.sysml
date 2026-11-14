package ArrowOperations {
    private import FpDiagram::*;

    action def Arr {
        in  f : "B -> C";
        out arrow : "A B C";
    }

    action def First {
        in  arrow : "A B C";
        out paired : "A (B,D) (C,D)";
    }

    action def Compose {
        in  left : "A B C";
        in  right : "A C D";
        out result : "A B D";
    }

    action def ArrowInterface {
        #FpNodePresentation { role = "hof"; tooltip = "A pure function is embedded into the arrow abstraction."; }
        item f : "B -> C";
        #FpNodePresentation { role = "function"; tooltip = "arr embeds an ordinary function as an arrow."; }
        action arr : Arr;
        item arrow : "A B C";

        #FpNodePresentation { role = "function"; tooltip = "first applies the arrow to one component and passes the other through unchanged."; }
        action first : First;
        item paired : "A (B,D) (C,D)";

        #FpNodePresentation { role = "hof"; tooltip = "The next arrow consumes the previous arrow's output type."; }
        item next : "A C D";
        #FpNodePresentation { role = "function"; tooltip = ">>> composes arrows sequentially."; }
        action compose : Compose;
        item composed : "A B D";

        flow from f to arr;
        flow from arr to arrow;
        flow from arrow to first;
        flow from first to paired;
        flow from arrow to compose;
        flow from next to compose;
        flow from compose to composed;
    }

    #FpViewPresentation { name = "Arrow"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*arrows*/
        expose ArrowInterface;
        render fpActivityDiagram;
    }
}
