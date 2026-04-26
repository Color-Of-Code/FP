// SysML v2 — Writer bind: implementation activity
// Shows the three steps: extract a+w1, apply f→(b,w2), combine logs w1<>w2.
// w1 (first log fragment) flows AROUND apply directly to combine — it must not be lost.

package WriterBindImpl {

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

    activity def WriterBindProcess {
        object wa      : "(a, w1)";
        object f       : "a ⟶ (b, w2)";
        action extract : ExtractPair;
        object a_val   : a;
        object w1      : w;              // first log fragment: bypasses f
        action apply   : ApplyF;
        object b_val   : b;
        object w2      : w;              // second log fragment: produced by f
        action combine : CombineLogs;
        object result  : "(b, w1<>w2)";

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
}

#diagram {
    type  = activity
    title = "Writer bind: extract a+w1, apply f→(b,w2), combine logs w1<>w2"
    name  = ">>="
    show wa      as type
    show f       as hof
    show extract as function
    show a_val   as value
    show w1      as value
    show apply   as function
    show b_val   as value
    show w2      as value
    show combine as function
    show result  as type
    tooltip wa      = "(a, w1) — result a paired with the first log fragment w1"
    tooltip f       = "(a ⟶ (b, w2)) — the continuation; produces result b AND a new log fragment w2"
    tooltip extract = "Pattern-match the pair: extract a (for f) and w1 (for the log combiner)"
    tooltip a_val   = "a — the value to pass to f"
    tooltip w1      = "w — the first log fragment. Flows DIRECTLY to combine, bypassing apply. It must not be dropped."
    tooltip apply   = "Apply f(a): produces (b, w2) — the result value b and a new log fragment w2"
    tooltip b_val   = "b — the result value from f(a)"
    tooltip w2      = "w — the second log fragment, produced by f(a). Combined with w1 from the first step."
    tooltip combine = "Return (b, w1 <> w2) — result b with both log fragments combined using monoid append"
    tooltip result  = "(b, w1<>w2) — the final result: value b and the complete accumulated log"
}
