package PrismOptic {
    private import FpDiagram::*;

    part def CirclePrism {
        part shape : Shape;
        part circle : "Prism Shape Double";

        part previewOp : "preview";
        part maybeRadius : "Maybe Double";
        part radius : Double;
        part reviewOp : "review";
        part constructedShape : Shape;

        connection connect circle to previewOp;
        connection connect shape to previewOp;
        connection connect previewOp to maybeRadius;

        connection connect circle to reviewOp;
        connection connect radius to reviewOp;
        connection connect reviewOp to constructedShape;
    }

    view diagram : FpIbdView {
        doc /*Prism previews one constructor and can fail*/
        expose CirclePrism;
        render fpIbdDiagram;
    }
}
