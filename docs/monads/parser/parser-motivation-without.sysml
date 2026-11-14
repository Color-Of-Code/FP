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
    private import FpDiagram::*;

    action def ParseDigit {
        in  input  : String;
        out _      : "Maybe (Char, String)";
    }

    action def ParseLetter {
        in  rest   : String;
        out _      : "Maybe (Char, String)";
    }

    action def DigitLetterWithout {
        // input
        #FpNodePresentation { role = "value"; tooltip = "input : String — the full input string, threaded through the whole chain."; }
        item input : String;

        // two fallible parsers
        #FpNodePresentation { role = "function"; tooltip = "parseDigit(input) → Maybe (Char, String). Returns the consumed character and the leftover, or Nothing."; }
        action parseDigit  : ParseDigit;
        #FpNodePresentation { role = "function"; tooltip = "parseLetter(rest1) → Maybe (Char, String). Must be called with the leftover from parseDigit, never the original input."; }
        action parseLetter : ParseLetter;

        // one Nothing-guard per step
        #FpNodePresentation { tooltip = "Guard #1: pattern-matches Maybe (Char, String). Skip and you'll feed Nothing to parseLetter — type error or worse, silent bug."; }
        decide check1 : "Nothing?";
        #FpNodePresentation { tooltip = "Guard #2: same pattern repeated. Skip and you'll return garbage."; }
        decide check2 : "Nothing?";

        // all failure branches converge here
        #FpNodePresentation { tooltip = "Any Nothing short-circuits the whole chain — both failure paths converge here."; }
        merge failRail;

        // outputs
        #FpNodePresentation { role = "type"; tooltip = "((d, l), rest2) — caller is responsible for unpacking the value and the remaining input."; }
        item outResult : "((d, l), rest2)";
        #FpNodePresentation { role = "type"; tooltip = "Nothing — a parse failure, indistinguishable from any other Nothing."; }
        item failed    : "Nothing";

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
    #FpViewPresentation { name = "digitLetter"; }
    view diagram : FpActivityView {
        doc /*Without bind: leftover threaded by hand; one Nothing guard per step*/
        expose DigitLetterWithout;
        render fpActivityDiagram;
    }
}

