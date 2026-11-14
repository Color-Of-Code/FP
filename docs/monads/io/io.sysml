package IOOverview {
    private import FpDiagram::*;

    action def IOBind {
        in  ia : "IO a";
        in  f  : "a ⟶ IO b";
        out ib : "IO b";
    }

    action def IOProcess {
        #FpNodePresentation { role = "type"; tooltip = "getLine : IO String — a description of reading a line, not an already-read string."; }
        item readLine : "IO String";
        #FpNodePresentation { role = "function"; tooltip = "Sequence the read action, then construct the next IO action from its result."; }
        action bind1 : IOBind;
        #FpNodePresentation { role = "hof"; tooltip = "greet : String ⟶ IO Unit — constructs an output action using the name."; }
        item greet : "String ⟶ IO Unit";
        #FpNodePresentation { role = "function"; tooltip = "Sequence the greeting action with the confirmation action."; }
        action bind2 : IOBind;
        #FpNodePresentation { role = "hof"; tooltip = "confirm : Unit ⟶ IO Unit — constructs the final output action."; }
        item confirm : "Unit ⟶ IO Unit";
        #FpNodePresentation { role = "type"; tooltip = "The complete description of the sequenced effects; running it performs them in order."; }
        item program : "IO Unit";

        flow from readLine to bind1 : "IO String";
        flow from greet to bind1 : "String ⟶ IO Unit";
        flow from bind1 to bind2 : "IO Unit";
        flow from confirm to bind2 : "Unit ⟶ IO Unit";
        flow from bind2 to program : "IO Unit";
        succession bind1 then bind2;
    }

    #FpViewPresentation { name = "IO"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*IO computations describe effects and bind sequences them explicitly*/
        expose IOProcess;
        render fpActivityDiagram;
    }
}
