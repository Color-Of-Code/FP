// SysML v2 — Parser monad IBD: what happens inside bind
// (>>=) :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b      m >>= f = join (fmap f m)
//
// Parser a = String ⟶ Maybe (a, String) — State threading plus Maybe failure.
//   • fmap applies f to the parsed value, keeping the remaining input
//   • join runs the outer parser, then runs the Parser it produced on the
//     unconsumed remainder; Nothing short-circuits (like Maybe)

package ParserSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Parser a = String ⟶ Maybe (a, String) — run on input; succeeds with (a, rest) or fails with Nothing"; }
        port in  ma : "Parser a";
        #FpNodePresentation { tooltip = "f : a ⟶ Parser b — user code; given parsed value a, constructs the next parser"; }
        port in  f  : "a ⟶ Parser b";
        #FpNodePresentation { tooltip = "Parser b — the composed parser; on success returns (b, rest2) where rest2 is what f(a) didn't consume. Never Parser (Parser b)."; }
        port out mb : "Parser b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: Parser a ⟶ Parser (Parser b)\nOn success (a, rest) returns (f a, rest): the next parser is built but not yet run. Failure stays Nothing."; }
        part fmap : "Parser a ⟶ Parser (Parser b)" {
            port in  f : "a ⟶ Parser b";
            port in  _ : "Parser a";
            port out _ : "Parser (Parser b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: Parser (Parser b) ⟶ Parser b — the Parser-specific part\njoin pp = \\input -> case pp input of\n  Nothing        -> Nothing       -- propagate failure\n  Just (p, rest) -> p rest        -- run the inner parser on the remainder"; }
        part join : "Parser (Parser b) ⟶ Parser b" {
            port in  _ : "Parser (Parser b)";
            port out _ : "Parser b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b — inside bind: fmap f, then join runs the inner parser on the remaining input — also called: flatMap, Bind, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
