// SysML v2 — fold activity diagram
// Concept: fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ List<a> ⟶ b
// Diagram type: activity — shows data token flow through repeated application of f

package FoldActivity {
    private import FpDiagram::*;

    // ── action signatures ──────────────────────────────────────────────────
    action def ApplyStep {
        in  b    : b;               // accumulator
        in  a    : a;               // current element
        in  f    : "b ⟶ a ⟶ b";  // combiner fn, HOF input
        out bOut : B;
    }

    // ── main activity ──────────────────────────────────────────────────────
    action def FoldProcess {
        // HOF input: the combiner function — flows in as a data token
        #FpNodePresentation { role = "hof"; tooltip = "(b ⟶ a ⟶ b) — the combining function, passed as a token (HOF input)"; }
        item f  : "b ⟶ a ⟶ b";  // combiner fn, HOF input

        // initial accumulator and list elements
        #FpNodePresentation { role = "value"; }
        item b0 : b;  // initial accumulator
        #FpNodePresentation { role = "value"; }
        item a1 : a;  // first element
        #FpNodePresentation { role = "value"; }
        item a2 : a;
        #FpNodePresentation { role = "value"; }
        item a3 : a;

        // step actions — each applies f to accumulator + next element
        #FpNodePresentation { role = "function"; tooltip = "Apply f to b0 and a1 → b1"; }
        action step1 : ApplyStep;
        #FpNodePresentation { role = "function"; tooltip = "Apply f to b1 and a2 → b2"; }
        action step2 : ApplyStep;
        #FpNodePresentation { role = "function"; tooltip = "Apply f to b2 and a3 → b3 (final result)"; }
        action step3 : ApplyStep;

        // intermediate and final accumulator values
        #FpNodePresentation { role = "value"; }
        item b1 : b;
        #FpNodePresentation { role = "value"; }
        item b2 : b;
        #FpNodePresentation { role = "value"; }
        item b3 : b;  // fold result

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
    #FpViewPresentation { name = "fold"; direction = "TB"; }
    view diagram : FpActivityView {
        doc /*fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ List<a> ⟶ b*/
        expose FoldProcess;
        render fpActivityDiagram;
    }
}

