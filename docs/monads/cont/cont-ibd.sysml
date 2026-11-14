// SysML v2 — Cont monad IBD: the Cont that bind returns
// (>>=) :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. Cont r b = (b ⟶ r) ⟶ r, so the «block»
// frame is the Cont that bind returns: its boundary ports are its call interface — the final
// continuation k in, the answer r out. The two things bind was applied to, ma and f, are fixed
// (captured) inside. Here fmap and join are fused into what Cont actually does — an
// inversion of control:
//   • f and k are wrapped into a NEW continuation k' = \a -> f a k
//   • the original computation ma receives k' and calls it with its result
// So the current step runs LAST — it hands control into the rest of the chain.

package ContSignature {
    private import FpDiagram::*;

    part def bound {
        #FpNodePresentation { tooltip = "k : b ⟶ r — the final continuation: what to do with b once everything is done. Supplied each time the Cont is run."; }
        port in  k      : "b ⟶ r";
        #FpNodePresentation { tooltip = "r — the final answer of the whole computation; callCC can capture k to exit early"; }
        port out result : "r";

        #FpNodePresentation { role = "hof"; tooltip = "ma : Cont r a = (a ⟶ r) ⟶ r — a suspended computation waiting for its continuation; fixed when bind was applied"; }
        part ma : "Cont r a — captured";
        #FpNodePresentation { role = "hof"; tooltip = "f : a ⟶ Cont r b — user code; given result a, builds the next continuation-based step; fixed when bind was applied"; }
        part f : "a ⟶ Cont r b — captured";

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

        connection connect f         to bridge.f : "captured";
        connection connect k         to bridge.k : "final continuation";
        connection connect bridge.k2 to run.k2 : "new continuation k'";
        connection connect ma        to run.m : "captured";
        connection connect run._     to result;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b — inside bind: f and k are wrapped into a new continuation handed to ma, so the current step runs last — also called: Bind, >>=*/
        expose bound;
        render fpIbdDiagram;
    }
}
