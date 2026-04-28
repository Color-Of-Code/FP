// SysML v2 — generic pure activity (chapter intro for monad)
// pure :: a ⟶ Ma
//
// The monadic lifting operation: take any plain value and place it into the
// monad context with no extra effect.  Each concrete monad realises this
// differently (Just for Maybe, Right for Either, [a] for List, return for IO,
// \s -> (a, s) for State, …) but the type-class signature is universal.

package MonadPureGeneric {

    action def Lift {
        in  a  : a;
        out Ma : Ma;
    }

    activity def PureFlow {
        object a0  : a;     // any plain value
        action lift : Lift;
        object Ma  : Ma;    // value embedded in the monad

        flow from a0  to lift;
        flow from lift to Ma;
    }
}

#diagram {
    type   = activity
    title  = "pure :: a ⟶ Ma   (lift a plain value into the monad — also called: return, of, unit, point)"
    name   = "pure"
    render = PureFlow
    show a0   as value
    show lift as function
    show Ma   as type
    tooltip a0   = "a0 — any plain value to be lifted into the monadic context."
    tooltip lift = "Embed a0 in the monad with no additional effect.  Per-monad realisation: Just a0 (Maybe), Right a0 (Either), [a0] (List), return a0 (IO), \\s -> (a0, s) (State), …"
    tooltip Ma   = "Ma — the same value wrapped in the minimal monadic context.  pure must satisfy the left/right identity laws with bind."
}
