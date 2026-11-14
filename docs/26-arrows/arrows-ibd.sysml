// SysML v2 — arrows IBD: the arrow that first returns
// first :: A b c ⟶ A (b, d) (c, d)      first f (b, d) = (f b, d)
//
// Reading guide:
//   • drawn for the plain function arrow (→), where running an arrow is applying it
//   • the «block» frame is the lifted arrow; its boundary ports are its call interface:
//     the pair p in, the new pair out
//   • the original arrow is fixed (captured) when first lifts it — it lives inside
//   • the pair is split: b goes through the arrow, d bypasses it on its own wire
//   • the two parts meet again in the output pair — the arrow never sees d

package ArrowsSignature {
    private import FpDiagram::*;

    part def lifted {
        #FpNodePresentation { tooltip = "p : (b, d) — the pair the lifted arrow runs on, supplied on every call"; }
        port in  p      : "(b, d)";
        #FpNodePresentation { tooltip = "result : (c, d) — the arrow's output paired with the untouched second component"; }
        port out result : "(c, d)";

        #FpNodePresentation { role = "hof"; tooltip = "arrow : A b c — an arrow from b to c (for plain functions: b ⟶ c); fixed when first lifted it"; }
        part arrow : "A b c — captured";

        #FpNodePresentation { role = "function"; tooltip = "Take the pair apart: b is for the arrow, d is set aside."; }
        part split : "(b, d)" {
            port in  _ : "(b, d)";
            port out b : "b";
            port out d : "d";
        }
        #FpNodePresentation { role = "function"; tooltip = "Run the arrow on b only — it never sees d."; }
        part run : "arrow b" {
            port in  arrow : "A b c";
            port in  b     : "b";
            port out _     : "c";
        }
        #FpNodePresentation { role = "function"; tooltip = "Put the pair back together: the arrow's result and the untouched d."; }
        part join_pair : "(c, d)" {
            port in  c : "c";
            port in  d : "d";
            port out _ : "(c, d)";
        }

        connection connect p         to split._ : "pair";
        connection connect arrow     to run.arrow : "captured";
        connection connect split.b   to run.b : "first component";
        connection connect split.d   to join_pair.d : "bypasses the arrow";
        connection connect run._     to join_pair.c : "result";
        connection connect join_pair._ to result;
    }

    #FpViewPresentation { name = "first"; }
    view diagram : FpIbdView {
        doc /*first :: A b c ⟶ A (b, d) (c, d) — inside first: the arrow runs on b only; d bypasses it and rejoins the result*/
        expose lifted;
        render fpIbdDiagram;
    }
}
