// SysML v2 — Parser monad IBD: type signature + bind contract
// (>>=) :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b
//
// Parser a = String ⟶ Maybe (a, String)
// The extra node rest shows the key structural difference: the remaining input
// is threaded from the first parser into f(a), just as the state threads in
// the State monad — each step consumes a prefix and passes the remainder forward.

package ParserSignature {
    private import FpDiagram::*;

    part def ParserBindContext {
        #FpNodePresentation { role = "type"; tooltip = "Parser a = String ⟶ Maybe (a, String) — run on input; succeeds with (a, rest) or fails with Nothing"; }
        part pa_val : "Parser a";        // String ⟶ Maybe (a, String)
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Parser b) — given parsed value a, constructs the next parser (runs on the remaining input)"; }
        part f_val  : "a ⟶ Parser b";  // effectful function (HOF) — next parser
        #FpNodePresentation { role = "value"; tooltip = "String — the unconsumed remainder after pa_val runs. bind threads it into f(a). Nothing short-circuits (like Maybe)."; }
        part rest   : String;            // remaining unconsumed input threaded through
        #FpNodePresentation { role = "function"; tooltip = "bind p f = \\input ->\n  case p(input) of\n    Nothing       -> Nothing        -- propagate failure\n    Just (a, rest) -> f a rest      -- thread rest into next parser"; }
        part bind   : ParserBindOp;
        #FpNodePresentation { role = "type"; tooltip = "Parser b — the composed parser; on success returns (b, rest2) where rest2 is what f(a) didn't consume"; }
        part pb_val : "Parser b";        // String ⟶ Maybe (b, String)

        connection connect pa_val to bind;
        connection connect f_val  to bind;
        connection connect rest   to bind;  // remaining input flows into bind then f(a)
        connection connect bind   to pb_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b — also called: flatMap, Bind, >>=*/
        expose ParserBindContext;
        render fpIbdDiagram;
    }
}

