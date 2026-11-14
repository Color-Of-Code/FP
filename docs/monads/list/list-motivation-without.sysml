// SysML v2 — List motivation: WITHOUT the List monad (bind)
//
// Cartesian product written as a nested loop.  Each extra dimension
// adds another nesting level, another `for`, another append into a
// shared accumulator.  Indentation tracks dimension count; the result
// list is built by side effect.

package ListMotivationWithout {
    private import FpDiagram::*;

    action def OuterLoop {
        in  xs : "[A]";
        out _  : A;
    }

    action def InnerLoop {
        in  ys : "[B]";
        out _  : B;
    }

    action def AppendPair {
        in  x : A;
        in  y : B;
        out _ : "[(A, B)]";
    }

    action def CartesianWithout {
        // inputs
        #FpNodePresentation { role = "value"; tooltip = "xs : [A] — the first list, iterated by the outer loop."; }
        item xs : "[A]";
        #FpNodePresentation { role = "value"; tooltip = "ys : [B] — the second list, iterated by the inner loop for every x."; }
        item ys : "[B]";

        // two nested loops + a manual append into a shared accumulator
        #FpNodePresentation { role = "function"; tooltip = "for x in xs — outer loop opens scope for x."; }
        action outer  : OuterLoop;
        #FpNodePresentation { role = "function"; tooltip = "for y in ys — inner loop nested inside; each extra dimension means one more nesting level."; }
        action inner  : InnerLoop;
        #FpNodePresentation { role = "function"; tooltip = "result.append((x, y)) — manual mutation of a shared accumulator. Easy to forget; easy to break."; }
        action append : AppendPair;

        // output
        #FpNodePresentation { role = "type"; tooltip = "[(A, B)] — the result list built by side effect. Adding a 3rd dimension means rewriting the whole structure."; }
        item result : "[(A, B)]";

        flow from xs     to outer;
        flow from outer  to inner  : "for x in xs";
        flow from ys     to inner;
        flow from inner  to append : "for y in ys";
        flow from append to result : "result.append((x, y))";
    }
    #FpViewPresentation { name = "cartesian"; }
    view diagram : FpActivityView {
        doc /*Without bind: one nested loop level per Cartesian dimension*/
        expose CartesianWithout;
        render fpActivityDiagram;
    }
}

