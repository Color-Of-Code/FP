// SysML v2 — currying activity diagram
// Concept: curry :: ((a,b) ⟶ c) ⟶ (a ⟶ (b ⟶ c))
// Diagram type: activity — original function flows in as HOF token, produces specialised functions

package Function2Activity {

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
    activity def PartialApplication {
        object f  : "(a,b) ⟶ c";  // function, HOF input
        object xa : a;               // value to fix as first argument
        object xb : b;               // value to fix as second argument

        action applyA : PartialApply;   // produce f1a :: b ⟶ c
        action applyB : PartialApply;   // produce f1b :: a ⟶ c

        object f1a : "b ⟶ c";  // a fixed
        object f1b : "a ⟶ c";  // b fixed

        flow from f  to applyA : "apply a";
        flow from xa to applyA;
        flow from applyA to f1a;

        flow from f  to applyB : "apply b";
        flow from xb to applyB;
        flow from applyB to f1b;
    }

    // ── currying ──────────────────────────────────────────────────────────
    activity def Currying {
        object f2      : "(a,b) ⟶ c";      // function, HOF input
        action curry   : CurryOp;
        object curried : "a ⟶ (b ⟶ c)";  // curried form

        object a   : a;               // first argument applied later
        action applyA : PartialApply;
        object f1a : "b ⟶ c";        // specialised function

        flow from f2     to curry : "curry";
        flow from curry  to curried;
        flow from curried to applyA : "apply a";
        flow from a       to applyA;
        flow from applyA  to f1a;

        succession curry then applyA;
    }
}

#diagram {
    type  = activity
    title = "Partial application and currying"
    name  = "partial apply"
    render = PartialApplication
    show f      as hof
    show applyA as function
    show applyB as function
    show f1a    as function
    show f1b    as function
    tooltip f      = "f2 :: (a,b) ⟶ c — original function, flowing in as a data token (HOF)"
    tooltip applyA = "Partially apply a — captures a, returns b ⟶ c"
    tooltip applyB = "Partially apply b — captures b, returns a ⟶ c"
    tooltip f1a    = "f1a :: b ⟶ c — specialised function"
    tooltip f1b    = "f1b :: a ⟶ c — specialised function"
}
