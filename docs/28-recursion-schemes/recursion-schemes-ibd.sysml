// SysML v2 — recursion schemes IBD: the function that cata returns
// cata :: Functor f => (f a ⟶ a) ⟶ Fix f ⟶ a      cata alg = alg ∘ fmap (cata alg) ∘ unFix
//
// Reading guide:
//   • the «block» frame is the reducer Fix F ⟶ a; its boundary ports are its call interface:
//     the structure t in, the reduced result out
//   • the algebra alg is fixed (captured) when cata is applied — it lives inside
//   • unFix peels one layer off t, exposing its children as F (Fix F)
//   • fmap (cata alg) is the recursion: it is this very block, applied to every child
//     under F — after it, each child has already been reduced to an a
//   • alg never recurses; it sees one layer F a and reduces it to a single a
//   • the same fmap-then-combine shape as bind: fmap first, then collapse one layer

package RecursionSchemesSignature {
    private import FpDiagram::*;

    part def reducer {
        #FpNodePresentation { tooltip = "t : Fix F — the structure to reduce, supplied on every call"; }
        port in  t      : "Fix F";
        #FpNodePresentation { tooltip = "result : a — the whole structure reduced to a single value"; }
        port out result : "a";

        #FpNodePresentation { role = "hof"; tooltip = "alg : F a ⟶ a — the algebra: what to do at one node, given its already-reduced children; fixed when cata was applied"; }
        part alg : "F a ⟶ a — captured";

        #FpNodePresentation { role = "function"; tooltip = "unFix :: Fix F ⟶ F (Fix F) — peel one layer: the node's constructor with its children still unreduced."; }
        part unfix : "unFix" {
            port in  _ : "Fix F";
            port out _ : "F (Fix F)";
        }
        #FpNodePresentation { role = "function"; tooltip = "fmap (cata alg) :: F (Fix F) ⟶ F a — the recursion. cata alg is this very block, applied to every child under F; the shape of the layer is kept."; }
        part recurse : "fmap (cata alg)" {
            port in  alg : "F a ⟶ a";
            port in  _   : "F (Fix F)";
            port out _   : "F a";
        }
        #FpNodePresentation { role = "function"; tooltip = "alg :: F a ⟶ a — applied exactly once per node, on a layer whose children are already reduced."; }
        part apply : "alg" {
            port in  alg : "F a ⟶ a";
            port in  _   : "F a";
            port out _   : "a";
        }

        connection connect t          to unfix._ : "structure";
        connection connect unfix._    to recurse._ : "children (internal only)";
        connection connect alg        to recurse.alg : "same algebra";
        connection connect recurse._  to apply._ : "children reduced";
        connection connect alg        to apply.alg : "algebra";
        connection connect apply._    to result;
    }

    #FpViewPresentation { name = "cata"; }
    view diagram : FpIbdView {
        doc /*cata :: (F a ⟶ a) ⟶ Fix F ⟶ a — inside cata: unFix one layer, fmap cata over its children, then apply alg once*/
        expose reducer;
        render fpIbdDiagram;
    }
}
