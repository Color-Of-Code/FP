package PropertyBasedTesting {
    private import FpDiagram::*;

    action def Generate {
        in property : "property :: input ⟶ Bool";
        out _ : "generated inputs";
    }
    action def Check {
        in property : "input ⟶ Bool";
        in inputs : "generated inputs";
        out _ : "pass or fail";
    }
    action def Shrink {
        in failure : "failing input";
        out _ : "minimal counterexample";
    }
    action def Report {
        in counterexample : "minimal counterexample";
        out _ : "counterexample and seed";
    }

    action def PropertyWorkflow {
        #FpNodePresentation { role = "hof"; tooltip = "A universally stated law expressed as an executable predicate."; }
        item property : "property: input ⟶ Bool";
        action generate : Generate;
        action check : Check;
        decide outcome;
        action shrink : Shrink;
        action report : Report;
        item passed : "all generated cases pass";

        flow from property to generate;
        flow from generate to check;
        flow from property to check;
        flow from check to outcome;
        flow from outcome to passed : "all pass";
        flow from outcome to shrink : "a case fails";
        flow from shrink to report;
    }

    view diagram : FpActivityView {
        doc /* Property tests generate cases and shrink failures */
        expose PropertyWorkflow;
        render fpActivityDiagram;
    }
}
