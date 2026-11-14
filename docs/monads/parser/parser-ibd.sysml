// SysML v2 — Parser monad IBD: the Parser that bind returns
// (>>=) :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. Parser b = String ⟶ Maybe (b, String), so
// the «block» frame is the parser that bind returns: its boundary ports are its call
// interface — the text in, the outcome out. The two things bind was applied to, ma and f, are
// fixed (captured) inside. Here fmap and join are fused into State threading plus Maybe failure:
//   • the first parser consumes a prefix and returns a plus the unconsumed rest
//   • the parser f builds runs on that rest — not on the original text
//   • if the first parser fails, f is never reached and Nothing is returned

package ParserSignature {
    private import FpDiagram::*;

    part def bound {
        #FpNodePresentation { tooltip = "The text to parse, supplied each time the parser is run"; }
        port in  text   : "String";
        #FpNodePresentation { tooltip = "Just (b, rest2) where rest2 is what f(a) didn't consume, or Nothing if either parser failed"; }
        port out result : "Maybe (b, String)";

        #FpNodePresentation { role = "hof"; tooltip = "ma : Parser a = String ⟶ Maybe (a, String) — succeeds with (a, rest) or fails with Nothing; fixed when bind was applied"; }
        part ma : "Parser a — captured";
        #FpNodePresentation { role = "hof"; tooltip = "f : a ⟶ Parser b — user code; given parsed value a, constructs the next parser; fixed when bind was applied"; }
        part f : "a ⟶ Parser b — captured";

        #FpNodePresentation { role = "function"; tooltip = "Run the first parser on the text: ma text."; }
        part run_ma : "ma text" {
            port in  p : "Parser a";
            port in  s : "String";
            port out _ : "Maybe (a, String)";
        }
        #FpNodePresentation { role = "function"; tooltip = "Pattern match on the outcome.\nJust (a, rest) → value and unconsumed rest leave separately\nNothing        → the parse failed"; }
        part match : "case of" {
            port in  _       : "Maybe (a, String)";
            port out a       : "a";
            port out rest    : "String";
            port out nothing : "Nothing";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the parsed value: yields the next parser, not yet run."; }
        part call : "f a" {
            port in  f : "a ⟶ Parser b";
            port in  a : "a";
            port out _ : "Parser b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Run the next parser on the remainder: (f a) rest. This is the threading step of the join."; }
        part run_next : "(f a) rest" {
            port in  p : "Parser b";
            port in  s : "String";
            port out _ : "Maybe (b, String)";
        }
        #FpNodePresentation { role = "function"; tooltip = "Short-circuit: failure is propagated, f is skipped."; }
        part fail : "Nothing" {
            port in  _ : "Nothing";
            port out _ : "Maybe (b, String)";
        }

        connection connect ma            to run_ma.p : "captured";
        connection connect text          to run_ma.s : "text";
        connection connect run_ma._      to match._ : "outcome";
        connection connect match.a       to call.a : "parsed value";
        connection connect f             to call.f : "captured";
        connection connect call._        to run_next.p : "next parser";
        connection connect match.rest    to run_next.s : "rest threaded";
        connection connect match.nothing to fail._ : "f skipped";
        connection connect run_next._    to result;
        connection connect fail._        to result;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b — inside bind: the unconsumed rest is threaded into the next parser; failure skips it — also called: flatMap, Bind, >>=*/
        expose bound;
        render fpIbdDiagram;
    }
}
