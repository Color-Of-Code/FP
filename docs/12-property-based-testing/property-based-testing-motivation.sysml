package PropertyBasedTestingMotivation {
    private import FpDiagram::*;

    action def RunExamples {
        in cases : "hand-picked inputs";
        out _ : "only those cases checked";
    }
    action def GenerateMany {
        in property : "invariant";
        out _ : "hundreds of generated inputs";
    }
    action def CheckProperty {
        in inputs : "generated inputs";
        in property : "invariant";
        out _ : "law holds or counterexample found";
    }
    action def Minimize {
        in failure : "failing case";
        out _ : "small reproducible counterexample";
    }

    action def Comparison {
        item selected : "test(0), test(1), test(-1), …";
        action examples : RunExamples;
        item invariant : "property holds for all inputs";
        action generate : GenerateMany;
        action check : CheckProperty;
        action shrink : Minimize;

        flow from selected to examples;
        flow from invariant to generate;
        flow from generate to check;
        flow from invariant to check;
        flow from check to shrink : "on failure";
    }

    view diagram : FpActivityView {
        doc /* Generated properties cover more cases than hand-picked tests */
        expose Comparison;
        render fpActivityDiagram;
    }
}
