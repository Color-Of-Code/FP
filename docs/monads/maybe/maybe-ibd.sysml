// SysML v2 — Maybe monad IBD: what happens inside bind
// (>>=) :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b      m >>= f = join (fmap f m)
//
// Same fmap → join shape as every monad — only the join differs:
//   • fmap applies f under Just and does nothing under Nothing (f is never called)
//   • join collapses Just (Just b) to Just b and drops Nothing at either level
// See maybe-pure.sysml for pure :: a ⟶ Maybe a.

package MaybeSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Maybe a — Just a (has a value) or Nothing (absent). If Nothing, f is never called."; }
        port in  ma : "Maybe a";
        #FpNodePresentation { tooltip = "f : a ⟶ Maybe b — user code; may itself return Nothing"; }
        port in  f  : "a ⟶ Maybe b";
        #FpNodePresentation { tooltip = "Maybe b — Just b (every step succeeded) or Nothing (first failure propagated); never Maybe (Maybe b)"; }
        port out mb : "Maybe b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: Maybe a ⟶ Maybe (Maybe b)\nJust a  →  Just (f a)\nNothing →  Nothing   (f is skipped)"; }
        part fmap : "Maybe a ⟶ Maybe (Maybe b)" {
            port in  f : "a ⟶ Maybe b";
            port in  _ : "Maybe a";
            port out _ : "Maybe (Maybe b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: Maybe (Maybe b) ⟶ Maybe b — the Maybe-specific part\nJust (Just b) →  Just b\nJust Nothing  →  Nothing\nNothing       →  Nothing   (failure at either level propagates)"; }
        part join : "Maybe (Maybe b) ⟶ Maybe b" {
            port in  _ : "Maybe (Maybe b)";
            port out _ : "Maybe b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Maybe a ⟶ (a ⟶ Maybe b) ⟶ Maybe b — inside bind: fmap f, then join; Nothing short-circuits — also called: flatMap, andThen / and_then, SelectMany, chain, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
