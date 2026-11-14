package CompositionMotivation {
    private import FpDiagram::*;

    action def Compose {
        in first : "a ⟶ b";
        in second : "b ⟶ c";
        out _ : "a ⟶ c";
    }

    action def Pipelines {
        item validateAndTrim : "validate_and_trim :: a ⟶ c";
        item validateTrimFormat : "validate_trim_format :: a ⟶ d";
        #FpNodePresentation { role = "hof"; tooltip = "Reusable validation step."; }
        item validate : "validate :: a ⟶ b";
        #FpNodePresentation { role = "hof"; tooltip = "Reusable trim step."; }
        item trim : "trim :: b ⟶ c";
        #FpNodePresentation { role = "hof"; tooltip = "Reusable formatting step."; }
        item format : "format :: c ⟶ d";
        #FpNodePresentation { role = "function"; tooltip = "Compose reusable functions into a pipeline instead of defining each wrapper."; }
        action composeVT : Compose;
        action composeFormat : Compose;

        flow from validate to composeVT;
        flow from trim to composeVT;
        flow from composeVT to composeFormat;
        flow from format to composeFormat;
    }

    view diagram : FpActivityView {
        doc /* Composition replaces one-off wrapper functions */
        expose Pipelines;
        render fpActivityDiagram;
    }
}
