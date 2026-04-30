// SysML v2 — Parser motivation: WITH the Parser monad (bind + pure)
//
// A Parser is roughly  String → Maybe (a, String).  The producing
// functions DO NOT COMPOSE naturally:
//   digit    : Parser Char            (≡ String → Maybe (Char, String))
//   letter   : Parser Char
//   pair     : Char → Char → (Char, Char)   ← takes plain values
//
// Two combinators do all the work:
//   pure  : a → Parser a                            — succeed with a, consume nothing
//   (>>=) : Parser a → (a → Parser b) → Parser b
//
// digit produces a Parser; bind threads the remaining input AND
// short-circuits a Nothing in any step.  pure lifts the final pair
// back into Parser without consuming any more input.

package ParserMotivationWith {

    action def Digit {
        out _ : "Parser Char";
    }

    // pure : a → Parser a
    action def Pure {
        in  a : a;
        out _ : "Parser a";
    }

    // bind : Parser a → (a → Parser b) → Parser b
    action def Bind {
        in  ma : "Parser a";
        in  f  : "a ⟶ Parser b";
        out _  : "Parser b";
    }

    activity def DigitLetterWith {
        // entry: digit is itself a Parser (no input value)
        action digit       : Digit;

        // bind in letter as the next parser; the HOF captures d in scope
        // and runs letter — conceptually  λd. letter >>= λl. pure (d, l)
        object letterFn    : "Char ⟶ Parser (Char, Char)";
        action bindLetter  : Bind;

        // output
        object outResult   : "(value, rest)";

        // main flow runs through the bind nodes
        flow from digit       to bindLetter : "Parser Char";
        flow from bindLetter  to outResult  : "runParser";

        // the parsing continuation is supplied as the f argument
        flow from letterFn    to bindLetter;
    }
}

#diagram {
    type  = activity
    title = "With pure + bind: bind threads the remaining input and short-circuits failure"
    name  = "digitLetter"
    show digit       as function
    show bindLetter  as function
    show letterFn    as hof
    show outResult   as type
    tooltip digit       = "digit : Parser Char — consumes one digit, leaves the rest of the string in its state."
    tooltip bindLetter  = ">>= : runs letter on the input that digit left behind. Failure in either step short-circuits."
    tooltip letterFn    = "λd. letter >>= λl. pure (d, l). HOF argument — captures d and produces a Parser (Char, Char)."
    tooltip outResult   = "runParser supplies the input string and returns (value, rest) — or Nothing if any step failed."
}

