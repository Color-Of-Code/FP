// SysML v2 — Parser monad IBD: inside bind
// (>>=) :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. The call interface is the same for every
// monad — ma and f in, mb out. Parser a = String ⟶ Maybe (a, String), so inside the block we
// see the body of the parser that bind returns: text is its parameter, supplied only when
// the parser is run. Here fmap and join are fused into State threading plus Maybe failure:
//   • the first parser consumes a prefix and returns a plus the unconsumed rest
//   • the parser f builds runs on that rest — not on the original text
//   • if the first parser fails, f is never reached and Nothing is returned

package ParserSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Parser a = String ⟶ Maybe (a, String) — run on input; succeeds with (a, rest) or fails with Nothing"; }
        port in  ma : "Parser a";
        #FpNodePresentation { tooltip = "f : a ⟶ Parser b — user code; given parsed value a, constructs the next parser"; }
        port in  f  : "a ⟶ Parser b";
        #FpNodePresentation { tooltip = "Parser b — the composed parser; a function still waiting for the text to parse"; }
        port out mb : "Parser b";

        #FpNodePresentation { role = "value"; tooltip = "The text to parse: the parameter of the returned parser. It is supplied when the parser is run, not when bind is called."; }
        part text : "String — supplied when run";

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
        #FpNodePresentation { role = "function"; tooltip = "Abstract over the text again: the outcome becomes the Parser b that bind returns."; }
        part wrap : "λtext → Maybe (b, String)" {
            port in  _ : "Maybe (b, String)";
            port out _ : "Parser b";
        }

        connection connect ma            to run_ma.p : "wrapped";
        connection connect text          to run_ma.s : "text";
        connection connect run_ma._      to match._ : "outcome";
        connection connect match.a       to call.a : "parsed value";
        connection connect f             to call.f : "user code";
        connection connect call._        to run_next.p : "next parser";
        connection connect match.rest    to run_next.s : "rest threaded";
        connection connect match.nothing to fail._ : "f skipped";
        connection connect run_next._    to wrap._ : "success";
        connection connect fail._        to wrap._ : "failure";
        connection connect wrap._        to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Parser a ⟶ (a ⟶ Parser b) ⟶ Parser b — inside bind: the unconsumed rest is threaded into the next parser; failure skips it — also called: flatMap, Bind, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
