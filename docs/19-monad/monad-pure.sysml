// SysML v2 — generic pure activity (chapter intro for monad)
// pure :: a ⟶ Ma
//
// The monadic lifting operation: take any plain value and place it into the
// monad context with no extra effect.  Each concrete monad realises this
// differently (Just for Maybe, Right for Either, [a] for List, return for IO,
// \s -> (a, s) for State, …) but the type-class signature is universal.

package MonadPureGeneric {
    private import FpDiagram::*;

    action def Lift {
        in  a  : a;
        out Ma : Ma;
    }

    action def PureFlow {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value to be lifted into the monadic context."; }
        item a0  : a;     // any plain value
        #FpNodePresentation { role = "function"; tooltip = "Embed a0 in the monad with no additional effect.  Per-monad realisation: Just a0 (Maybe), Right a0 (Either), [a0] (List), return a0 (IO), \\s -> (a0, s) (State), …"; }
        action lift : Lift;
        #FpNodePresentation { role = "type"; tooltip = "Ma — the same value wrapped in the minimal monadic context.  pure must satisfy the left/right identity laws with bind."; }
        item Ma  : Ma;    // value embedded in the monad

        flow from a0  to lift;
        flow from lift to Ma;
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Ma   (lift a plain value into the monad — also called: return, of, unit, point)*/
        expose PureFlow;
        render fpActivityDiagram;
    }
}

