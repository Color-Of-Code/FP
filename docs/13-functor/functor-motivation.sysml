package FunctorMotivation {
    private import FpDiagram::*;

    part def GenericMapping {
        #FpNodePresentation { role = "function"; tooltip = "The same mapping logic is duplicated for each container."; }
        part listMap : "map_list :: List a ⟶ List b";
        part maybeMap : "map_maybe :: Maybe a ⟶ Maybe b";
        part treeMap : "map_tree :: Tree a ⟶ Tree b";
        #FpNodePresentation { role = "hof"; tooltip = "One plain function is reused inside every functor."; }
        part f : "a ⟶ b";
        #FpNodePresentation { role = "function"; tooltip = "fmap lifts f according to the container's structure."; }
        part fmap : "fmap :: (a ⟶ b) ⟶ F a ⟶ F b";

        connection connect f to fmap : "function argument";
    }

    view diagram : FpIbdView {
        doc /* fmap replaces container-specific mapping code */
        expose GenericMapping;
        render fpIbdDiagram;
    }
}
