// SysML v2 — lens IBD: what happens inside over
// over :: Lens s a ⟶ (a ⟶ a) ⟶ s ⟶ s      over l f s = set l (f (get l s)) s
//
// Reading guide:
//   • the «block» frame is over; its boundary ports are its whole call interface:
//     the lens l, the update function f, the new function s ⟶ s out
//   • over applies nothing itself — inside the block we see the body of the returned
//     function, as it runs when called: s is its parameter, supplied only then
//   • s travels on TWO wires: one into get, to read the focus, and one that bypasses
//     f entirely and meets the updated focus at set — f only ever sees the focus a
//   • the same lens l is used on both sides; that is why a lens bundles get and set

package LensSignature {
    private import FpDiagram::*;

    part def over {
        #FpNodePresentation { tooltip = "l : Lens s a — focuses on one field of s: supplies both get and set"; }
        port in  l : "Lens s a";
        #FpNodePresentation { tooltip = "f : a ⟶ a — update applied to the focused field only"; }
        port in  f : "a ⟶ a";
        #FpNodePresentation { tooltip = "s ⟶ s — a new function; nothing has been read or replaced yet"; }
        port out h : "s ⟶ s";

        #FpNodePresentation { role = "value"; tooltip = "The whole structure: supplied when the returned function is called, not when over is applied to l and f."; }
        part s : "s — supplied when called";

        #FpNodePresentation { role = "function"; tooltip = "get l s :: a — read the focused field."; }
        part get : "get l s" {
            port in  l : "Lens s a";
            port in  s : "s";
            port out _ : "a";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply the update to the focus. f never sees the rest of s."; }
        part call : "f a" {
            port in  f : "a ⟶ a";
            port in  a : "a";
            port out _ : "a";
        }
        #FpNodePresentation { role = "function"; tooltip = "set l a' s :: s — return a copy of s with the focus replaced by a'. Everything outside the focus comes from the original s; nothing is mutated."; }
        part set : "set l a' s" {
            port in  l  : "Lens s a";
            port in  a  : "a";
            port in  s  : "s";
            port out _  : "s";
        }
        #FpNodePresentation { role = "function"; tooltip = "Abstract over s again: the whole body becomes the function s ⟶ s that over returns."; }
        part wrap : "λs → s'" {
            port in  _ : "s";
            port out _ : "s ⟶ s";
        }

        connection connect l       to get.l : "lens";
        connection connect s       to get.s : "read";
        connection connect get._   to call.a : "focus";
        connection connect f       to call.f : "update";
        connection connect l       to set.l : "same lens";
        connection connect call._  to set.a : "new focus a'";
        connection connect s       to set.s : "original bypasses f";
        connection connect set._   to wrap._ : "updated copy";
        connection connect wrap._  to h;
    }

    #FpViewPresentation { name = "over"; }
    view diagram : FpIbdView {
        doc /*over :: Lens s a ⟶ (a ⟶ a) ⟶ s ⟶ s — inside over: get the focus, apply f to it, then set the result back into the original s*/
        expose over;
        render fpIbdDiagram;
    }
}
