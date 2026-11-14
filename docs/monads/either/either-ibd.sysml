// SysML v2 — Either monad IBD: inside bind
// (>>=) :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. Same case split as Maybe — but the
// failure exit carries a value:
//   • Right a → a goes into f, whose result is the answer
//   • Left e  → f is never reached; the error e is returned unchanged

package EitherSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Either e a — Right a (carry a) or Left e (carry error e)"; }
        port in  ma : "Either e a";
        #FpNodePresentation { tooltip = "f : a ⟶ Either e b — user code; may itself return Left e"; }
        port in  f  : "a ⟶ Either e b";
        #FpNodePresentation { tooltip = "Either e b — Right b (all steps succeeded) or Left e (first error propagated, unchanged)"; }
        port out mb : "Either e b";

        #FpNodePresentation { role = "function"; tooltip = "Pattern match on the constructor.\nRight a → the payload a leaves through 'right'\nLeft e  → the error e leaves through 'left'"; }
        part match : "case ma of" {
            port in  _     : "Either e a";
            port out right : "a";
            port out left  : "e";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the payload. Only reachable on the Right path — on Left, f is never called."; }
        part call : "f a" {
            port in  f : "a ⟶ Either e b";
            port in  a : "a";
            port out _ : "Either e b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Short-circuit: the error value is rewrapped as Left e, unchanged — unlike Maybe, the reason is preserved."; }
        part skip : "Left e" {
            port in  e : "e";
            port out _ : "Either e b";
        }

        connection connect ma         to match._ : "wrapped";
        connection connect f          to call.f : "user code";
        connection connect match.right to call.a : "payload";
        connection connect match.left to skip.e : "error kept";
        connection connect call._     to mb;
        connection connect skip._     to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b — inside bind: Right passes its payload to f; Left skips f and keeps its error — also called: andThen / and_then, Bind, flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
