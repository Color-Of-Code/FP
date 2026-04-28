// SysML v2 — Parser pure: implementation activity
// pure :: a ⟶ Parser a   ≡   pure a = \input -> Just (a, input)
//
// Build a parser that succeeds without consuming any input. The unparsed
// remainder is returned unchanged together with the lifted value a.
// This is the identity parser: it matches the empty string.

package ParserPureImpl {

    action def NullParse {
        in  a  : a;
        out pa : "Parser a";   // = \input -> Just (a, input)
    }

    activity def ParserPureProcess {
        object a0   : a;
        action wrap : NullParse;
        object pa   : "Parser a";

        flow from a0   to wrap;
        flow from wrap to pa : "\\input -> Just (a0, input)";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ Parser a   (succeed with a0, consume nothing) — also called: return, succeed"
    name  = "pure"
    show a0   as value
    show wrap as function
    show pa   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "NullParse: build the parser \\input -> Just (a0, input). Always succeeds; remainder = input."
    tooltip pa   = "Parser a — a parser that matches the empty prefix. Combined with bind, it threads the same remainder forward."
}
