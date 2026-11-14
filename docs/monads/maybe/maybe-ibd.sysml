// SysML v2 — Maybe monad IBD: inside bind
// (>>=) :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. Here fmap and join are fused into
// what Maybe actually does — a case split with two exits:
//   • Just a  → a goes into f, whose result is the answer
//   • Nothing → f is never reached; Nothing is returned as-is
// Contrast List, where f is called once per element and the results are concatenated.

package MaybeSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Maybe a — Just a (has a value) or Nothing (absent)"; }
        port in  ma : "Maybe a";
        #FpNodePresentation { tooltip = "f : a ⟶ Maybe b — user code; may itself return Nothing"; }
        port in  f  : "a ⟶ Maybe b";
        #FpNodePresentation { tooltip = "Maybe b — Just b (every step succeeded) or Nothing (first failure propagated)"; }
        port out mb : "Maybe b";

        #FpNodePresentation { role = "function"; tooltip = "Pattern match on the constructor.\nJust a  → the payload a leaves through 'just'\nNothing → the 'nothing' exit fires; there is no a to pass on"; }
        part match : "case ma of" {
            port in  _       : "Maybe a";
            port out just    : "a";
            port out nothing : "Nothing";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the payload. Only reachable on the Just path — on Nothing, f is never called."; }
        part call : "f a" {
            port in  f : "a ⟶ Maybe b";
            port in  a : "a";
            port out _ : "Maybe b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Short-circuit: the absence is returned unchanged, retyped as Maybe b."; }
        part skip : "Nothing" {
            port in  _ : "Nothing";
            port out _ : "Maybe b";
        }

        connection connect ma            to match._ : "wrapped";
        connection connect f             to call.f : "user code";
        connection connect match.just    to call.a : "payload";
        connection connect match.nothing to skip._ : "f skipped";
        connection connect call._        to mb;
        connection connect skip._        to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b — inside bind: Just passes its payload to f; Nothing skips f — also called: flatMap, andThen / and_then, SelectMany, chain, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
