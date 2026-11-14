// SysML v2 — applicative IBD: type signature
// (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb

package ApplicativeSignature {
    private import FpDiagram::*;

    part def ApContext {
        // inputs
        #FpNodePresentation { role = "hof"; tooltip = "F(a ⟶ b) — a function already lifted into the applicative context"; }
        part ff_val : "F(a ⟶ b)";  // function lifted into context
        #FpNodePresentation { role = "type"; tooltip = "Fa — value inside the same context F"; }
        part fa_val : Fa;              // value inside context

        // the operation
        #FpNodePresentation { role = "function"; tooltip = "<*>: applies a wrapped function to a wrapped value"; }
        part ap     : ApOp;

        // output
        #FpNodePresentation { role = "type"; tooltip = "Fb — result in context F"; }
        part fb_val : Fb;

        connection connect ff_val to ap;
        connection connect fa_val to ap;
        connection connect ap     to fb_val;
    }
    view diagram : FpIbdView {
        doc /*(<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb*/
        expose ApContext;
        render fpIbdDiagram;
    }
}

