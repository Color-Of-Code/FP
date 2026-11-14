// SysML v2 — applicative IBD: what happens inside <*>
// (<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb      ff <*> fa = fmap apply (pair ff fa)
//
// Reading guide:
//   • the «block» frame is <*>; its boundary ports are its whole call interface:
//     the wrapped function F (a ⟶ b), the wrapped value F a, and the wrapped result F b
//   • pair is the Applicative-specific part: it combines two independent contexts
//     into one context holding both values (Maybe needs both Just, List takes all
//     combinations, Validation collects both errors)
//   • fmap apply then applies the function to its argument under F; no user code
//     is involved, and — unlike bind — nothing computed in the first step can
//     influence which effect comes next
//   • the pair F ((a ⟶ b), a) exists only inside the block

package ApplicativeSignature {
    private import FpDiagram::*;

    part def ap {
        #FpNodePresentation { tooltip = "F (a ⟶ b) — a function already lifted into the applicative context"; }
        port in  ff : "F (a ⟶ b)";
        #FpNodePresentation { tooltip = "F a — value inside the same context F"; }
        port in  fa : "F a";
        #FpNodePresentation { tooltip = "F b — result in context F"; }
        port out fb : "F b";

        #FpNodePresentation { role = "function"; tooltip = "pair :: F x ⟶ F y ⟶ F (x, y) — the Applicative-specific part (the monoidal structure of F). Combines both contexts: Maybe needs both Just, List takes all combinations, Validation accumulates both errors, IO runs both effects in order."; }
        part pair : "F (a ⟶ b) × F a ⟶ F ((a ⟶ b), a)" {
            port in  ff : "F (a ⟶ b)";
            port in  fa : "F a";
            port out _  : "F ((a ⟶ b), a)";
        }
        #FpNodePresentation { role = "function"; tooltip = "fmap apply :: F ((a ⟶ b), a) ⟶ F b — from Functor. apply (f, a) = f a, mapped under the combined context."; }
        part fmap : "F ((a ⟶ b), a) ⟶ F b" {
            port in  _ : "F ((a ⟶ b), a)";
            port out _ : "F b";
        }

        connection connect ff       to pair.ff : "wrapped function";
        connection connect fa       to pair.fa : "wrapped value";
        connection connect pair._   to fmap._ : "paired (internal only)";
        connection connect fmap._   to fb;
    }

    #FpViewPresentation { name = "<*>"; }
    view diagram : FpIbdView {
        doc /*(<*>) :: F(a ⟶ b) ⟶ Fa ⟶ Fb — inside <*>: pair the two contexts, then fmap apply*/
        expose ap;
        render fpIbdDiagram;
    }
}
