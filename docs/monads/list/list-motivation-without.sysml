// SysML v2 — List motivation: WITHOUT the List monad
//
// Cartesian product written as a nested loop.  Each extra dimension
// adds another nesting level, another `for`, another append into a
// shared accumulator.  Indentation tracks dimension count.

package ListMotivationWithout {

    action def OuterLoop {
        in  xs   : "[A]";
        out x    : A;
    }

    action def InnerLoop {
        in  ys   : "[B]";
        out y    : B;
    }

    action def AppendPair {
        in  x      : A;
        in  y      : B;
        out result : "result : [(A, B)]";
    }

    activity def CartesianWithout {
        object xs : "[A]";
        object ys : "[B]";

        action outer  : OuterLoop;
        action inner  : InnerLoop;
        action append : AppendPair;

        object result : "[(A, B)]";

        flow from xs     to outer;
        flow from outer  to inner  : "for x in xs";
        flow from ys     to inner;
        flow from inner  to append : "for y in ys";
        flow from append to result : "result.append((x, y))";
    }
}

#diagram {
    type  = activity
    title = "Without List: one nested loop level per dimension"
    name  = "cartesian"
    show xs     as value
    show ys     as value
    show outer  as function
    show inner  as function
    show append as function
    show result as type
    tooltip xs     = "xs : [A] — the first list, iterated by the outer loop."
    tooltip ys     = "ys : [B] — the second list, iterated by the inner loop for every x."
    tooltip outer  = "for x in xs — outer loop opens scope for x."
    tooltip inner  = "for y in ys — inner loop nested inside; each extra dimension means one more nesting level."
    tooltip append = "result.append((x, y)) — manual mutation of a shared accumulator.  Easy to forget; easy to break."
    tooltip result = "[(A, B)] — the result list built by side effect.  Adding a 3rd dimension means rewriting the whole structure."
}
