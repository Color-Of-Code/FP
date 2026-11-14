// SysML v2 — Reader monad IBD: type signature + bind contract
// (>>=) :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b
//
// The extra node r_env shows the key structural difference from Maybe/Either/List:
// the same environment r is threaded into BOTH inputs of bind and is visible in
// the output type — it is never consumed, never modified, just shared.

package ReaderSignature {
    private import FpDiagram::*;

    part def ReaderBindContext {
        #FpNodePresentation { role = "type"; tooltip = "Reader r a — a computation waiting for env r; when run with r it produces a"; }
        part ra_val : "Reader r a";        // r ⟶ a — a suspended computation
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Reader r b) — continuation: given a, produces a new computation waiting for r"; }
        part f_val  : "a ⟶ Reader r b";  // effectful function (HOF)
        #FpNodePresentation { role = "value"; tooltip = "r — the shared read-only environment. bind supplies THE SAME r to ra and to f(a). It is never modified."; }
        part r_env  : r;                   // shared read-only environment
        #FpNodePresentation { role = "function"; tooltip = "bind ra f = \\r -> f (ra r) r\nRun ra with env r to get a. Pass a to f. Run f(a) with the SAME env r."; }
        part bind   : ReaderBindOp;
        #FpNodePresentation { role = "type"; tooltip = "Reader r b — the composed computation; when run with r it produces b"; }
        part rb_val : "Reader r b";        // r ⟶ b — result computation

        connection connect ra_val to bind;
        connection connect f_val  to bind;
        connection connect r_env  to bind;  // env supplied to both ra and f(a)
        connection connect bind   to rb_val;
    }
    view diagram : FpIbdView {
        doc /*bind :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b — also called: flatMap, >>=*/
        expose ReaderBindContext;
        render fpIbdDiagram;
    }
}

