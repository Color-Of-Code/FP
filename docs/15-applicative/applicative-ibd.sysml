// SysML v2 — applicative IBD: type signature
// (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb

package ApplicativeSignature {

    part def ApContext {
        // inputs
        part ff_val : "F(a ⟶ b)";  // function lifted into context
        part fa_val : Fa;              // value inside context

        // the operation
        part ap     : ApOp;

        // output
        part fb_val : Fb;

        connection connect ff_val to ap;
        connection connect fa_val to ap;
        connection connect ap     to fb_val;
    }
}

#diagram {
    type  = ibd
    title = "(<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb"
    render = ApContext
    show ff_val as hof
    show fa_val as type
    show ap     as function
    show fb_val as type
    tooltip ff_val = "F(a ⟶ b) — a function already lifted into the applicative context"
    tooltip fa_val = "Fa — value inside the same context F"
    tooltip ap     = "<*>: applies a wrapped function to a wrapped value"
    tooltip fb_val = "Fb — result in context F"
}
