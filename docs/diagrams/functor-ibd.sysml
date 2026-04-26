// SysML v2 — functor IBD: type signature
// fmap :: (a ⟶ b) ⟶ Fa ⟶ Fb

package FunctorSignature {

    part def FmapContext {
        // inputs
        part f_val  : "a ⟶ b";  // plain function, HOF argument
        part fa_val : Fa;          // value in context F

        // the operation
        part fmap   : FmapOp;

        // output
        part fb_val : Fb;          // result in context F

        connection connect f_val  to fmap;
        connection connect fa_val to fmap;
        connection connect fmap   to fb_val;
    }
}

#diagram {
    type  = ibd
    title = "fmap :: (a ⟶ b) ⟶ Fa ⟶ Fb"
    render = FmapContext
    show f_val  as hof
    show fa_val as type
    show fmap   as function
    show fb_val as type
    tooltip f_val  = "(a ⟶ b) — plain function, flowing in as a structural argument"
    tooltip fa_val = "Fa — value inside the functor context"
    tooltip fmap   = "fmap: lifts a plain function to operate inside the functor"
    tooltip fb_val = "Fb — result inside the same functor context"
}
