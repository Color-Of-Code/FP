// SysML v2 — arrows IBD: what happens inside first
// first :: A b c ⟶ A (b, d) (c, d)      first f (b, d) = (f b, d)
//
// Reading guide:
//   • the «block» frame is first; its boundary ports are its whole call interface:
//     the arrow in, the lifted arrow out
//   • first applies nothing itself — inside the block we see the body of the lifted
//     arrow, as it runs on a pair: p is its input, supplied only then
//   • the pair is split: b goes through the arrow, d bypasses it on its own wire
//   • the two parts meet again in the output pair — the arrow never sees d
//   • drawn for the plain function arrow (→), where running an arrow is applying it

package ArrowsSignature {
    private import FpDiagram::*;

    part def first {
        #FpNodePresentation { tooltip = "A b c — an arrow from b to c (for plain functions: b ⟶ c)"; }
        port in  arrow : "A b c";
        #FpNodePresentation { tooltip = "A (b, d) (c, d) — the same arrow lifted to pairs; the second component is passed through unchanged"; }
        port out paired : "A (b, d) (c, d)";

        #FpNodePresentation { role = "value"; tooltip = "The pair the lifted arrow runs on: supplied when it is called."; }
        part p : "(b, d) — supplied when run";

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
        #FpNodePresentation { role = "function"; tooltip = "Abstract over the pair again: the whole body becomes the lifted arrow that first returns."; }
        part wrap : "λp → (c, d)" {
            port in  _ : "(c, d)";
            port out _ : "A (b, d) (c, d)";
        }

        connection connect p         to split._ : "pair";
        connection connect arrow     to run.arrow : "arrow";
        connection connect split.b   to run.b : "first component";
        connection connect split.d   to join_pair.d : "bypasses the arrow";
        connection connect run._     to join_pair.c : "result";
        connection connect join_pair._ to wrap._ : "pair";
        connection connect wrap._    to paired;
    }

    #FpViewPresentation { name = "first"; }
    view diagram : FpIbdView {
        doc /*first :: A b c ⟶ A (b, d) (c, d) — inside first: the arrow runs on b only; d bypasses it and rejoins the result*/
        expose first;
        render fpIbdDiagram;
    }
}
