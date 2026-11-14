// SysML v2 — Reader monad IBD: what happens inside bind
// (>>=) :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b      m >>= f = join (fmap f m)
//
// Reader r a = r ⟶ a — a computation waiting for its environment r.
//   • fmap applies f to the eventual result: a Reader that yields another Reader
//   • join runs the outer Reader with r, then runs the Reader it produced with the
//     SAME r — the environment is shared, never consumed, never modified

package ReaderSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Reader r a — a computation waiting for env r; when run with r it produces a"; }
        port in  ma : "Reader r a";
        #FpNodePresentation { tooltip = "f : a ⟶ Reader r b — user code; given a, produces a new computation waiting for r"; }
        port in  f  : "a ⟶ Reader r b";
        #FpNodePresentation { tooltip = "Reader r b — the composed computation; when run with r it produces b. Never Reader r (Reader r b)."; }
        port out mb : "Reader r b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: Reader r a ⟶ Reader r (Reader r b)\nfmap f ma = \\r -> f (ma r)\nOnce r is supplied, the result is the next Reader — not yet run."; }
        part fmap : "Reader r a ⟶ Reader r (Reader r b)" {
            port in  f : "a ⟶ Reader r b";
            port in  _ : "Reader r a";
            port out _ : "Reader r (Reader r b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: Reader r (Reader r b) ⟶ Reader r b — the Reader-specific part\njoin mm = \\r -> mm r r\nRun the outer Reader with r to get the inner Reader, then run it with the SAME env r. r is never modified."; }
        part join : "Reader r (Reader r b) ⟶ Reader r b" {
            port in  _ : "Reader r (Reader r b)";
            port out _ : "Reader r b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b — inside bind: fmap f, then join feeds the same r to both — also called: flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
