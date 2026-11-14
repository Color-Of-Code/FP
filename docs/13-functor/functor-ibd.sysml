// SysML v2 — functor IBD: type signature
// fmap :: (a ⟶ b) ⟶ Fa ⟶ Fb

package FunctorSignature {
    private import FpDiagram::*;

    part def FmapContext {
        // inputs
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ b) — plain function, flowing in as a structural argument"; }
        part f_val  : "a ⟶ b";  // plain function, HOF argument
        #FpNodePresentation { role = "type"; tooltip = "Fa — value inside the functor context"; }
        part fa_val : Fa;          // value in context F

        // the operation
        #FpNodePresentation { role = "function"; tooltip = "fmap: lifts a plain function to operate inside the functor"; }
        part fmap   : FmapOp;

        // output
        #FpNodePresentation { role = "type"; tooltip = "Fb — result inside the same functor context"; }
        part fb_val : Fb;          // result in context F

        connection connect f_val  to fmap;
        connection connect fa_val to fmap;
        connection connect fmap   to fb_val;
    }
    view diagram : FpIbdView {
        doc /*fmap :: (a ⟶ b) ⟶ Fa ⟶ Fb*/
        expose FmapContext;
        render fpIbdDiagram;
    }
}

