// SysML v2 — applicative: fmap (for comparison) and pure

package ApplicativeFmapPure {
    private import FpDiagram::*;

    action def FmapOp {
        in  f  : "a ⟶ b";  // plain function, HOF input
        in  fa : Fa;          // wrapped argument
        out fb : Fb;          // result in context
    }

    action def PureOp {
        in  x  : a;   // plain value
        out fa : Fa;  // lifted into context
    }

    action def FmapProcess {
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ b) — a plain function (contrast: Applicative wraps the function too)"; }
        item f    : "a ⟶ b";  // plain function, NOT wrapped
        #FpNodePresentation { role = "type"; tooltip = "Fa — value inside context F"; }
        item Fa   : Fa;          // value in context
        #FpNodePresentation { role = "function"; tooltip = "fmap: lifts a plain function into the functor"; }
        action fmapF : FmapOp;
        #FpNodePresentation { role = "type"; tooltip = "Fb — result inside context F"; }
        item Fb   : Fb;          // result in context

        flow from f    to fmapF;
        flow from Fa   to fmapF;
        flow from fmapF to Fb;
    }

    action def PureProcess {
        item x  : a;    // plain value
        action pur : PureOp;
        #FpNodePresentation { role = "type"; tooltip = "Fa — value inside context F"; }
        item Fa : Fa;   // lifted into context

        flow from x   to pur;
        flow from pur to Fa;
    }
    #FpViewPresentation { name = "fmap"; }
    view diagram : FpActivityView {
        doc /*fmap :: (a ⟶ b) ⟶ Fa ⟶ Fb  |  pure :: a ⟶ Fa*/
        expose FmapProcess;
        render fpActivityDiagram;
    }
}

