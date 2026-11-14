// SysML v2 — IO monad IBD: type signature + bind contract
// (>>=) :: IO a ⟶ (a ⟶ IO b) ⟶ IO b
//
// IO a is a description (recipe) of a side-effectful computation.
// bind sequences two recipes: execute first, feed result to second.
// The structural shape is the simplest — what distinguishes IO is the
// semantics: values are descriptions of effects, not plain data.

package IOSignature {
    private import FpDiagram::*;

    part def IOBindContext {
        #FpNodePresentation { role = "type"; tooltip = "IO a — a description of a side-effectful computation. Nothing runs yet."; }
        part ia_val : "IO a";        // recipe: when executed, produces a (with side effects)
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ IO b) — given the result of running ia, produces the next IO action to run"; }
        part f_val  : "a ⟶ IO b";  // effectful function (HOF) — returns another recipe
        #FpNodePresentation { role = "function"; tooltip = "Build a new IO recipe that, when run by the runtime:\n1. executes ia to get a\n2. passes a to f to get IO b\n3. executes IO b\nOrder of effects = order of binds."; }
        part bind   : IOBindOp;
        #FpNodePresentation { role = "type"; tooltip = "IO b — the composed recipe. Effects of ia happen before effects of f(a)."; }
        part ib_val : "IO b";        // composed recipe: executes ia then f(a)

        connection connect ia_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to ib_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: IO a ⟶ (a ⟶ IO b) ⟶ IO b — also called: .then (Promises), >>=*/
        expose IOBindContext;
        render fpIbdDiagram;
    }
}

