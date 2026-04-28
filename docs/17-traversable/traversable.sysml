// SysML v2 — traversable activity diagram
// Concept: traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)
// Diagram type: activity — effectful map function flows in as HOF token

package TraversableActivity {

    action def TraverseOp {
        in  f   : "a ⟶ Fb";  // effectful mapping fn, HOF input
        in  ta  : Ta;           // traversable container of a's
        out ftb : "F(Tb)";     // effects collected, T shape kept
    }

    action def SequenceOp {
        in  tfa : ContainerFA;   // T(Fa)
        out fta : EffectContA;   // F(Ta)
    }

    activity def TraverseProcess {
        // HOF input: effectful mapping function
        object f   : "a ⟶ Fb";  // effectful mapping fn
        object ta  : Ta;           // traversable container of a's
        action trav : TraverseOp;
        object ftb : "F(Tb)";     // effects collected, T shape kept

        flow from f   to trav;
        flow from ta  to trav;
        flow from trav to ftb;
    }

    activity def SequenceProcess {
        object tfa : ContainerFA;      // T(Fa) — container of effects
        action seq : SequenceOp;
        object fta : EffectContA;      // F(Ta) — single effect wrapping T

        flow from tfa to seq;
        flow from seq to fta;
    }
}

#diagram {
    type  = activity
    title = "traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)"
    name  = "traverse"
    render = TraverseProcess
    show f    as hof
    show ta   as type
    show trav as function
    show ftb  as type
    tooltip f    = "(a ⟶ Fb) — effectful mapping fn, received as a data token (HOF)"
    tooltip ta   = "Ta — traversable container of a's"
    tooltip trav = "traverse: maps each element with f, collects effects into outer F"
    tooltip ftb  = "F(Tb) — container shape T preserved; all effects F collected"
}
