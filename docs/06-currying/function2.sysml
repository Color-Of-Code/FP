// SysML v2 — currying activity diagram
// Concept: curry :: ((a,b) ⟶ c) ⟶ (a ⟶ (b ⟶ c))
// Diagram type: activity — original function flows in as HOF token, produces specialised functions

package Function2Activity {
    private import FpDiagram::*;

    action def PartialApply {
        in  f  : "(a,b) ⟶ c";  // function to partially apply, HOF input
        in  x  : a;               // argument to fix
        out f1 : "b ⟶ c";      // specialised function
    }

    action def CurryOp {
        in  f2     : "(a,b) ⟶ c";   // multi-arg function, HOF input
        out curried: "a ⟶ (b ⟶ c)"; // curried form
    }

    // ── partial application ────────────────────────────────────────────────
    action def PartialApplication {
        #FpNodePresentation { role = "hof"; tooltip = "f2 :: (a,b) ⟶ c — original function, flowing in as a data token (HOF)"; }
        item f  : "(a,b) ⟶ c";  // function, HOF input
        item xa : a;               // value to fix as first argument
        item xb : b;               // value to fix as second argument

        #FpNodePresentation { role = "function"; tooltip = "Partially apply a — captures a, returns b ⟶ c"; }

        action applyA : PartialApply;   // produce f1a :: b ⟶ c
        #FpNodePresentation { role = "function"; tooltip = "Partially apply b — captures b, returns a ⟶ c"; }
        action applyB : PartialApply;   // produce f1b :: a ⟶ c

        #FpNodePresentation { role = "function"; tooltip = "f1a :: b ⟶ c — specialised function"; }

        item f1a : "b ⟶ c";  // a fixed
        #FpNodePresentation { role = "function"; tooltip = "f1b :: a ⟶ c — specialised function"; }
        item f1b : "a ⟶ c";  // b fixed

        flow from f  to applyA : "apply a";
        flow from xa to applyA;
        flow from applyA to f1a;

        flow from f  to applyB : "apply b";
        flow from xb to applyB;
        flow from applyB to f1b;
    }

    // ── currying ──────────────────────────────────────────────────────────
    action def Currying {
        item f2      : "(a,b) ⟶ c";      // function, HOF input
        action curry   : CurryOp;
        item curried : "a ⟶ (b ⟶ c)";  // curried form

        item a   : a;               // first argument applied later
        #FpNodePresentation { role = "function"; tooltip = "Partially apply a — captures a, returns b ⟶ c"; }
        action applyA : PartialApply;
        #FpNodePresentation { role = "function"; tooltip = "f1a :: b ⟶ c — specialised function"; }
        item f1a : "b ⟶ c";        // specialised function

        flow from f2     to curry : "curry";
        flow from curry  to curried;
        flow from curried to applyA : "apply a";
        flow from a       to applyA;
        flow from applyA  to f1a;

        succession curry then applyA;
    }
    #FpViewPresentation { name = "partial apply"; }
    view diagram : FpActivityView {
        doc /*Partial application and currying*/
        expose PartialApplication;
        render fpActivityDiagram;
    }
}

