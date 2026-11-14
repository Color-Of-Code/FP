package HigherOrderFunctionsMotivation {
    private import FpDiagram::*;

    part def MapAlternatives {
        #FpNodePresentation { role = "function"; tooltip = "Specialized mapping repeats the same structure for each container type."; }
        part mapInts : "List Int ⟶ List Int";
        part mapStrings : "List String ⟶ List String";
        part mapUsers : "List User ⟶ List User";
        #FpNodePresentation { role = "hof"; tooltip = "One function argument works for every element type."; }
        part f : "a ⟶ b";
        #FpNodePresentation { role = "function"; tooltip = "The generic map applies f to any list element type."; }
        part genericMap : "(a ⟶ b) ⟶ List a ⟶ List b";

        connection connect f to genericMap : "function argument";
    }

    view diagram : FpIbdView {
        doc /* One generic map replaces type-specific maps */
        expose MapAlternatives;
        render fpIbdDiagram;
    }
}
