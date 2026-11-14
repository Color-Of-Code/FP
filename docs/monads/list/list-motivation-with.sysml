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
    private import FpDiagram::*;

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

    action def CartesianWith {
        // inputs
        #FpNodePresentation { role = "value"; tooltip = "[A] — first list. Outer iteration."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item xs        : "[A]";
        #FpNodePresentation { role = "value"; tooltip = "[B] — second list. Inner iteration (under each x)."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }
        item ys        : "[B]";

        // outer bind: xs >>= outerFn
        // outerFn = λx. ys >>= λy. pure (x, y)
        #FpNodePresentation { role = "hof"; tooltip = "λx. ys >>= λy. pure (x, y). HOF argument to the outer bind — its input is A, not [A]."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "2"; }
        item outerFn   : "A ⟶ [(A, B)]";
        #FpNodePresentation { role = "function"; tooltip = ">>= : applies outerFn to every element of xs and concatenates the results."; laneId = "monad"; laneLabel = "List monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action bindOuter : Bind;

        // outerFn is itself built from an inner bind and pure;
        // shown here as side actions referenced by outerFn.
        #FpNodePresentation { role = "function"; tooltip = ">>= : the inner bind that lives inside outerFn — applies innerFn to every element of ys."; laneId = "monad"; laneLabel = "List monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindInner : Bind;
        #FpNodePresentation { role = "hof"; tooltip = "λy. pure (x, y). HOF argument to the inner bind — captures x from outerFn's scope."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "3"; }
        item innerFn   : "B ⟶ [(A, B)]";
        #FpNodePresentation { role = "function"; tooltip = "pure : (A, B) → [(A, B)]. Lifts the single pair (x, y) into a singleton list."; laneId = "monad"; laneLabel = "List monad"; laneOrder = "1"; laneMemberOrder = "2"; }
        action purePair  : Pure;

        // output
        #FpNodePresentation { role = "type"; tooltip = "[(A, B)] — the Cartesian product as a flat list. One more axis = one more bind line."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "4"; }
        item result    : "[(A, B)]";

        // main flow: the only thing on the linear path is xs → bindOuter → result
        flow from xs        to bindOuter : "[A]";
        flow from outerFn   to bindOuter;
        flow from bindOuter to result    : "[(A, B)]";

        // outerFn's body: ys >>= innerFn   (innerFn = λy. pure (x, y))
        flow from ys        to bindInner : "[B]";
        flow from innerFn   to bindInner;

        // innerFn's body: pure (x, y)
        flow from purePair  to result    : "(via inner bind)";

        // ── Swimlanes ───────────────────────────────────────────────────────


    }
    #FpViewPresentation { name = "cartesian"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: nested binds = nested loops; one bind per Cartesian axis*/
        expose CartesianWith;
        render fpActivityDiagram;
    }
}

