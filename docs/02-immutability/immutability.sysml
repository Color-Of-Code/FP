package Immutability {
    private import FpDiagram::*;

    part def SharedLists {
        #FpNodePresentation { role = "type"; tooltip = "The original list remains unchanged."; }
        part xs : "xs = [1, 2, 3]";
        #FpNodePresentation { role = "value"; tooltip = "Only the new head is allocated."; }
        part zero : "new head: 0";
        #FpNodePresentation { role = "type"; tooltip = "A new list points at the new head and shared tail."; }
        part ys : "ys = 0 : xs";

        connection connect ys to zero : "new head";
        connection connect ys to xs : "shared tail (no copy)";
    }

    view diagram : FpIbdView {
        doc /* Immutability with structural sharing */
        expose SharedLists;
        render fpIbdDiagram;
    }
}
