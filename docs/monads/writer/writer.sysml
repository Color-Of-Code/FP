package WriterOverview {
    private import FpDiagram::*;

    action def WriterBind {
        in  wa : "Writer w a";
        in  f  : "a ⟶ Writer w b";
        out wb : "Writer w b";
    }

    action def WriterProcess {
        #FpNodePresentation { role = "value"; tooltip = "(3, []) — the starting result and empty log."; }
        item input : "Writer [String] Int";
        #FpNodePresentation { role = "function"; tooltip = "Apply doubleWithLog, then append its log fragment to the existing log."; }
        action bind1 : WriterBind;
        #FpNodePresentation { role = "hof"; tooltip = "doubleWithLog : Int ⟶ Writer [String] Int; for 3 it yields (6, [\"doubled 3\"])."; }
        item doubleWithLog : "Int ⟶ Writer [String] Int";
        #FpNodePresentation { role = "function"; tooltip = "Apply addOneWithLog and append this step's log after the first step's log."; }
        action bind2 : WriterBind;
        #FpNodePresentation { role = "hof"; tooltip = "addOneWithLog : Int ⟶ Writer [String] Int; for 6 it yields (7, [\"added 1 to 6\"])."; }
        item addOneWithLog : "Int ⟶ Writer [String] Int";
        #FpNodePresentation { role = "type"; tooltip = "(7, [\"doubled 3\", \"added 1 to 6\"]) — result plus logs accumulated in order."; }
        item result : "Writer [String] Int";

        flow from input to bind1 : "Writer [String] Int";
        flow from doubleWithLog to bind1 : "Int ⟶ Writer [String] Int";
        flow from bind1 to bind2 : "Writer [String] Int";
        flow from addOneWithLog to bind2 : "Int ⟶ Writer [String] Int";
        flow from bind2 to result : "Writer [String] Int";
        succession bind1 then bind2;
    }

    #FpViewPresentation { name = "Writer bind"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*Writer bind combines each step's log with the result in order*/
        expose WriterProcess;
        render fpActivityDiagram;
    }
}
