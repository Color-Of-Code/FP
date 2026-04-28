// SysML v2 — monad IBD: type signature
// (>>=) :: Ma ⟶ (a ⟶ Mb) ⟶ Mb

package MonadSignature {

    part def BindContext {
        // inputs
        part ma_val : Ma;            // monadic value
        part f_val  : "a ⟶ Mb";    // continuation / monadic function (HOF)

        // the operation
        part bind   : BindOp;

        // output
        part mb_val : Mb;

        connection connect ma_val to bind;
        connection connect f_val  to bind;
        connection connect bind   to mb_val;
    }
}

#diagram {
    type  = ibd
    title = "(>>=) :: Ma ⟶ (a ⟶ Mb) ⟶ Mb"
    render = BindContext
    show ma_val as type
    show f_val  as hof
    show bind   as function
    show mb_val as type
    tooltip ma_val = "Ma — monadic value, provides unwrapped a to the continuation"
    tooltip f_val  = "(a ⟶ Mb) — the continuation: maps each a to a new monadic Mb"
    tooltip bind   = ">>= (bind): sequences two monadic actions, threading the value"
    tooltip mb_val = "Mb — final monadic result"
}
