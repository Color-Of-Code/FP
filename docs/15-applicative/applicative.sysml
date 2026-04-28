// SysML v2 — applicative <*> activity diagram
// Concept: (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb
// Diagram type: activity — wrapped function flows in as HOF token, applied to Fa

package ApplicativeActivity {

    action def ApplyWrapped {
        in  fff : "F(a ⟶ b)";  // wrapped function, HOF input
        in  fa  : Fa;             // wrapped argument
        out fb  : Fb;             // result in context
    }

    action def PureOp {
        in  x  : a;   // plain value
        out fa : Fa;  // lifted into context
    }

    activity def ApplicativeProcess {
        // HOF input: the wrapped function flowing in as a data token
        object fff  : "F(a ⟶ b)";  // wrapped function, HOF input
        object fa   : Fa;             // argument in same context

        action apStar : ApplyWrapped;

        object fb   : Fb;             // result in context

        flow from fff  to apStar;
        flow from fa   to apStar;
        flow from apStar to fb;
    }

    activity def PureProcess {
        object x  : a;    // plain value
        action pur : PureOp;
        object fa : Fa;   // lifted into context

        flow from x   to pur;
        flow from pur to fa;
    }
}

#diagram {
    type  = activity
    title = "Applicative: (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb"
    name  = "<*>"
    render = ApplicativeProcess
    show fff    as hof
    show fa     as type
    show apStar as function
    show fb     as type
    tooltip fff    = "F(a ⟶ b) — a function wrapped in context F, flowing in as a value (HOF)"
    tooltip fa     = "Fa — the argument value, also wrapped in the same context F"
    tooltip apStar = "(<*>) — applies the wrapped function to the wrapped argument"
    tooltip fb     = "Fb — result in context F; same context shape as input"
}
