package SemigroupMonoidMotivation {
    private import FpDiagram::*;

    action def Mconcat {
        in combine : "a ⟶ a ⟶ a";
        in identity : a;
        in values : "List a";
        out _ : a;
    }

    action def GenericAggregation {
        #FpNodePresentation { role = "hof"; tooltip = "The type's associative operation is supplied as a value."; }
        item combine : "(<>) :: a ⟶ a ⟶ a";
        #FpNodePresentation { role = "value"; tooltip = "The monoid identity starts the fold."; }
        item identity : "mempty :: a";
        item values : "values :: List a";
        #FpNodePresentation { role = "function"; tooltip = "One aggregation function works for any Monoid instance."; }
        action mconcat : Mconcat;

        flow from combine to mconcat;
        flow from identity to mconcat;
        flow from values to mconcat;
    }

    view diagram : FpActivityView {
        doc /* One mconcat works for every Monoid instance */
        expose GenericAggregation;
        render fpActivityDiagram;
    }
}
