// SysML v2 — currying IBD: the function that curry returns
// curry :: ((a, b) ⟶ c) ⟶ (a ⟶ b ⟶ c)      curry f a b = f (a, b)
//
// Reading guide:
//   • the «block» frame is the curried function; its boundary ports are its call interface:
//     a arrives with the 1st call, b with the 2nd, the result is available after both
//   • f is fixed (captured) when curry builds the function — it lives inside, untouched
//   • the two separately delivered arguments are packed back into one pair for f — the only
//     thing curry changes is who delivers the arguments, and when

package CurrySignature {
    private import FpDiagram::*;

    part def curried {
        #FpNodePresentation { tooltip = "a : first argument — actual parameter of the 1st call: (curry f) a"; }
        port in  a      : "a";
        #FpNodePresentation { tooltip = "b : second argument — actual parameter of the 2nd call: ((curry f) a) b"; }
        port in  b      : "b";
        #FpNodePresentation { tooltip = "result : c — available only after both calls"; }
        port out result : "c";

        #FpNodePresentation { role = "hof"; tooltip = "f : (a, b) ⟶ c — fixed when curry was applied; takes both arguments at once, as a pair"; }
        part f : "(a, b) ⟶ c — captured";

        #FpNodePresentation { role = "function"; tooltip = "Pack the two separately delivered arguments into the pair that f expects."; }
        part pack : "(a, b)" {
            port in  a : "a";
            port in  b : "b";
            port out _ : "(a, b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "The original function, applied to the pair."; }
        part run : "f (a, b)" {
            port in  f : "(a, b) ⟶ c";
            port in  p : "(a, b)";
            port out _ : "c";
        }

        connection connect a       to pack.a : "1st call";
        connection connect b       to pack.b : "2nd call";
        connection connect pack._  to run.p : "pair (internal only)";
        connection connect f       to run.f : "captured";
        connection connect run._   to result;
    }

    #FpViewPresentation { name = "curry"; }
    view diagram : FpIbdView {
        doc /*curry :: ((a, b) ⟶ c) ⟶ (a ⟶ b ⟶ c) — inside curry: the two separately supplied arguments are packed into a pair for f*/
        expose curried;
        render fpIbdDiagram;
    }
}
