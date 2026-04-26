// SysML v2 — fold IBD: type signature
// fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ [a] ⟶ b
// Four wires: HOF f, initial accumulator b, input list [a], output b

package FoldSignature {

    part def FoldContext {
        // inputs
        part f_val    : "b ⟶ a ⟶ b";  // combining function (HOF)
        part init_val : b;                // initial accumulator
        part list_val : "[a]";            // input list

        // the operation
        part fold     : FoldOp;

        // output
        part result   : b;                // final accumulated value

        connection connect f_val    to fold;
        connection connect init_val to fold;
        connection connect list_val to fold;
        connection connect fold     to result;
    }
}

#diagram {
    type  = ibd
    title = "fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ [a] ⟶ b"
    render = FoldContext
    show f_val    as hof
    show init_val as value
    show list_val as type
    show fold     as function
    show result   as value
    tooltip f_val    = "(b ⟶ a ⟶ b) — combining function: takes accumulator and element, returns new accumulator"
    tooltip init_val = "b — initial accumulator value (the \"zero\" of the fold)"
    tooltip list_val = "[a] — the input list whose elements are consumed one by one"
    tooltip fold     = "fold: reduce a list to a single value by repeatedly applying f"
    tooltip result   = "b — the final accumulated result"
}
