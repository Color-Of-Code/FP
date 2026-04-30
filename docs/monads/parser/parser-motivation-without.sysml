// SysML v2 — Parser motivation: WITHOUT the Parser monad (bind)
//
// Each parser must accept the full remaining input and return both a
// value and the leftover string.  After every step the caller checks
// for null and forwards the leftover by hand.  Forgetting to use the
// fresh remainder is a silent bug that "still parses" but consumes
// the wrong characters.
//
// We use "Parser X" / "(X, String)" types here so the parallel with
// the with-monad diagram is visible: the type doesn't change — what
// differs is HOW the leftover-and-failure are handled (manual checks
// + manual rest-passing vs. automatic threading via bind).

package ParserMotivationWithout {

    action def ParseDigit {
        in  input  : String;
        out _      : "Maybe (Char, String)";
    }

    action def ParseLetter {
        in  rest   : String;
        out _      : "Maybe (Char, String)";
    }

    activity def DigitLetterWithout {
        // input
        object input : String;

        // two fallible parsers
        action parseDigit  : ParseDigit;
        action parseLetter : ParseLetter;

        // one Nothing-guard per step
        decision check1 : "Nothing?";
        decision check2 : "Nothing?";

        // all failure branches converge here
        merge failRail;

        // outputs
        object outResult : "((d, l), rest2)";
        object failed    : "Nothing";

        // happy path — leftover is unwrapped from the pair and threaded by hand
        flow from input        to parseDigit;
        flow from parseDigit   to check1      : "Maybe (Char, String)";
        flow from check1       to failRail    : "Nothing";
        flow from check1       to parseLetter : "Just (d, rest1) — pass rest1";

        flow from parseLetter  to check2      : "Maybe (Char, String)";
        flow from check2       to failRail    : "Nothing";
        flow from check2       to outResult   : "Just (l, rest2)";

        flow from failRail     to failed;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without bind: leftover threaded by hand; one Nothing guard per step"
    name  = "digitLetter"
    show input       as value
    show parseDigit  as function
    show parseLetter as function
    show outResult   as type
    show failed      as type
    tooltip input        = "input : String — the full input string, threaded through the whole chain."
    tooltip parseDigit   = "parseDigit(input) → Maybe (Char, String). Returns the consumed character and the leftover, or Nothing."
    tooltip parseLetter  = "parseLetter(rest1) → Maybe (Char, String). Must be called with the leftover from parseDigit, never the original input."
    tooltip check1       = "Guard #1: pattern-matches Maybe (Char, String). Skip and you'll feed Nothing to parseLetter — type error or worse, silent bug."
    tooltip check2       = "Guard #2: same pattern repeated. Skip and you'll return garbage."
    tooltip failRail     = "Any Nothing short-circuits the whole chain — both failure paths converge here."
    tooltip outResult    = "((d, l), rest2) — caller is responsible for unpacking the value and the remaining input."
    tooltip failed       = "Nothing — a parse failure, indistinguishable from any other Nothing."
}

