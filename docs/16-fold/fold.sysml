// SysML v2 — fold activity diagram
// Concept: fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ List<a> ⟶ b
// Diagram type: activity — shows data token flow through repeated application of f

package FoldActivity {

    // ── action signatures ──────────────────────────────────────────────────
    action def ApplyStep {
        in  b    : b;               // accumulator
        in  a    : a;               // current element
        in  f    : "b ⟶ a ⟶ b";  // combiner fn, HOF input
        out bOut : B;
    }

    // ── main activity ──────────────────────────────────────────────────────
    activity def FoldProcess {
        // HOF input: the combiner function — flows in as a data token
        object f  : "b ⟶ a ⟶ b";  // combiner fn, HOF input

        // initial accumulator and list elements
        object b0 : b;  // initial accumulator
        object a1 : a;  // first element
        object a2 : a;
        object a3 : a;

        // step actions — each applies f to accumulator + next element
        action step1 : ApplyStep;
        action step2 : ApplyStep;
        action step3 : ApplyStep;

        // intermediate and final accumulator values
        object b1 : b;
        object b2 : b;
        object b3 : b;  // fold result

        // data flows: object tokens flow into actions and out as results
        flow from f  to step1;
        flow from b0 to step1;
        flow from a1 to step1;
        flow from step1 to b1;

        flow from f  to step2;
        flow from b1 to step2;
        flow from a2 to step2;
        flow from step2 to b2;

        flow from f  to step3;
        flow from b2 to step3;
        flow from a3 to step3;
        flow from step3 to b3;

        // control flow: steps execute sequentially
        succession step1 then step2;
        succession step2 then step3;
    }
}

#diagram {
    type      = activity
    title     = "fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ List<a> ⟶ b"
    name      = "fold"
    direction = TB
    show f     as hof
    show b0    as value
    show a1    as value
    show a2    as value
    show a3    as value
    show b1    as value
    show b2    as value
    show b3    as value
    show step1 as function
    show step2 as function
    show step3 as function
    tooltip f     = "(b ⟶ a ⟶ b) — the combining function, passed as a token (HOF input)"
    tooltip step1 = "Apply f to b0 and a1 → b1"
    tooltip step2 = "Apply f to b1 and a2 → b2"
    tooltip step3 = "Apply f to b2 and a3 → b3 (final result)"
}
