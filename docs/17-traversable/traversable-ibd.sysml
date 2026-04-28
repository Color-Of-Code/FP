// SysML v2 — traversable IBD: type signature
// traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)

package TraversableSignature {

    part def TraverseContext {
        // inputs
        part f_val  : "a ⟶ Fb";  // effectful mapper, HOF argument
        part ta_val : Ta;           // traversable structure holding a

        // the operation
        part traverse : TraverseOp;

        // output
        part ftb_val  : "F(Tb)";   // effect outside, structure inside

        connection connect f_val   to traverse;
        connection connect ta_val  to traverse;
        connection connect traverse to ftb_val;
    }
}

#diagram {
    type  = ibd
    title = "traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)"
    render = TraverseContext
    show f_val    as hof
    show ta_val   as type
    show traverse as function
    show ftb_val  as type
    tooltip f_val    = "(a ⟶ Fb) — effectful mapper applied to each element"
    tooltip ta_val   = "Ta — traversable structure containing elements of type a"
    tooltip traverse = "traverse: map with effects, collecting results into F(Tb)"
    tooltip ftb_val  = "F(Tb) — effect on the outside, rebuilt structure on the inside"
}
