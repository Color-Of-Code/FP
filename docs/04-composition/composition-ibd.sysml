// SysML v2 — composition IBD: the function that compose returns
// (∘) :: (b ⟶ c) ⟶ (a ⟶ b) ⟶ (a ⟶ c)      h = g ∘ f,   h x = g (f x)
//
// Reading guide:
//   • the «block» frame is the new function h; its boundary ports are its call interface:
//     the actual argument x in, the result out
//   • f and g are fixed (captured) when compose builds h — they live inside, not on the
//     boundary, exactly like the captured 5 in add5
//   • the wire between f and g carries b: f's output type must equal g's input type —
//     that is the one rule composition enforces
//   • the intermediate b exists only inside the block; callers of h never see it

package CompositionSignature {
    private import FpDiagram::*;

    part def composed {
        #FpNodePresentation { tooltip = "x : a — actual parameter, supplied on every call: h x"; }
        port in  x      : "a";
        #FpNodePresentation { tooltip = "result : c — what each call returns: h x = g (f x)"; }
        port out result : "c";

        #FpNodePresentation { role = "hof"; tooltip = "f : a ⟶ b — fixed when h was built; runs first"; }
        part f : "a ⟶ b — captured";
        #FpNodePresentation { role = "hof"; tooltip = "g : b ⟶ c — fixed when h was built; runs second. Its input type must equal f's output type."; }
        part g : "b ⟶ c — captured";

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

        connection connect f       to run_f.f : "captured";
        connection connect x       to run_f.a : "argument";
        connection connect run_f._ to run_g.b : "b (internal only)";
        connection connect g       to run_g.g : "captured";
        connection connect run_g._ to result;
    }

    #FpViewPresentation { name = "compose"; }
    view diagram : FpIbdView {
        doc /*(∘) :: (b ⟶ c) ⟶ (a ⟶ b) ⟶ (a ⟶ c) — inside compose: f runs first, its result b feeds g; b never leaves the block*/
        expose composed;
        render fpIbdDiagram;
    }
}
