// SysML v2 — Parser bind: implementation activity
// Like State (threads remaining input) + Maybe (short-circuits on Nothing).
// Success: run p(input) → (a, rest); thread rest into f(a)(rest).
// Failure: p returns Nothing → f is skipped, Nothing propagates (like Maybe bind).

package ParserBindImpl {
    private import FpDiagram::*;

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

    action def ParserBindProcess {
        // ── success path ───────────────────────────────────────────────────
        #FpNodePresentation { role = "type"; tooltip = "Parser a — a function String ⟶ Maybe (a, String): consumes a prefix, returns (a, rest) or Nothing"; }
        item pa      : "Parser a";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Parser b) — the next parser, built from the parsed value a"; }
        item f       : "a ⟶ Parser b";
        #FpNodePresentation { role = "value"; tooltip = "String — the full input. pa consumes a prefix; rest is passed forward (like State monad)."; }
        item input   : String;           // full input string
        #FpNodePresentation { role = "function"; tooltip = "Run pa(input): on success produces (a, rest); on failure produces Nothing"; }
        action run_pa  : RunPA;
        #FpNodePresentation { role = "value"; tooltip = "a — the parsed value. Passed to f to build the next parser."; }
        item a_val   : a;                // parsed value
        #FpNodePresentation { role = "value"; tooltip = "String — unconsumed input after pa ran. Flows to run_pb (not input). This is the State-like threading."; }
        item rest    : String;           // remaining input after pa consumed its prefix
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a): build Parser b from the parsed value a"; }
        action apply_f : ApplyF;
        #FpNodePresentation { role = "type"; tooltip = "Parser b — the second parser"; }
        item pb      : "Parser b";
        #FpNodePresentation { role = "function"; tooltip = "Run pb(rest): parse b from the REMAINING input, not from the original input"; }
        action run_pb  : RunPB;
        #FpNodePresentation { role = "value"; tooltip = "b — the final parsed value"; }
        item b       : b;
        #FpNodePresentation { role = "value"; tooltip = "String — input still unconsumed after both parsers ran"; }
        item rest2   : String;           // remaining after both parsers

        // ── failure path ───────────────────────────────────────────────────
        #FpNodePresentation { role = "type"; tooltip = "Nothing — pa failed. No (a, rest) was produced."; }
        item fail_in  : Nothing;         // pa returned Nothing
        #FpNodePresentation { role = "type"; tooltip = "Nothing — propagated unchanged. f is never called. (Same short-circuit as Maybe bind.)"; }
        item fail_out : Nothing;         // propagated — f never called

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
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*Parser bind: thread rest to f(a)  |  Nothing → Nothing  (f skipped) — also called: flatMap, Bind, >>=*/
        expose ParserBindProcess;
        render fpActivityDiagram;
    }
}

