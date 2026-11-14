// SysML v2 — composition IBD: what happens inside compose
// (∘) :: (b ⟶ c) ⟶ (a ⟶ b) ⟶ (a ⟶ c)      (g ∘ f) x = g (f x)
//
// Reading guide:
//   • the «block» frame is compose; its boundary ports are its whole call interface:
//     the two functions g and f in, the new function h out
//   • compose does not run anything — it builds h. Inside the block we see the body of h,
//     as it executes when h is finally called: x is h's parameter, supplied only then
//   • the wire between f and g carries b: f's output type must equal g's input type —
//     that is the one rule composition enforces
//   • the intermediate b exists only inside the block; callers of h never see it

package CompositionSignature {
    private import FpDiagram::*;

    part def compose {
        #FpNodePresentation { tooltip = "g : b ⟶ c — runs second; its input type must equal f's output type"; }
        port in  g : "b ⟶ c";
        #FpNodePresentation { tooltip = "f : a ⟶ b — runs first"; }
        port in  f : "a ⟶ b";
        #FpNodePresentation { tooltip = "h = g ∘ f : a ⟶ c — a new function; nothing has been applied yet"; }
        port out h : "a ⟶ c";

        #FpNodePresentation { role = "value"; tooltip = "The argument of h: supplied when h is called, not when compose builds it."; }
        part x : "a — supplied when h is called";

        #FpNodePresentation { role = "function"; tooltip = "Apply f to the argument: the first step of h."; }
        part run_f : "f x" {
            port in  f : "a ⟶ b";
            port in  a : "a";
            port out _ : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply g to the result of f: the second step of h. This is the only place where f's output meets g's input."; }
        part run_g : "g b" {
            port in  g : "b ⟶ c";
            port in  b : "b";
            port out _ : "c";
        }
        #FpNodePresentation { role = "function"; tooltip = "Abstract over x again: the whole body becomes the function h that compose returns."; }
        part wrap : "λx → c" {
            port in  _ : "c";
            port out _ : "a ⟶ c";
        }

        connection connect f        to run_f.f : "first";
        connection connect x        to run_f.a : "argument";
        connection connect run_f._  to run_g.b : "b (internal only)";
        connection connect g        to run_g.g : "second";
        connection connect run_g._  to wrap._ : "result";
        connection connect wrap._   to h;
    }

    #FpViewPresentation { name = "compose"; }
    view diagram : FpIbdView {
        doc /*(∘) :: (b ⟶ c) ⟶ (a ⟶ b) ⟶ (a ⟶ c) — inside compose: f runs first, its result b feeds g; b never leaves the block*/
        expose compose;
        render fpIbdDiagram;
    }
}
