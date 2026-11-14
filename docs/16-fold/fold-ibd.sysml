// SysML v2 — fold IBD: what happens inside fold
// fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ [a] ⟶ b
//   fold f z []       = z
//   fold f z (x:rest) = fold f (f z x) rest
//
// Reading guide:
//   • the «block» frame is fold; its boundary ports are its whole call interface:
//     the combining function f, the initial accumulator init, the list xs, the result
//   • a case split on the list decides everything: an empty list stops and returns the
//     accumulator; otherwise f combines the accumulator with the head
//   • the recursive call is fold itself, applied to the new accumulator and the shorter
//     tail — f is passed along unchanged and the list gets shorter on every round
//   • the intermediate accumulator exists only inside the block

package FoldSignature {
    private import FpDiagram::*;

    part def fold {
        #FpNodePresentation { tooltip = "f : b ⟶ a ⟶ b — combining function: takes accumulator and element, returns the new accumulator"; }
        port in  f      : "b ⟶ a ⟶ b";
        #FpNodePresentation { tooltip = "init : b — initial accumulator, the \"zero\" of the fold"; }
        port in  init   : "b";
        #FpNodePresentation { tooltip = "xs : [a] — the input list, consumed one element per round"; }
        port in  xs     : "[a]";
        #FpNodePresentation { tooltip = "result : b — the final accumulated value"; }
        port out result : "b";

        #FpNodePresentation { role = "function"; tooltip = "Pattern match on the list.\n[]      → the 'nil' exit fires: nothing left to combine\nx : rest → head x and tail rest leave separately"; }
        part split : "case xs of" {
            port in  _    : "[a]";
            port out nil  : "[]";
            port out x    : "a";
            port out rest : "[a]";
        }
        #FpNodePresentation { role = "function"; tooltip = "Combine the accumulator with the head: f acc x gives the next accumulator."; }
        part step : "f acc x" {
            port in  f   : "b ⟶ a ⟶ b";
            port in  acc : "b";
            port in  x   : "a";
            port out _   : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "The recursive call: fold itself, with the same f, the new accumulator and the shorter tail."; }
        part again : "fold f acc' rest" {
            port in  f    : "b ⟶ a ⟶ b";
            port in  acc  : "b";
            port in  rest : "[a]";
            port out _    : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Base case: the list is exhausted, the accumulator is the result."; }
        part stop : "return acc" {
            port in  nil : "[]";
            port in  acc : "b";
            port out _   : "b";
        }

        connection connect xs        to split._ : "list";
        connection connect f         to step.f : "combiner";
        connection connect init      to step.acc : "accumulator";
        connection connect split.x   to step.x : "head";
        connection connect step._    to again.acc : "acc' (internal only)";
        connection connect f         to again.f : "unchanged";
        connection connect split.rest to again.rest : "shorter tail";
        connection connect split.nil to stop.nil : "empty";
        connection connect init      to stop.acc : "accumulator";
        connection connect again._   to result;
        connection connect stop._    to result;
    }

    #FpViewPresentation { name = "fold"; }
    view diagram : FpIbdView {
        doc /*fold :: (b ⟶ a ⟶ b) ⟶ b ⟶ [a] ⟶ b — inside fold: an empty list returns the accumulator; otherwise f combines it with the head and fold recurses on the tail*/
        expose fold;
        render fpIbdDiagram;
    }
}
