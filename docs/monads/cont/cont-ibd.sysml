// SysML v2 — Cont monad IBD: what happens inside bind
// (>>=) :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b      m >>= f = join (fmap f m)
//
// Cont r a = (a ⟶ r) ⟶ r — a computation waiting for "what to do next" (the continuation k).
//   • fmap composes f into the continuation: the result is a Cont yielding another Cont
//   • join hands the final continuation k to the inner Cont — the current step runs LAST
// This inversion of control enables callCC, early exit, exceptions, and coroutines.

package ContSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Cont r a = (a ⟶ r) ⟶ r — a suspended computation waiting for its continuation k"; }
        port in  ma : "Cont r a";
        #FpNodePresentation { tooltip = "f : a ⟶ Cont r b — user code; given result a, builds the next continuation-based step"; }
        port in  f  : "a ⟶ Cont r b";
        #FpNodePresentation { tooltip = "Cont r b = (b ⟶ r) ⟶ r — the composed computation; callCC can capture k here for early exit. Never Cont r (Cont r b)."; }
        port out mb : "Cont r b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: Cont r a ⟶ Cont r (Cont r b)\nfmap f m = \\k -> m (\\a -> k (f a))\nWhatever a is produced, the continuation k receives f a — the next Cont — not its result."; }
        part fmap : "Cont r a ⟶ Cont r (Cont r b)" {
            port in  f : "a ⟶ Cont r b";
            port in  _ : "Cont r a";
            port out _ : "Cont r (Cont r b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: Cont r (Cont r b) ⟶ Cont r b — the Cont-specific part\njoin mm = \\k -> mm (\\m -> m k)\nWhen the outer step finishes, the inner Cont it produced receives the original continuation k. The current step runs last — this is continuation composition."; }
        part join : "Cont r (Cont r b) ⟶ Cont r b" {
            port in  _ : "Cont r (Cont r b)";
            port out _ : "Cont r b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Cont r a ⟶ (a ⟶ Cont r b) ⟶ Cont r b — inside bind: fmap f, then join passes the original k to the inner Cont — also called: Bind, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
