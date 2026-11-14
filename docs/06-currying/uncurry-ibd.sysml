// SysML v2 — currying IBD: the function that uncurry returns
// uncurry :: (a ⟶ b ⟶ c) ⟶ ((a, b) ⟶ c)      uncurry g (a, b) = g a b
//
// Reading guide:
//   • the «block» frame is the tupled function; its boundary ports are its call interface:
//     the pair p in, the result out
//   • g is fixed (captured) when uncurry builds the function — it lives inside
//   • the pair is taken apart, and g is applied in two stages — exactly the two calls a
//     curried function expects
//   • the function returned by the first stage exists only inside the block

package UncurrySignature {
    private import FpDiagram::*;

    part def uncurried {
        #FpNodePresentation { tooltip = "p : (a, b) — actual parameter, supplied on every call: h (x, y)"; }
        port in  p      : "(a, b)";
        #FpNodePresentation { tooltip = "result : c — what each call returns"; }
        port out result : "c";

        #FpNodePresentation { role = "hof"; tooltip = "g : a ⟶ b ⟶ c — fixed when uncurry was applied; takes the arguments one call at a time"; }
        part g : "a ⟶ b ⟶ c — captured";

        #FpNodePresentation { role = "function"; tooltip = "Take the pair apart into the two arguments g expects, one per call."; }
        part unpair : "(a, b)" {
            port in  _ : "(a, b)";
            port out a : "a";
            port out b : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "First call: g a returns a function still waiting for b."; }
        part stage1 : "g a" {
            port in  g : "a ⟶ b ⟶ c";
            port in  a : "a";
            port out _ : "b ⟶ c";
        }
        #FpNodePresentation { role = "function"; tooltip = "Second call: apply the returned function to b."; }
        part stage2 : "(g a) b" {
            port in  h : "b ⟶ c";
            port in  b : "b";
            port out _ : "c";
        }

        connection connect p         to unpair._ : "pair";
        connection connect g         to stage1.g : "captured";
        connection connect unpair.a  to stage1.a : "1st argument";
        connection connect stage1._  to stage2.h : "b ⟶ c (internal only)";
        connection connect unpair.b  to stage2.b : "2nd argument";
        connection connect stage2._  to result;
    }

    #FpViewPresentation { name = "uncurry"; }
    view diagram : FpIbdView {
        doc /*uncurry :: (a ⟶ b ⟶ c) ⟶ ((a, b) ⟶ c) — inside uncurry: the pair is taken apart and g is applied in two stages*/
        expose uncurried;
        render fpIbdDiagram;
    }
}
