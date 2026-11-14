// SysML v2 — lens IBD: the function that over returns
// over :: Lens s a ⟶ (a ⟶ a) ⟶ s ⟶ s      over l f s = set l (f (get l s)) s
//
// Reading guide:
//   • the «block» frame is the update function s ⟶ s; its boundary ports are its call
//     interface: the structure s in, the updated copy out
//   • the lens l and the update f are fixed (captured) when over is applied — they live inside
//   • s travels on TWO wires: one into get, to read the focus, and one that bypasses f
//     entirely and meets the updated focus at set — f only ever sees the focus a
//   • the same lens l is used on both sides; that is why a lens bundles get and set

package LensSignature {
    private import FpDiagram::*;

    part def updater {
        #FpNodePresentation { tooltip = "s : the whole structure — actual parameter, supplied on every call"; }
        port in  s      : "s";
        #FpNodePresentation { tooltip = "result : s — a copy of the input with the focused field updated; nothing is mutated"; }
        port out result : "s";

        #FpNodePresentation { role = "hof"; tooltip = "l : Lens s a — focuses on one field of s: supplies both get and set; fixed when over was applied"; }
        part l : "Lens s a — captured";
        #FpNodePresentation { role = "hof"; tooltip = "f : a ⟶ a — update applied to the focused field only; fixed when over was applied"; }
        part f : "a ⟶ a — captured";

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
        #FpNodePresentation { role = "function"; tooltip = "set l a' s :: s — return a copy of s with the focus replaced by a'. Everything outside the focus comes from the original s."; }
        part set : "set l a' s" {
            port in  l : "Lens s a";
            port in  a : "a";
            port in  s : "s";
            port out _ : "s";
        }

        connection connect l       to get.l : "lens";
        connection connect s       to get.s : "read";
        connection connect get._   to call.a : "focus";
        connection connect f       to call.f : "update";
        connection connect l       to set.l : "same lens";
        connection connect call._  to set.a : "new focus a'";
        connection connect s       to set.s : "original bypasses f";
        connection connect set._   to result;
    }

    #FpViewPresentation { name = "over"; }
    view diagram : FpIbdView {
        doc /*over :: Lens s a ⟶ (a ⟶ a) ⟶ s ⟶ s — inside over: get the focus, apply f to it, then set the result back into the original s*/
        expose updater;
        render fpIbdDiagram;
    }
}
