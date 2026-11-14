package Newtype {
    private import FpDiagram::*;

    part def WrappedMeasures {
        #FpNodePresentation { role = "type"; tooltip = "All wrappers share the same runtime representation."; }
        part raw : Int;
        #FpNodePresentation { role = "type"; tooltip = "Distinct from Year and Kg at compile time."; }
        part age : Age;
        part year : Year;
        part kg : Kg;

        connection connect raw to age : "wrap / coerce (zero-cost)";
        connection connect raw to year : "wrap / coerce (zero-cost)";
        connection connect raw to kg : "wrap / coerce (zero-cost)";
    }

    view diagram : FpIbdView {
        doc /* Newtypes distinguish types without changing representation */
        expose WrappedMeasures;
        render fpIbdDiagram;
    }
}
