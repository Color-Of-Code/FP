// SysML v2 — traversable activity diagram
// Concept: traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)
// Diagram type: activity — effectful map function flows in as HOF token

package TraversableActivity {
    private import FpDiagram::*;

    action def TraverseOp {
        in  f   : "a ⟶ Fb";  // effectful mapping fn, HOF input
        in  ta  : Ta;           // traversable container of a's
        out ftb : "F(Tb)";     // effects collected, T shape kept
    }

    action def SequenceOp {
        in  tfa : ContainerFA;   // T(Fa)
        out fta : EffectContA;   // F(Ta)
    }

    action def TraverseProcess {
        // HOF input: effectful mapping function
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Fb) — effectful mapping fn, received as a data token (HOF)"; }
        item f   : "a ⟶ Fb";  // effectful mapping fn
        #FpNodePresentation { role = "type"; tooltip = "Ta — traversable container of a's"; }
        item ta  : Ta;           // traversable container of a's
        #FpNodePresentation { role = "function"; tooltip = "traverse: maps each element with f, collects effects into outer F"; }
        action trav : TraverseOp;
        #FpNodePresentation { role = "type"; tooltip = "F(Tb) — container shape T preserved; all effects F collected"; }
        item ftb : "F(Tb)";     // effects collected, T shape kept

        flow from f   to trav;
        flow from ta  to trav;
        flow from trav to ftb;
    }

    action def SequenceProcess {
        item tfa : ContainerFA;      // T(Fa) — container of effects
        action seq : SequenceOp;
        item fta : EffectContA;      // F(Ta) — single effect wrapping T

        flow from tfa to seq;
        flow from seq to fta;
    }
    #FpViewPresentation { name = "traverse"; }
    view diagram : FpActivityView {
        doc /*traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)*/
        expose TraverseProcess;
        render fpActivityDiagram;
    }
}

