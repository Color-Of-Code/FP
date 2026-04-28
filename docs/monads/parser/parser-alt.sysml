// SysML v2 — Parser alt (<|>): implementation activity
// (<|>) :: Parser a ⟶ Parser a ⟶ Parser a
//
// Try parser p1 on the input.  If it succeeds, return its result.  If it
// fails (without consuming input, by convention), back-track and try p2.
// Provides ordered choice — the canonical way to express grammar
// alternatives.

package ParserAltImpl {

    action def Alt {
        in  p1 : "Parser a";
        in  p2 : "Parser a";
        out pr : "Parser a";
    }

    activity def ParserAltProcess {
        object p1 : "Parser a";
        object p2 : "Parser a";
        action alt : Alt;
        object pr : "Parser a";

        flow from p1  to alt;
        flow from p2  to alt;
        flow from alt to pr : "run p1; on failure, run p2";
    }
}

#diagram {
    type  = activity
    title = "(<|>) :: Parser a ⟶ Parser a ⟶ Parser a   (ordered choice; try p1, on failure try p2) — also called: alt, choice, orElse"
    name  = "alt"
    show p1  as value
    show p2  as value
    show alt as function
    show pr  as type
    tooltip p1  = "p1 : Parser a — primary alternative.  If it succeeds (or consumes input then fails, depending on the parser library), its result wins."
    tooltip p2  = "p2 : Parser a — fallback alternative.  Tried only when p1 fails without commitment."
    tooltip alt = "Alt: build \\input -> case p1 input of Just r -> Just r; Nothing -> p2 input."
    tooltip pr  = "Parser a — combined parser that succeeds whenever either branch succeeds.  Used to encode grammar disjunction (rule = a | b)."
}
