// SysML v2 — Either motivation: WITHOUT the Either monad
//
// Every step may return an error code (or throw, or return a tagged
// union the caller must inspect).  After every call the caller writes
// the same conditional "is this an error?" boilerplate; one missed
// check silently feeds garbage into the next step.  Three checks
// converge on a shared error-return rail.
//
// Style: the action's output type and the decision branch label carry
// the type information directly on the flow edges; no intermediate
// object boxes for the tagged result.

package EitherMotivationWithout {

    action def Parse {
        in  raw    : String;
        out result : "Parsed | Error";
    }

    action def Validate {
        in  parsed : Parsed;
        out result : "Valid | Error";
    }

    action def Save {
        in  valid  : Valid;
        out result : "Saved | Error";
    }

    activity def ParseValidateSaveWithout {
        object raw : String;

        // three fallible steps
        action parse    : Parse;
        action validate : Validate;
        action save     : Save;

        // one error-guard per step — each is the pattern-match
        decision checkParse    : "err?";
        decision checkValidate : "err?";
        decision checkSave     : "err?";

        // all error branches converge here
        merge errorRail;

        // outputs
        object errOut : "Error";
        object saved  : "Saved";

        // happy path
        flow from raw          to parse;
        flow from parse        to checkParse    : "Parsed | Error";
        flow from checkParse   to errorRail     : "Error";
        flow from checkParse   to validate      : "parsed : Parsed";

        flow from validate     to checkValidate : "Valid | Error";
        flow from checkValidate to errorRail    : "Error";
        flow from checkValidate to save         : "valid : Valid";

        flow from save         to checkSave     : "Saved | Error";
        flow from checkSave    to errorRail     : "Error";
        flow from checkSave    to saved         : "saved : Saved";

        flow from errorRail    to errOut;
    }
}

#diagram {
    type  = activity
    title = "Without Either: explicit error guard at every step"
    name  = "parseValidateSave"
    show raw      as value
    show parse    as function
    show validate as function
    show save     as function
    show errOut   as type
    show saved    as value
    tooltip raw            = "The raw input — for example a request body or untrusted user data."
    tooltip parse          = "parse(raw) — may return Error if the input is malformed."
    tooltip validate       = "validate(parsed) — may return Error if a business rule is violated."
    tooltip save           = "save(valid) — may return Error on a database / IO failure."
    tooltip checkParse     = "Error guard #1: pattern-matches Parsed | Error.  The error branch joins errorRail; the value branch carries 'parsed : Parsed' to validate."
    tooltip checkValidate  = "Error guard #2: same pattern repeated.  Skipping this is a latent bug."
    tooltip checkSave      = "Error guard #3: yet another check.  Business logic is buried in guards."
    tooltip errorRail      = "Any Error terminates the chain here — three separate error paths converge."
    tooltip errOut         = "Error — returned when any step failed.  Caller must also inspect this and decide what to do."
    tooltip saved          = "Saved — the happy-path result, reached only when all three checks pass."
}
