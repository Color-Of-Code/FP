// SysML v2 — Parser monad IBD: type signature + bind contract
// (>>=) :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b
//
// Parser a = String ⟶ Maybe (a, String)
// The extra node rest shows the key structural difference: the remaining input
// is threaded from the first parser into f(a), just as the state threads in
// the State monad — each step consumes a prefix and passes the remainder forward.

package ParserSignature {

    part def ParserBindContext {
        part pa_val : "Parser a";        // String ⟶ Maybe (a, String)
        part f_val  : "a ⟶ Parser b";  // effectful function (HOF) — next parser
        part rest   : String;            // remaining unconsumed input threaded through
        part bind   : ParserBindOp;
        part pb_val : "Parser b";        // String ⟶ Maybe (b, String)

        connection connect pa_val to bind;
        connection connect f_val  to bind;
        connection connect rest   to bind;  // remaining input flows into bind then f(a)
        connection connect bind   to pb_val;
    }
}

#diagram {
    type  = ibd
    title = "(>>=) :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b"
    render = ParserBindContext
    show pa_val as type
    show f_val  as hof
    show rest   as value
    show bind   as function
    show pb_val as type
    tooltip pa_val = "Parser a = String ⟶ Maybe (a, String) — run on input; succeeds with (a, rest) or fails with Nothing"
    tooltip f_val  = "(a ⟶ Parser b) — given parsed value a, constructs the next parser (runs on the remaining input)"
    tooltip rest   = "String — the unconsumed remainder after pa_val runs. bind threads it into f(a). Nothing short-circuits (like Maybe)."
    tooltip bind   = "bind p f = \\input ->\n  case p(input) of\n    Nothing       -> Nothing        -- propagate failure\n    Just (a, rest) -> f a rest      -- thread rest into next parser"
    tooltip pb_val = "Parser b — the composed parser; on success returns (b, rest2) where rest2 is what f(a) didn't consume"
}
