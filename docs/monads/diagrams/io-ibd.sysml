// SysML v2 — IO monad IBD: type signature + bind contract
// (>>=) :: IO a ⟶ (a ⟶ IO b) ⟶ IO b
//
// IO a is a description (recipe) of a side-effectful computation.
// bind sequences two recipes: execute first, feed result to second.
// The structural shape is the simplest — what distinguishes IO is the
// semantics: values are descriptions of effects, not plain data.

package IOSignature {

    part def IOBindContext {
        part ia_val : "IO a";        // recipe: when executed, produces a (with side effects)
        part f_val  : "a ⟶ IO b";  // effectful function (HOF) — returns another recipe
        part bind   : IOBindOp;
        part ib_val : "IO b";        // composed recipe: executes ia then f(a)

        connection connect ia_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to ib_val;
    }
}

#diagram {
    type  = ibd
    title = "(>>=) :: IO a ⟶ (a ⟶ IO b) ⟶ IO b"
    render = IOBindContext
    show ia_val as type
    show f_val  as hof
    show bind   as function
    show ib_val as type
    tooltip ia_val = "IO a — a description of a side-effectful computation. Nothing runs yet."
    tooltip f_val  = "(a ⟶ IO b) — given the result of running ia, produces the next IO action to run"
    tooltip bind   = "Build a new IO recipe that, when run by the runtime:\n1. executes ia to get a\n2. passes a to f to get IO b\n3. executes IO b\nOrder of effects = order of binds."
    tooltip ib_val = "IO b — the composed recipe. Effects of ia happen before effects of f(a)."
}
