// SysML v2 — fold IBD: type signature
// fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ [a] ⟶ b
// Four wires: HOF f, initial accumulator b, input list [a], output b

package FoldSignature {
    private import FpDiagram::*;

    part def FoldContext {
        // inputs
        #FpNodePresentation { role = "hof"; tooltip = "(b ⟶ a ⟶ b) — combining function: takes accumulator and element, returns new accumulator"; }
        part f_val    : "b ⟶ a ⟶ b";  // combining function (HOF)
        #FpNodePresentation { role = "value"; tooltip = "b — initial accumulator value (the \"zero\" of the fold)"; }
        part init_val : b;                // initial accumulator
        #FpNodePresentation { role = "type"; tooltip = "[a] — the input list whose elements are consumed one by one"; }
        part list_val : "[a]";            // input list

        // the operation
        #FpNodePresentation { role = "function"; tooltip = "fold: reduce a list to a single value by repeatedly applying f"; }
        part fold     : FoldOp;

        // output
        #FpNodePresentation { role = "value"; tooltip = "b — the final accumulated result"; }
        part result   : b;                // final accumulated value

        connection connect f_val    to fold;
        connection connect init_val to fold;
        connection connect list_val to fold;
        connection connect fold     to result;
    }
    view diagram : FpIbdView {
        doc /*fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ [a] ⟶ b*/
        expose FoldContext;
        render fpIbdDiagram;
    }
}

