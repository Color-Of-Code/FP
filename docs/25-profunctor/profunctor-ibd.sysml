// SysML v2 — profunctor IBD: the function that dimap returns (for plain functions)
// dimap :: (A' ⟶ A) ⟶ (B ⟶ B') ⟶ P A B ⟶ P A' B'      dimap f g h = g ∘ h ∘ f
//
// Reading guide:
//   • drawn for the archetypal profunctor, the function type P A B = A ⟶ B
//   • the «block» frame is the adapted function; its boundary ports are its call interface:
//     the new input x in, the new result out
//   • f, g and h are fixed (captured) when dimap builds the function — they live inside
//   • f runs BEFORE h (the contravariant side: it turns the new input A' into the A that
//     h expects) and g runs AFTER h (the covariant side: it turns h's B into B')
//   • h itself is untouched — dimap only wraps it on both ends

package ProfunctorSignature {
    private import FpDiagram::*;

    part def adapted {
        #FpNodePresentation { tooltip = "x : A' — actual parameter, supplied on every call of the adapted function"; }
        port in  x      : "A'";
        #FpNodePresentation { tooltip = "result : B' — what each call returns: g (h (f x))"; }
        port out result : "B'";

        #FpNodePresentation { role = "hof"; tooltip = "f : A' ⟶ A — pre-map (contravariant): adapts the new input to what h expects; fixed when dimap was applied"; }
        part f : "A' ⟶ A — captured";
        #FpNodePresentation { role = "hof"; tooltip = "h : A ⟶ B — the original profunctor (here a plain function), left unchanged"; }
        part h : "A ⟶ B — captured";
        #FpNodePresentation { role = "hof"; tooltip = "g : B ⟶ B' — post-map (covariant): adapts h's output to the new output type"; }
        part g : "B ⟶ B' — captured";

        #FpNodePresentation { role = "function"; tooltip = "Pre-map: turn the new input A' into the A that h expects."; }
        part pre : "f x" {
            port in  f : "A' ⟶ A";
            port in  a : "A'";
            port out _ : "A";
        }
        #FpNodePresentation { role = "function"; tooltip = "The original function, running on the adapted input."; }
        part run : "h a" {
            port in  h : "A ⟶ B";
            port in  a : "A";
            port out _ : "B";
        }
        #FpNodePresentation { role = "function"; tooltip = "Post-map: turn h's B into the new output type B'."; }
        part post : "g b" {
            port in  g : "B ⟶ B'";
            port in  b : "B";
            port out _ : "B'";
        }

        connection connect x       to pre.a : "new input";
        connection connect f       to pre.f : "contravariant";
        connection connect pre._   to run.a : "A (internal only)";
        connection connect h       to run.h : "unchanged";
        connection connect run._   to post.b : "B (internal only)";
        connection connect g       to post.g : "covariant";
        connection connect post._  to result;
    }

    #FpViewPresentation { name = "dimap"; }
    view diagram : FpIbdView {
        doc /*dimap :: (A' ⟶ A) ⟶ (B ⟶ B') ⟶ P A B ⟶ P A' B' — inside dimap (for functions): f adapts the input, h runs, g adapts the output*/
        expose adapted;
        render fpIbdDiagram;
    }
}
