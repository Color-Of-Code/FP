// SysML v2 — Parser alt (<|>): implementation activity
// (<|>) :: Parser a ⟶ Parser a ⟶ Parser a
//
// Try parser p1 on the input.  If it succeeds, return its result.  If it
// fails (without consuming input, by convention), back-track and try p2.
// Provides ordered choice — the canonical way to express grammar
// alternatives.

package ParserAltImpl {
    private import FpDiagram::*;

    action def Alt {
        in  p1 : "Parser a";
        in  p2 : "Parser a";
        out pr : "Parser a";
    }

    action def ParserAltProcess {
        #FpNodePresentation { role = "value"; tooltip = "p1 : Parser a — primary alternative.  If it succeeds (or consumes input then fails, depending on the parser library), its result wins."; }
        item p1 : "Parser a";
        #FpNodePresentation { role = "value"; tooltip = "p2 : Parser a — fallback alternative.  Tried only when p1 fails without commitment."; }
        item p2 : "Parser a";
        #FpNodePresentation { role = "function"; tooltip = "Alt: build \\input -> case p1 input of Just r -> Just r; Nothing -> p2 input."; }
        action alt : Alt;
        #FpNodePresentation { role = "type"; tooltip = "Parser a — combined parser that succeeds whenever either branch succeeds.  Used to encode grammar disjunction (rule = a | b)."; }
        item pr : "Parser a";

        flow from p1  to alt;
        flow from p2  to alt;
        flow from alt to pr : "run p1; on failure, run p2";
    }
    #FpViewPresentation { name = "alt"; }
    view diagram : FpActivityView {
        doc /*(<|>) :: Parser a ⟶ Parser a ⟶ Parser a   (ordered choice; try p1, on failure try p2) — also called: alt, choice, orElse*/
        expose ParserAltProcess;
        render fpActivityDiagram;
    }
}

