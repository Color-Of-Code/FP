// SysML v2 — Either monad IBD: what happens inside bind
// (>>=) :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b      m >>= f = join (fmap f m)
//
// Same fmap → join shape as Maybe — but Left carries the error value e, preserved intact:
//   • fmap applies f under Right and leaves Left untouched (f is never called)
//   • join collapses Right (Right b) to Right b and keeps the first Left

package EitherSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Either e a — Right a (carry a) or Left e (carry error e). Unlike Maybe, the error value is preserved."; }
        port in  ma : "Either e a";
        #FpNodePresentation { tooltip = "f : a ⟶ Either e b — user code; may itself return Left e"; }
        port in  f  : "a ⟶ Either e b";
        #FpNodePresentation { tooltip = "Either e b — Right b (all steps succeeded) or Left e (first error propagated, unchanged); never Either e (Either e b)"; }
        port out mb : "Either e b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: Either e a ⟶ Either e (Either e b)\nRight a →  Right (f a)\nLeft e  →  Left e   (f is skipped)"; }
        part fmap : "Either e a ⟶ Either e (Either e b)" {
            port in  f : "a ⟶ Either e b";
            port in  _ : "Either e a";
            port out _ : "Either e (Either e b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: Either e (Either e b) ⟶ Either e b — the Either-specific part\nRight (Right b) →  Right b\nRight (Left e)  →  Left e\nLeft e          →  Left e   (the error value is preserved unchanged)"; }
        part join : "Either e (Either e b) ⟶ Either e b" {
            port in  _ : "Either e (Either e b)";
            port out _ : "Either e b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Either e a ⟶ (a ⟶ Either e b) ⟶ Either e b — inside bind: fmap f, then join; Left short-circuits — also called: andThen / and_then, Bind, flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
