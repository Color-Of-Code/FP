// SysML v2 — Writer monad IBD: type signature + bind contract
// (>>=) :: (a, w1) ⟶ (a ⟶ (b, w2)) ⟶ (b, w1<>w2)
//
// The output type label (b, w1<>w2) makes the log accumulation visible in the
// structure itself — w1 from the first step and w2 from f(a) are combined with
// the monoid append operation (<>).

package WriterSignature {
    private import FpDiagram::*;

    part def WriterBindContext {
        #FpNodePresentation { role = "type"; tooltip = "(a, w1) — a result value a paired with a log fragment w1"; }
        part ma_val : "(a, w1)";        // result paired with first log fragment
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ (b, w2)) — given a, produces result b alongside a new log fragment w2"; }
        part f_val  : "a ⟶ (b, w2)";  // effectful function (HOF) — produces log w2
        #FpNodePresentation { role = "function"; tooltip = "extract a from (a, w1)\napply f(a) to get (b, w2)\nreturn (b, w1 <> w2)  ← logs combined with monoid append"; }
        part bind   : WriterBindOp;
        #FpNodePresentation { role = "type"; tooltip = "(b, w1<>w2) — result b with the complete log: w1 from the first step appended with w2 from f"; }
        part mb_val : "(b, w1<>w2)";   // result with both log fragments combined

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: (a, w1) ⟶ (a ⟶ (b, w2)) ⟶ (b, w1<>w2) — also called: flatMap, >>=*/
        expose WriterBindContext;
        render fpIbdDiagram;
    }
}

