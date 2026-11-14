// SysML v2 — transformer IBD: what happens inside bind of ExceptT e m
// (>>=) :: ExceptT e m a ⟶ (a ⟶ ExceptT e m b) ⟶ ExceptT e m b
//
// Reading guide:
//   • the «block» frame is bind of the transformer; its boundary ports are the same call
//     interface as any monad's bind: ma and f in, mb out
//   • an ExceptT e m a is just an m (Either e a) — the transformer does not run anything
//     itself: it hands the sequencing to the bind of the monad m BELOW it
//   • the continuation given to m's bind is where ExceptT's own effect lives: a Left
//     short-circuits (m returns the error, f is skipped), a Right runs f a
//   • that is the whole trick of a transformer stack: every layer's bind is built on the
//     layer underneath; the chain of layers is a chain of these blocks

package TransformerSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "ExceptT e m a ≅ m (Either e a) — an m-computation that may fail with e"; }
        port in  ma : "ExceptT e m a";
        #FpNodePresentation { tooltip = "f : a ⟶ ExceptT e m b — user code; may itself fail"; }
        port in  f  : "a ⟶ ExceptT e m b";
        #FpNodePresentation { tooltip = "ExceptT e m b — the composed computation"; }
        port out mb : "ExceptT e m b";

        #FpNodePresentation { role = "function"; tooltip = "runExceptT: look through the newtype at the m (Either e a) it wraps."; }
        part unwrap : "runExceptT" {
            port in  _ : "ExceptT e m a";
            port out _ : "m (Either e a)";
        }
        #FpNodePresentation { role = "function"; tooltip = "Build the continuation for m's bind.\n\\r -> case r of\n  Left e  -> return (Left e)   -- short-circuit: f is skipped\n  Right a -> runExceptT (f a)  -- run the next step"; }
        part next : "λr → case r of …" {
            port in  f : "a ⟶ ExceptT e m b";
            port out _ : "Either e a ⟶ m (Either e b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "The bind of the monad m underneath — the layer below does the actual sequencing (IO runs effects in order, Writer appends logs, State threads state, …)."; }
        part bind_m : ">>= of m" {
            port in  m : "m (Either e a)";
            port in  k : "Either e a ⟶ m (Either e b)";
            port out _ : "m (Either e b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "ExceptT: put the newtype back around the result."; }
        part wrap : "ExceptT" {
            port in  _ : "m (Either e b)";
            port out _ : "ExceptT e m b";
        }

        connection connect ma        to unwrap._ : "wrapped";
        connection connect f         to next.f : "user code";
        connection connect unwrap._  to bind_m.m : "inner computation";
        connection connect next._    to bind_m.k : "continuation";
        connection connect bind_m._  to wrap._ : "composed in m";
        connection connect wrap._    to mb;
    }

    #FpViewPresentation { name = "bind (ExceptT)"; }
    view diagram : FpIbdView {
        doc /*bind :: ExceptT e m a ⟶ (a ⟶ ExceptT e m b) ⟶ ExceptT e m b — inside bind: the layer's continuation is sequenced by the bind of the monad m below*/
        expose bind;
        render fpIbdDiagram;
    }
}
