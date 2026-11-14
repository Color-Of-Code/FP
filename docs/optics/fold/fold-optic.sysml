package FoldOptic {
    private import FpDiagram::*;

    part def FoldComposition {
        part orders : "Fold Cart Order";
        part price  : "Fold Order Double";
        part compose : "optic composition";
        part prices : "Fold Cart Double";

        part cart : Cart;
        part collect : toListOf;
        part allPrices : "[Double]";

        connection connect orders to compose;
        connection connect price to compose;
        connection connect compose to prices;
        connection connect cart to collect;
        connection connect prices to collect;
        connection connect collect to allPrices;
    }

    view diagram : FpIbdView {
        doc /*Fold composes read-only paths to collect zero or more values*/
        expose FoldComposition;
        render fpIbdDiagram;
    }
}
