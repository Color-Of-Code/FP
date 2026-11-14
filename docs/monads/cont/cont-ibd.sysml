// SysML v2 — Cont monad IBD: inside bind
// (>>=) :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. The call interface is the same for every
// monad — ma and f in, mb out. Cont r b = (b ⟶ r) ⟶ r, so inside the block we see the body
// of the Cont that bind returns: k is its parameter, the final continuation, supplied only
// when the result is run. Here fmap and join are fused into what Cont actually does — an
// inversion of control:
//   • f and k are wrapped into a NEW continuation k' = \a -> f a k
//   • the original computation ma receives k' and calls it with its result
// So the current step runs LAST — it hands control into the rest of the chain.

package ContSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Cont r a = (a ⟶ r) ⟶ r — a suspended computation waiting for its continuation"; }
        port in  ma : "Cont r a";
        #FpNodePresentation { tooltip = "f : a ⟶ Cont r b — user code; given result a, builds the next continuation-based step"; }
        port in  f  : "a ⟶ Cont r b";
        #FpNodePresentation { tooltip = "Cont r b = (b ⟶ r) ⟶ r — the composed computation; callCC can capture k here for early exit"; }
        port out mb : "Cont r b";

        #FpNodePresentation { role = "value"; tooltip = "The final continuation: the parameter of the returned Cont. It says what to do with b once everything is done, and is supplied when the Cont is run, not when bind is called."; }
        part k : "b ⟶ r — supplied when run";

        #FpNodePresentation { role = "function"; tooltip = "Builds the new continuation k' = \\a -> f a k.\nWhen k' receives a, it runs f a and hands it the ORIGINAL continuation k — this is the Cont-specific join."; }
        part bridge : "λa → (f a) k" {
            port in  f  : "a ⟶ Cont r b";
            port in  k  : "b ⟶ r";
            port out k2 : "a ⟶ r";
        }
        #FpNodePresentation { role = "function"; tooltip = "Run the original computation, handing it k' instead of k. It decides if and when to call k' (once, many times, or never — callCC, early exit)."; }
        part run : "ma k'" {
            port in  m  : "Cont r a";
            port in  k2 : "a ⟶ r";
            port out _  : "r";
        }
        #FpNodePresentation { role = "function"; tooltip = "Abstract over k again: the whole body becomes the Cont r b that bind returns."; }
        part wrap : "λk → r" {
            port in  _ : "r";
            port out _ : "Cont r b";
        }

        connection connect f         to bridge.f : "user code";
        connection connect k         to bridge.k : "final continuation";
        connection connect bridge.k2 to run.k2 : "new continuation k'";
        connection connect ma        to run.m : "wrapped";
        connection connect run._     to wrap._ : "answer";
        connection connect wrap._    to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b — inside bind: f and k are wrapped into a new continuation handed to ma, so the current step runs last — also called: Bind, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
