// SysML v2 — traversable: sequence :: T(Fa) ⟶ F(Ta)

package TraversableSequence {
    private import FpDiagram::*;

    action def SequenceOp {
        in  tfa : "T(Fa)";  // container of effects
        out fta : "F(Ta)";  // single effect wrapping container
    }

    action def SequenceProcess {
        #FpNodePresentation { role = "type"; tooltip = "T(Fa) — a container of effects (e.g. [Maybe a, Maybe a, ...])"; }
        item Tfa : "T(Fa)";  // container of effects
        #FpNodePresentation { role = "function"; tooltip = "sequence: swaps T and F — collects all effects into one outer F"; }
        action seq : SequenceOp;
        #FpNodePresentation { role = "type"; tooltip = "F(Ta) — one effect wrapping the whole container (e.g. Maybe [a, a, ...])"; }
        item Fta : "F(Ta)";  // single effect wrapping container

        flow from Tfa to seq;
        flow from seq to Fta;
    }
    #FpViewPresentation { name = "sequence"; }
    view diagram : FpActivityView {
        doc /*sequence :: T(Fa) ⟶ F(Ta)  (= traverse id)*/
        expose SequenceProcess;
        render fpActivityDiagram;
    }
}

