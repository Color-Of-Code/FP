package MaybeOverview {
    private import FpDiagram::*;

    action def MaybeBind {
        in  ma : "Maybe a";
        in  f  : "a ⟶ Maybe b";
        out mb : "Maybe b";
    }

    action def MaybeProcess {
        #FpNodePresentation { role = "value"; tooltip = "Just 10"; }
        item input : "Maybe Int";
        #FpNodePresentation { role = "function"; tooltip = "bind applies safeDivide(2) to Just 10, producing Just 5."; }
        action bind1 : MaybeBind;
        #FpNodePresentation { role = "hof"; tooltip = "safeDivide(2) : Int ⟶ Maybe Int"; }
        item divideByTwo : "Int ⟶ Maybe Int";
        #FpNodePresentation { role = "function"; tooltip = "bind applies safeDivide(0) to Just 5; division by zero returns Nothing."; }
        action bind2 : MaybeBind;
        #FpNodePresentation { role = "hof"; tooltip = "safeDivide(0) : Int ⟶ Maybe Int"; }
        item divideByZero : "Int ⟶ Maybe Int";
        #FpNodePresentation { role = "function"; tooltip = "Nothing passes through unchanged; the next function is not called."; }
        action bind3 : MaybeBind;
        #FpNodePresentation { role = "hof"; tooltip = "safeDivide(1) : Int ⟶ Maybe Int — skipped because the input is Nothing."; }
        item divideByOne : "Int ⟶ Maybe Int";
        #FpNodePresentation { role = "type"; tooltip = "Nothing — the first failed step short-circuits the remaining chain."; }
        item result : "Maybe Int";

        flow from input to bind1 : "Maybe Int";
        flow from divideByTwo to bind1 : "Int ⟶ Maybe Int";
        flow from bind1 to bind2 : "Maybe Int";
        flow from divideByZero to bind2 : "Int ⟶ Maybe Int";
        flow from bind2 to bind3 : "Maybe Int";
        flow from divideByOne to bind3 : "Int ⟶ Maybe Int";
        flow from bind3 to result : "Maybe Int";
        succession bind1 then bind2;
        succession bind2 then bind3;
    }

    #FpViewPresentation { name = "Maybe bind"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*Maybe bind propagates Nothing and skips the remaining functions*/
        expose MaybeProcess;
        render fpActivityDiagram;
    }
}
