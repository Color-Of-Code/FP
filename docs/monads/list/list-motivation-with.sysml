// SysML v2 — List motivation: WITH the List monad (bind + pure)
//
// In the list monad, bind is flatMap:
//   pure  : a → [a]                     — singleton list
//   (>>=) : [a] → (a → [b]) → [b]       — apply f to each element, concatenate
//
// A two-axis Cartesian product is naturally TWO nested binds plus a
// pure at the bottom:
//   xs >>= \x ->
//     ys >>= \y ->
//       pure (x, y)
//
// Adding a third axis is one new bind line — not a new nested loop
// level.  In the diagram each bind is its own action node and the
// per-element continuation is an HOF side-input.  The inner bind +
// pure live inside outerFn (annotated below).

package ListMotivationWith {

    // pure : a → [a]
    action def Pure {
        in  a : a;
        out _ : "[a]";
    }

    // bind : [a] → (a → [b]) → [b]
    action def Bind {
        in  ma : "[a]";
        in  f  : "a ⟶ [b]";
        out _  : "[b]";
    }

    activity def CartesianWith {
        // inputs
        object xs        : "[A]";
        object ys        : "[B]";

        // outer bind: xs >>= outerFn
        // outerFn = λx. ys >>= λy. pure (x, y)
        object outerFn   : "A ⟶ [(A, B)]";
        action bindOuter : Bind;

        // outerFn is itself built from an inner bind and pure;
        // shown here as side actions referenced by outerFn.
        action bindInner : Bind;
        object innerFn   : "B ⟶ [(A, B)]";
        action purePair  : Pure;

        // output
        object result    : "[(A, B)]";

        // main flow: the only thing on the linear path is xs → bindOuter → result
        flow from xs        to bindOuter : "[A]";
        flow from outerFn   to bindOuter;
        flow from bindOuter to result    : "[(A, B)]";

        // outerFn's body: ys >>= innerFn   (innerFn = λy. pure (x, y))
        flow from ys        to bindInner : "[B]";
        flow from innerFn   to bindInner;

        // innerFn's body: pure (x, y)
        flow from purePair  to result    : "(via inner bind)";
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "With pure + bind: nested binds = nested loops; one bind per Cartesian axis"
    name  = "cartesian"
    show xs        as value
    show ys        as value
    show bindOuter as function
    show bindInner as function
    show purePair  as function
    show outerFn   as hof
    show innerFn   as hof
    show result    as type
    tooltip xs        = "[A] — first list. Outer iteration."
    tooltip ys        = "[B] — second list. Inner iteration (under each x)."
    tooltip bindOuter = ">>= : applies outerFn to every element of xs and concatenates the results."
    tooltip bindInner = ">>= : the inner bind that lives inside outerFn — applies innerFn to every element of ys."
    tooltip purePair  = "pure : (A, B) → [(A, B)]. Lifts the single pair (x, y) into a singleton list."
    tooltip outerFn   = "λx. ys >>= λy. pure (x, y). HOF argument to the outer bind — its input is A, not [A]."
    tooltip innerFn   = "λy. pure (x, y). HOF argument to the inner bind — captures x from outerFn's scope."
    tooltip result    = "[(A, B)] — the Cartesian product as a flat list. One more axis = one more bind line."
}


