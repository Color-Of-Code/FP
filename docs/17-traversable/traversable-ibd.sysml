// SysML v2 — traversable IBD: type signature
// traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)

package TraversableSignature {
    private import FpDiagram::*;

    part def TraverseContext {
        // inputs
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Fb) — effectful mapper applied to each element"; }
        part f_val  : "a ⟶ Fb";  // effectful mapper, HOF argument
        #FpNodePresentation { role = "type"; tooltip = "Ta — traversable structure containing elements of type a"; }
        part ta_val : Ta;           // traversable structure holding a

        // the operation
        #FpNodePresentation { role = "function"; tooltip = "traverse: map with effects, collecting results into F(Tb)"; }
        part traverse : TraverseOp;

        // output
        #FpNodePresentation { role = "type"; tooltip = "F(Tb) — effect on the outside, rebuilt structure on the inside"; }
        part ftb_val  : "F(Tb)";   // effect outside, structure inside

        connection connect f_val   to traverse;
        connection connect ta_val  to traverse;
        connection connect traverse to ftb_val;
    }
    view diagram : FpIbdView {
        doc /*traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)*/
        expose TraverseContext;
        render fpIbdDiagram;
    }
}

