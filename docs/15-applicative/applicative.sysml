// SysML v2 — applicative <*> activity diagram
// Concept: (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb
// Diagram type: activity — wrapped function flows in as HOF token, applied to Fa

package ApplicativeActivity {
    private import FpDiagram::*;

    action def ApplyWrapped {
        in  fff : "F(a ⟶ b)";  // wrapped function, HOF input
        in  fa  : Fa;             // wrapped argument
        out fb  : Fb;             // result in context
    }

    action def PureOp {
        in  x  : a;   // plain value
        out fa : Fa;  // lifted into context
    }

    action def ApplicativeProcess {
        // HOF input: the wrapped function flowing in as a data token
        #FpNodePresentation { role = "hof"; tooltip = "F(a ⟶ b) — a function wrapped in context F, flowing in as a value (HOF)"; }
        item fff  : "F(a ⟶ b)";  // wrapped function, HOF input
        #FpNodePresentation { role = "type"; tooltip = "Fa — the argument value, also wrapped in the same context F"; }
        item fa   : Fa;             // argument in same context

        #FpNodePresentation { role = "function"; tooltip = "(<*>) — applies the wrapped function to the wrapped argument"; }

        action apStar : ApplyWrapped;

        #FpNodePresentation { role = "type"; tooltip = "Fb — result in context F; same context shape as input"; }

        item fb   : Fb;             // result in context

        flow from fff  to apStar;
        flow from fa   to apStar;
        flow from apStar to fb;
    }

    action def PureProcess {
        item x  : a;    // plain value
        action pur : PureOp;
        #FpNodePresentation { role = "type"; tooltip = "Fa — the argument value, also wrapped in the same context F"; }
        item fa : Fa;   // lifted into context

        flow from x   to pur;
        flow from pur to fa;
    }
    #FpViewPresentation { name = "<*>"; }
    view diagram : FpActivityView {
        doc /*Applicative: (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb*/
        expose ApplicativeProcess;
        render fpActivityDiagram;
    }
}

