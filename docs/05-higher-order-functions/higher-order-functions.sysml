package HigherOrderFunctions {
    private import FpDiagram::*;

    action def Map {
        in function : "a ⟶ b";
        in container : "Container a";
        out _ : "Container b";
    }
    action def Const {
        in value : a;
        out _ : "b ⟶ a";
    }

    action def HigherOrderExamples {
        #FpNodePresentation { role = "hof"; tooltip = "A function passed to map as an argument."; }
        item f : "f :: a ⟶ b";
        item values : "Container a";
        #FpNodePresentation { role = "function"; tooltip = "map accepts a function value and applies it to the container."; }
        action map : Map;
        item x : a;
        action constant : Const;

        flow from f to map;
        flow from values to map;
        flow from x to constant;
    }

    view diagram : FpActivityView {
        doc /* Higher-order functions accept and return functions */
        expose HigherOrderExamples;
        render fpActivityDiagram;
    }
}
