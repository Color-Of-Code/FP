// SysML v2 — List pure: implementation activity
// pure :: a ⟶ List a
//
// Singleton list: pure x = [x]. The unit element of List bind.
// Wrapping in [] (empty list) would violate the left-identity law:
// pure a >>= f must equal f a, but [] >>= f = [].

package ListPureImpl {

    action def Singleton {
        in  a    : a;
        out list : "List a";   // exactly one element
    }

    activity def ListPureProcess {
        object a0       : a;
        action wrap     : Singleton;
        object listOut  : "List a";

        flow from a0  to wrap;
        flow from wrap to listOut : "[a0]";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ List a   (singleton list [a0], not the empty list) — also called: return, of, single"
    name  = "pure"
    show a0      as value
    show wrap    as function
    show listOut as type
    tooltip a0      = "a0 — any plain value."
    tooltip wrap    = "Singleton: produce the one-element list [a0]. The empty list would absorb every subsequent bind and break left identity."
    tooltip listOut = "[a0] : List a — exactly one element. List pure is NOT the empty list."
}
