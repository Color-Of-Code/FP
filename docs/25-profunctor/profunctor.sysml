package ProfunctorOptic {
    private import FpDiagram::*;

    part def OpticType {
        #FpNodePresentation { role = "type"; tooltip = "A profunctor with the optic's focused input and output types."; }
        part focused : "P a b";
        #FpNodePresentation { role = "type"; tooltip = "The whole structure's input and output types."; }
        part whole : "P s t";
        #FpNodePresentation { role = "type"; tooltip = "The optic is polymorphic in P, subject to a constraint such as Strong or Choice."; }
        part constraint : "forall P. C P";
        #FpNodePresentation { role = "function"; tooltip = "An optic transforms the focused profunctor into the whole-structure profunctor."; }
        part optic : "Optic C s t a b";

        connection connect focused to optic;
        connection connect constraint to optic;
        connection connect optic to whole;
    }

    view diagram : FpIbdView {
        doc /*profunctor*/
        expose OpticType;
        render fpIbdDiagram;
    }
}
