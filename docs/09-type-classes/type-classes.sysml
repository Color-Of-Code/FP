package TypeClasses {
    private import FpDiagram::*;

    part def InstanceDispatch {
        #FpNodePresentation { role = "type"; tooltip = "A type class declares operations required of its instances."; }
        part showClass : "Show: show :: a ⟶ String";
        #FpNodePresentation { role = "function"; tooltip = "An implementation supplies the class operation for Int."; }
        part intInstance : "Show Int";
        part boolInstance : "Show Bool";
        #FpNodePresentation { role = "value"; tooltip = "The caller depends on the contract, not a specific type."; }
        part client : "printAll :: Show a ⇒ [a] ⟶ IO ()";

        connection connect showClass to intInstance : "implements";
        connection connect showClass to boolInstance : "implements";
        connection connect intInstance to client : "selected by type";
        connection connect boolInstance to client : "selected by type";
    }

    view diagram : FpIbdView {
        doc /* Type classes define operations and select instances */
        expose InstanceDispatch;
        render fpIbdDiagram;
    }
}
