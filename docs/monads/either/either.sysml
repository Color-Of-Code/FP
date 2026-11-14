package EitherOverview {
    private import FpDiagram::*;

    action def EitherBind {
        in  ma : "Either Error a";
        in  f  : "a ⟶ Either Error b";
        out mb : "Either Error b";
    }

    action def EitherProcess {
        #FpNodePresentation { role = "value"; tooltip = "Right \"abc\" — begin by parsing text that is not a number."; }
        item input : "Either Error String";
        #FpNodePresentation { role = "hof"; tooltip = "parseAge: String ⟶ Either Error Int"; }
        item parseAge : "String ⟶ Either Error Int";
        #FpNodePresentation { role = "function"; tooltip = "bind calls parseAge for Right; it propagates Left without calling the function."; }
        action bind1 : EitherBind;
        #FpNodePresentation { role = "hof"; tooltip = "validateAge: Int ⟶ Either Error Int; skipped after a Left."; }
        item validateAge : "Int ⟶ Either Error Int";
        #FpNodePresentation { role = "function"; tooltip = "The Left parse error passes through unchanged; validateAge is not called."; }
        action bind2 : EitherBind;
        #FpNodePresentation { role = "hof"; tooltip = "formatAge: Int ⟶ Either Error String; skipped after a Left."; }
        item formatAge : "Int ⟶ Either Error String";
        #FpNodePresentation { role = "function"; tooltip = "bind propagates the same Left error and does not call formatAge."; }
        action bind3 : EitherBind;
        #FpNodePresentation { role = "type"; tooltip = "Left \"not a number\" — the first error is preserved."; }
        item result : "Either Error String";

        flow from input to bind1 : "Either Error String";
        flow from parseAge to bind1 : "String ⟶ Either Error Int";
        flow from bind1 to bind2 : "Either Error Int";
        flow from validateAge to bind2 : "Int ⟶ Either Error Int";
        flow from bind2 to bind3 : "Either Error Int";
        flow from formatAge to bind3 : "Int ⟶ Either Error String";
        flow from bind3 to result : "Either Error String";
        succession bind1 then bind2;
        succession bind2 then bind3;
    }

    #FpViewPresentation { name = "Either"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*Either bind propagates the first Left error and skips later functions*/
        expose EitherProcess;
        render fpActivityDiagram;
    }
}
