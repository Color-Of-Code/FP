package TaglessFinal {
    private import FpDiagram::*;

    action def InterpretProduction {
        in  program : "forall F. Algebra F => F Result";
        out result : "IO Result";
    }

    action def InterpretTest {
        in  program : "forall F. Algebra F => F Result";
        out result : "State Log Result";
    }

    action def ProgramInterpretations {
        #FpNodePresentation { role = "function"; tooltip = "One polymorphic program describes the required algebra, not a concrete effect."; }
        item program : "forall F. Algebra F => F Result";
        #FpNodePresentation { role = "function"; tooltip = "Choose IO-backed instances for production."; }
        action production : InterpretProduction;
        item ioResult : "IO Result";
        #FpNodePresentation { role = "function"; tooltip = "Choose a pure state-backed interpreter for tests."; }
        action test : InterpretTest;
        item testResult : "State Log Result";

        flow from program to production;
        flow from production to ioResult;
        flow from program to test;
        flow from test to testResult;
    }

    #FpViewPresentation { name = "tagless final"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*tagless final*/
        expose ProgramInterpretations;
        render fpActivityDiagram;
    }
}
