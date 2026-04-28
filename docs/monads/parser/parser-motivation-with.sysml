// SysML v2 — Parser motivation: WITH the Parser monad
//
// A parser is a function String → Maybe (a, String).  bind threads
// the remaining input automatically: the next parser starts where
// the previous one stopped, and a Nothing in any step short-circuits
// the whole chain.

package ParserMotivationWith {

    action def Digit {
        in  input  : String;
        out result : "Parser Char";
    }

    action def Letter {
        in  input  : String;
        out result : "Parser Char";
    }

    action def MakePair {
        in  d      : Char;
        in  l      : Char;
        out result : "Parser (Char, Char)";
    }

    activity def DigitLetterWith {
        action digit    : Digit;
        action letter   : Letter;
        action makePair : MakePair;
        object outResult      : "(value, rest)";

        flow from digit    to letter   : ">>= bind";
        flow from letter   to makePair : ">>= bind";
        flow from makePair to outResult      : "runParser";
    }
}

#diagram {
    type  = activity
    title = "With Parser: bind threads the remaining input automatically"
    name  = "digitLetter"
    show digit    as function
    show letter   as function
    show makePair as function
    show outResult      as type
    tooltip digit    = "digit :: Parser Char — consumes one digit, leaves the rest of the string in its state."
    tooltip letter   = "letter :: Parser Char — runs on the remaining input from digit; bind threads the leftover automatically."
    tooltip makePair = "pure (d, l) — lifts a plain pair back into the Parser monad."
    tooltip outResult      = "runParser supplies the input string and returns (value, rest) — or Nothing if any step failed."
}
