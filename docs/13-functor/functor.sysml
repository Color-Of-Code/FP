package Functor {
    private import FpDiagram::*;

    action def MapList {
        in function : "Int ⟶ Int";
        in values : "List Int";
        out _ : "List Int";
    }

    action def Mapping {
        #FpNodePresentation { role = "hof"; tooltip = "An ordinary function is supplied to fmap."; }
        item double : "double :: Int ⟶ Int";
        item values : "[1, 2, 3]";
        #FpNodePresentation { role = "function"; tooltip = "fmap applies the function to elements while preserving list shape."; }
        action fmap : MapList;
        item result : "[2, 4, 6]";

        flow from double to fmap;
        flow from values to fmap;
        flow from fmap to result;
    }

    view diagram : FpActivityView {
        doc /* Mapping a function inside a list preserves its shape */
        expose Mapping;
        render fpActivityDiagram;
    }
}
