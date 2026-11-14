package GetterSetterOptics {
    private import FpDiagram::*;

    part def GetterSetterOperations {
        part source : S;

        part getter : "Getter S A";
        part viewOp : "view";
        part focused : A;

        part setter : "Setter S A";
        part transform : "A ⟶ A";
        part overOp : "over";
        part updated : S;

        connection connect getter to viewOp;
        connection connect source to viewOp;
        connection connect viewOp to focused;

        connection connect setter to overOp;
        connection connect transform to overOp;
        connection connect source to overOp;
        connection connect overOp to updated;
    }

    view diagram : FpIbdView {
        doc /*Getter reads one value; Setter modifies focused values*/
        expose GetterSetterOperations;
        render fpIbdDiagram;
    }
}
