// SysML v2 — Parser motivation: WITHOUT the Parser monad
//
// Each parser must accept the full remaining input and return both a
// value and the leftover string.  After every step the caller checks
// for null and forwards the leftover by hand.  Forgetting to use the
// fresh remainder is a silent bug that "still parses" but consumes
// the wrong characters.

package ParserMotivationWithout {

    action def ParseDigit {
        in  input  : String;
        out result : "(Char, String) | null";
    }

    action def ParseLetter {
        in  input  : String;
        out result : "(Char, String) | null";
    }

    activity def DigitLetterWithout {
        object input : String;

        action parseDigit  : ParseDigit;
        action parseLetter : ParseLetter;

        decision check1 : "null?";
        decision check2 : "null?";

        merge failRail;

        object outResult    : "((d, l), rest2)";
        object failed : "null";

        flow from input        to parseDigit;
        flow from parseDigit   to check1      : "(Char, String) | null";
        flow from check1       to failRail    : "null";
        flow from check1       to parseLetter : "(d, rest1)";

        flow from parseLetter  to check2      : "(Char, String) | null";
        flow from check2       to failRail    : "null";
        flow from check2       to outResult         : "((d, l), rest2)";

        flow from failRail     to failed;
    }
}

#diagram {
    type  = activity
    title = "Without Parser: remaining input threaded by hand"
    name  = "digitLetter"
    show input       as value
    show parseDigit  as function
    show parseLetter as function
    show outResult         as type
    show failed      as type
    tooltip input        = "input : String — the full input string, threaded through the whole chain."
    tooltip parseDigit   = "parseDigit(input) → (Char, String) or null.  Returns the consumed character and the leftover."
    tooltip parseLetter  = "parseLetter(rest1) → (Char, String) or null.  Must be called with the leftover from parseDigit, never the original input."
    tooltip check1       = "Null guard #1: skip and you'll feed null to parseLetter."
    tooltip check2       = "Null guard #2: skip and you'll return garbage."
    tooltip failRail     = "Any null short-circuits the whole chain."
    tooltip outResult          = "((d, l), rest2) — caller is responsible for unpacking the value and the remaining input."
    tooltip failed       = "null — a plausible parse failure value indistinguishable from a real returned value of null."
}
