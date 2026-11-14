// SysML v2 — Parser pure: implementation activity
// pure :: a ⟶ Parser a   ≡   pure a = \input -> Just (a, input)
//
// Build a parser that succeeds without consuming any input. The unparsed
// remainder is returned unchanged together with the lifted value a.
// This is the identity parser: it matches the empty string.

package ParserPureImpl {
    private import FpDiagram::*;

    action def NullParse {
        in  a  : a;
        out pa : "Parser a";   // = \input -> Just (a, input)
    }

    action def ParserPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0   : a;
        #FpNodePresentation { role = "function"; tooltip = "NullParse: build the parser \\input -> Just (a0, input). Always succeeds; remainder = input."; }
        action wrap : NullParse;
        #FpNodePresentation { role = "type"; tooltip = "Parser a — a parser that matches the empty prefix. Combined with bind, it threads the same remainder forward."; }
        item pa   : "Parser a";

        flow from a0   to wrap;
        flow from wrap to pa : "\\input -> Just (a0, input)";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Parser a   (succeed with a0, consume nothing) — also called: return, succeed*/
        expose ParserPureProcess;
        render fpActivityDiagram;
    }
}

