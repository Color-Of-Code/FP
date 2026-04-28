// SysML v2 — traversable: sequence :: T(Fa) ⟶ F(Ta)

package TraversableSequence {

    action def SequenceOp {
        in  tfa : "T(Fa)";  // container of effects
        out fta : "F(Ta)";  // single effect wrapping container
    }

    activity def SequenceProcess {
        object Tfa : "T(Fa)";  // container of effects
        action seq : SequenceOp;
        object Fta : "F(Ta)";  // single effect wrapping container

        flow from Tfa to seq;
        flow from seq to Fta;
    }
}

#diagram {
    type   = activity
    title  = "sequence :: T(Fa) ⟶ F(Ta)  (= traverse id)"
    name   = "sequence"
    show Tfa as type
    show seq as function
    show Fta as type
    tooltip Tfa = "T(Fa) — a container of effects (e.g. [Maybe a, Maybe a, ...])"
    tooltip seq = "sequence: swaps T and F — collects all effects into one outer F"
    tooltip Fta = "F(Ta) — one effect wrapping the whole container (e.g. Maybe [a, a, ...])"
}
