// SysML v2 — List pure: implementation activity
// pure :: a ⟶ List a
//
// Singleton list: pure x = [x]. The unit element of List bind.
// Wrapping in [] (empty list) would violate the left-identity law:
// pure a >>= f must equal f a, but [] >>= f = [].

package ListPureImpl {
    private import FpDiagram::*;

    action def Singleton {
        in  a    : a;
        out list : "List a";   // exactly one element
    }

    action def ListPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0       : a;
        #FpNodePresentation { role = "function"; tooltip = "Singleton: produce the one-element list [a0]. The empty list would absorb every subsequent bind and break left identity."; }
        action wrap     : Singleton;
        #FpNodePresentation { role = "type"; tooltip = "[a0] : List a — exactly one element. List pure is NOT the empty list."; }
        item listOut  : "List a";

        flow from a0  to wrap;
        flow from wrap to listOut : "[a0]";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ List a   (singleton list [a0], not the empty list) — also called: return, of, single*/
        expose ListPureProcess;
        render fpActivityDiagram;
    }
}

