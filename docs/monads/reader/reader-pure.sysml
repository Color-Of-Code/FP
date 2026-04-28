// SysML v2 — Reader pure: implementation activity
// pure :: a ⟶ Reader r a   ≡   pure a = \r -> a
//
// Build a Reader that ignores the environment r and returns a unchanged.
// This is precisely the constant function. Reader's pure must not consult
// r; doing so would couple the lifted value to the environment.

package ReaderPureImpl {

    action def ConstReader {
        in  a  : a;
        out ra : "Reader r a";   // = \r -> a
    }

    activity def ReaderPureProcess {
        object a0   : a;
        action wrap : ConstReader;
        object ra   : "Reader r a";

        flow from a0   to wrap;
        flow from wrap to ra : "\\r -> a0";
    }
}

#diagram {
    type  = activity
    title = "pure :: a ⟶ Reader r a   (constant reader: ignore r, return a0) — also called: return"
    name  = "pure"
    show a0   as value
    show wrap as function
    show ra   as type
    tooltip a0   = "a0 — any plain value."
    tooltip wrap = "ConstReader: build the function \\r -> a0. The environment is accepted but never inspected."
    tooltip ra   = "Reader r a = (r ⟶ a). Always returns a0 regardless of which environment is supplied at run time."
}
