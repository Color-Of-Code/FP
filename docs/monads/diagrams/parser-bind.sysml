// SysML v2 — Parser bind: implementation activity
// Like State (threads remaining input) + Maybe (short-circuits on Nothing).
// Success: run p(input) → (a, rest); thread rest into f(a)(rest).
// Failure: p returns Nothing → f is skipped, Nothing propagates (like Maybe bind).

package ParserBindImpl {

    action def RunPA {
        in  pa    : "Parser a";  // String ⟶ Maybe (a, String)
        in  input : String;
        out a_val : a;           // success: parsed value
        out rest  : String;      // success: unconsumed input
        out fail  : Nothing;     // failure: input not consumed
    }

    action def ApplyF {
        in  a_val : a;
        in  f     : "a ⟶ Parser b";
        out pb    : "Parser b";
    }

    action def RunPB {
        in  pb    : "Parser b";
        in  rest  : String;      // remaining input from step 1 — NOT original input
        out b     : b;
        out rest2 : String;      // unconsumed input after both parsers
    }

    activity def ParserBindProcess {
        // ── success path ───────────────────────────────────────────────────
        object pa      : "Parser a";
        object f       : "a ⟶ Parser b";
        object input   : String;           // full input string
        action run_pa  : RunPA;
        object a_val   : a;                // parsed value
        object rest    : String;           // remaining input after pa consumed its prefix
        action apply_f : ApplyF;
        object pb      : "Parser b";
        action run_pb  : RunPB;
        object b       : b;
        object rest2   : String;           // remaining after both parsers

        // ── failure path ───────────────────────────────────────────────────
        object fail_in  : Nothing;         // pa returned Nothing
        object fail_out : Nothing;         // propagated — f never called

        // success path flows
        flow from pa      to run_pa;
        flow from input   to run_pa;
        flow from run_pa  to a_val;
        flow from run_pa  to rest;         // remaining input threaded to next parser
        flow from a_val   to apply_f;
        flow from f       to apply_f;
        flow from apply_f to pb;
        flow from pb      to run_pb;
        flow from rest    to run_pb;       // rest (not input!) flows to second parser
        flow from run_pb  to b;
        flow from run_pb  to rest2;

        // failure path: Nothing propagates unchanged — f is never called
        flow from fail_in to fail_out : "f skipped";

        succession run_pa then apply_f;
        succession apply_f then run_pb;
    }
}

#diagram {
    type  = activity
    title = "Parser bind: thread rest to f(a)  |  Nothing → Nothing  (f skipped)"
    name  = ">>="
    show pa       as type
    show f        as hof
    show input    as value
    show run_pa   as function
    show a_val    as value
    show rest     as value
    show apply_f  as function
    show pb       as type
    show run_pb   as function
    show b        as value
    show rest2    as value
    show fail_in  as type
    show fail_out as type
    tooltip pa       = "Parser a — a function String ⟶ Maybe (a, String): consumes a prefix, returns (a, rest) or Nothing"
    tooltip f        = "(a ⟶ Parser b) — the next parser, built from the parsed value a"
    tooltip input    = "String — the full input. pa consumes a prefix; rest is passed forward (like State monad)."
    tooltip run_pa   = "Run pa(input): on success produces (a, rest); on failure produces Nothing"
    tooltip a_val    = "a — the parsed value. Passed to f to build the next parser."
    tooltip rest     = "String — unconsumed input after pa ran. Flows to run_pb (not input). This is the State-like threading."
    tooltip apply_f  = "Apply f(a): build Parser b from the parsed value a"
    tooltip pb       = "Parser b — the second parser"
    tooltip run_pb   = "Run pb(rest): parse b from the REMAINING input, not from the original input"
    tooltip b        = "b — the final parsed value"
    tooltip rest2    = "String — input still unconsumed after both parsers ran"
    tooltip fail_in  = "Nothing — pa failed. No (a, rest) was produced."
    tooltip fail_out = "Nothing — propagated unchanged. f is never called. (Same short-circuit as Maybe bind.)"
}
