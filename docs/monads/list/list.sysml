package ListOverview {
    private import FpDiagram::*;

    action def ListBind {
        in  values : "List a";
        in  f      : "a ⟶ List b";
        out result : "List b";
    }

    action def ListProcess {
        #FpNodePresentation { role = "value"; tooltip = "List [1, 2] — bind applies the function once to each element."; }
        item values : "List Int";
        #FpNodePresentation { role = "function"; tooltip = "List bind is concatMap: apply f to every element, then flatten the produced lists."; }
        action bind : ListBind;
        #FpNodePresentation { role = "hof"; tooltip = "expand(x) = [x, x * 10]"; }
        item expand : "Int ⟶ List Int";
        #FpNodePresentation { role = "type"; tooltip = "List [1, 10, 2, 20] — all produced lists concatenated in input order."; }
        item result : "List Int";

        flow from values to bind : "List Int";
        flow from expand to bind : "Int ⟶ List Int";
        flow from bind to result : "List Int";
    }

    #FpViewPresentation { name = "List bind"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*List bind applies a function to each element and concatenates the results*/
        expose ListProcess;
        render fpActivityDiagram;
    }
}
