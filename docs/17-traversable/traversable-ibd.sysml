// SysML v2 — traversable IBD: what happens inside traverse
// traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb)      traverse f = sequence ∘ fmap f
//
// Reading guide:
//   • the «block» frame is traverse; its boundary ports are its whole call interface:
//     the effectful mapper f, the structure T a, and the effect-outside result F (T b)
//   • fmap is the Functor T mapping — it knows nothing about F, so every element
//     becomes an F b and the effects end up INSIDE the structure: T (F b)
//   • sequence swaps the layers using the Applicative F, combining all the
//     effects into a single outer F — the same role join plays in bind
//   • the intermediate T (F b) exists only inside the block

package TraversableSignature {
    private import FpDiagram::*;

    part def traverse {
        #FpNodePresentation { tooltip = "f : a ⟶ F b — effectful mapper applied to each element"; }
        port in  f   : "a ⟶ F b";
        #FpNodePresentation { tooltip = "T a — traversable structure containing elements of type a"; }
        port in  ta  : "T a";
        #FpNodePresentation { tooltip = "F (T b) — effect on the outside, rebuilt structure on the inside"; }
        port out ftb : "F (T b)";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: T a ⟶ T (F b) — from Functor T. Applies f to every element and keeps the shape of the structure; each element is now an effect waiting to be combined."; }
        part fmap : "T a ⟶ T (F b)" {
            port in  f : "a ⟶ F b";
            port in  _ : "T a";
            port out _ : "T (F b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "sequence :: T (F b) ⟶ F (T b) — needs Applicative F. Runs the effects left to right and rebuilds the structure inside a single outer F: Maybe fails on any Nothing, List builds all combinations, IO runs the actions in order."; }
        part sequence : "T (F b) ⟶ F (T b)" {
            port in  _ : "T (F b)";
            port out _ : "F (T b)";
        }

        connection connect ta         to fmap._ : "structure";
        connection connect f          to fmap.f : "effectful mapper";
        connection connect fmap._     to sequence._ : "effects inside (internal only)";
        connection connect sequence._ to ftb;
    }

    #FpViewPresentation { name = "traverse"; }
    view diagram : FpIbdView {
        doc /*traverse :: (a ⟶ Fb) ⟶ Ta ⟶ F(Tb) — inside traverse: fmap f, then sequence swaps T (F b) into F (T b)*/
        expose traverse;
        render fpIbdDiagram;
    }
}
