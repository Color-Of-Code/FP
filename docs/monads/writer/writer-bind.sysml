// SysML v2 — Writer bind: implementation activity
// Shows the three steps: extract a+w1, apply f→(b,w2), combine logs w1<>w2.
// w1 (first log fragment) flows AROUND apply directly to combine — it must not be lost.

package WriterBindImpl {
    private import FpDiagram::*;

    action def ExtractPair {
        in  wa    : "(a, w1)";
        out a_val : a;
        out w1    : w;         // first log fragment, bypasses apply
    }

    action def ApplyF {
        in  a_val : a;
        in  f     : "a ⟶ (b, w2)";
        out b_val : b;
        out w2    : w;         // second log fragment, produced by f(a)
    }

    action def CombineLogs {
        in  b_val  : b;
        in  w1     : w;        // from extract — NOT from apply
        in  w2     : w;        // from apply
        out result : "(b, w1<>w2)";
    }

    action def WriterBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "(a, w1) — result a paired with the first log fragment w1"; }
        item wa      : "(a, w1)";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ (b, w2)) — the continuation; produces result b AND a new log fragment w2"; }
        item f       : "a ⟶ (b, w2)";
        #FpNodePresentation { role = "function"; tooltip = "Pattern-match the pair: extract a (for f) and w1 (for the log combiner)"; }
        action extract : ExtractPair;
        #FpNodePresentation { role = "value"; tooltip = "a — the value to pass to f"; }
        item a_val   : a;
        #FpNodePresentation { role = "value"; tooltip = "w — the first log fragment. Flows DIRECTLY to combine, bypassing apply. It must not be dropped."; }
        item w1      : w;              // first log fragment: bypasses f
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a): produces (b, w2) — the result value b and a new log fragment w2"; }
        action apply   : ApplyF;
        #FpNodePresentation { role = "value"; tooltip = "b — the result value from f(a)"; }
        item b_val   : b;
        #FpNodePresentation { role = "value"; tooltip = "w — the second log fragment, produced by f(a). Combined with w1 from the first step."; }
        item w2      : w;              // second log fragment: produced by f
        #FpNodePresentation { role = "function"; tooltip = "Return (b, w1 <> w2) — result b with both log fragments combined using monoid append"; }
        action combine : CombineLogs;
        #FpNodePresentation { role = "type"; tooltip = "(b, w1<>w2) — the final result: value b and the complete accumulated log"; }
        item result  : "(b, w1<>w2)";

        flow from wa       to extract;
        flow from extract  to a_val;
        flow from extract  to w1;        // w1 flows around apply to combine
        flow from a_val    to apply;
        flow from f        to apply;
        flow from apply    to b_val;
        flow from apply    to w2;
        flow from b_val    to combine;
        flow from w1       to combine;   // w1 meets w2 here
        flow from w2       to combine;
        flow from combine  to result;

        succession extract then apply;
        succession apply   then combine;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*Writer bind: extract a+w1, apply f→(b,w2), combine logs w1<>w2 — also called: flatMap, >>=*/
        expose WriterBindProcess;
        render fpActivityDiagram;
    }
}

