// SysML v2 — applicative: fmap (for comparison) and pure

package ApplicativeFmapPure {

    action def FmapOp {
        in  f  : "a ⟶ b";  // plain function, HOF input
        in  fa : Fa;          // wrapped argument
        out fb : Fb;          // result in context
    }

    action def PureOp {
        in  x  : a;   // plain value
        out fa : Fa;  // lifted into context
    }

    activity def FmapProcess {
        object f    : "a ⟶ b";  // plain function, NOT wrapped
        object Fa   : Fa;          // value in context
        action fmapF : FmapOp;
        object Fb   : Fb;          // result in context

        flow from f    to fmapF;
        flow from Fa   to fmapF;
        flow from fmapF to Fb;
    }

    activity def PureProcess {
        object x  : a;    // plain value
        action pur : PureOp;
        object Fa : Fa;   // lifted into context

        flow from x   to pur;
        flow from pur to Fa;
    }
}

#diagram {
    type   = activity
    title  = "fmap :: (a ⟶ b) ⟶ Fa ⟶ Fb  |  pure :: a ⟶ Fa"
    name   = "fmap"
    render = FmapProcess
    show f     as hof
    show Fa    as type
    show fmapF as function
    show Fb    as type
    tooltip f     = "(a ⟶ b) — a plain function (contrast: Applicative wraps the function too)"
    tooltip Fa    = "Fa — value inside context F"
    tooltip fmapF = "fmap: lifts a plain function into the functor"
    tooltip Fb    = "Fb — result inside context F"
}
