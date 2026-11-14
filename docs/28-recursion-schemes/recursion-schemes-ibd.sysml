// SysML v2 — recursion schemes IBD: what happens inside cata
// cata :: Functor f => (f a ⟶ a) ⟶ Fix f ⟶ a      cata alg = alg ∘ fmap (cata alg) ∘ unFix
//
// Reading guide:
//   • the «block» frame is cata; its boundary ports are its whole call interface:
//     the algebra alg in, the new function Fix F ⟶ a out
//   • cata applies nothing itself — inside the block we see the body of the returned
//     function, as it runs when called: t is its parameter, supplied only then
//   • unFix peels one layer off t, exposing its children as F (Fix F)
//   • fmap (cata alg) is the recursion: it is this very block, applied to every child
//     under F — after it, each child has already been reduced to an a
//   • alg never recurses; it sees one layer F a and reduces it to a single a
//   • the same fmap-then-combine shape as bind: fmap first, then collapse one layer

package RecursionSchemesSignature {
    private import FpDiagram::*;

    part def cata {
        #FpNodePresentation { tooltip = "alg : F a ⟶ a — the algebra: what to do at one node, given its already-reduced children"; }
        port in  alg  : "F a ⟶ a";
        #FpNodePresentation { tooltip = "Fix F ⟶ a — the new function; nothing has been reduced yet"; }
        port out eval : "Fix F ⟶ a";

        #FpNodePresentation { role = "value"; tooltip = "The structure to reduce: supplied when the returned function is called, not when cata is applied to alg."; }
        part t : "Fix F — supplied when called";

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
        #FpNodePresentation { role = "function"; tooltip = "Abstract over t again: the whole body becomes the function Fix F ⟶ a that cata returns."; }
        part wrap : "λt → a" {
            port in  _ : "a";
            port out _ : "Fix F ⟶ a";
        }

        connection connect t          to unfix._ : "structure";
        connection connect unfix._    to recurse._ : "children (internal only)";
        connection connect alg        to recurse.alg : "same algebra";
        connection connect recurse._  to apply._ : "children reduced";
        connection connect alg        to apply.alg : "algebra";
        connection connect apply._    to wrap._ : "result";
        connection connect wrap._     to eval;
    }

    #FpViewPresentation { name = "cata"; }
    view diagram : FpIbdView {
        doc /*cata :: (F a ⟶ a) ⟶ Fix F ⟶ a — inside cata: unFix one layer, fmap cata over its children, then apply alg once*/
        expose cata;
        render fpIbdDiagram;
    }
}
