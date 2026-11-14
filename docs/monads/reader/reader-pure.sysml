// SysML v2 — Reader pure: implementation activity
// pure :: a ⟶ Reader r a   ≡   pure a = \r -> a
//
// Build a Reader that ignores the environment r and returns a unchanged.
// This is precisely the constant function. Reader's pure must not consult
// r; doing so would couple the lifted value to the environment.

package ReaderPureImpl {
    private import FpDiagram::*;

    action def ConstReader {
        in  a  : a;
        out ra : "Reader r a";   // = \r -> a
    }

    action def ReaderPureProcess {
        #FpNodePresentation { role = "value"; tooltip = "a0 — any plain value."; }
        item a0   : a;
        #FpNodePresentation { role = "function"; tooltip = "ConstReader: build the function \\r -> a0. The environment is accepted but never inspected."; }
        action wrap : ConstReader;
        #FpNodePresentation { role = "type"; tooltip = "Reader r a = (r ⟶ a). Always returns a0 regardless of which environment is supplied at run time."; }
        item ra   : "Reader r a";

        flow from a0   to wrap;
        flow from wrap to ra : "\\r -> a0";
    }
    #FpViewPresentation { name = "pure"; }
    view diagram : FpActivityView {
        doc /*pure :: a ⟶ Reader r a   (constant reader: ignore r, return a0) — also called: return*/
        expose ReaderPureProcess;
        render fpActivityDiagram;
    }
}

