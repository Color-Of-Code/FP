// SysML v2 — Either motivation: WITHOUT the Either monad (bind)
//
// Every step in the chain returns Either e X.  The caller must insert
// an explicit Left-guard decision after each step; one missed guard
// silently feeds garbage into the next step.  All three failure paths
// converge on a shared error rail.
//
// We use "Either e X" here (same as the with-monad diagram) to
// highlight that the type is identical — what differs is HOW you
// handle it: manual case/match vs. automatic bind short-circuiting.

package EitherMotivationWithout {

    action def Parse {
        in  raw    : String;
        out _      : "Either e Parsed";
    }

    action def Validate {
        in  parsed : Parsed;
        out _      : "Either e Valid";
    }

    action def Save {
        in  valid  : Valid;
        out _      : "Either e Saved";
    }

    activity def ParseValidateSaveWithout {
        // input
        object raw : String;

        // three fallible steps
        action parse    : Parse;
        action validate : Validate;
        action save     : Save;

        // one Left-guard per step — each pattern-matches its predecessor's output
        decision checkParse    : "Left?";
        decision checkValidate : "Left?";
        decision checkSave     : "Left?";

        // all Left branches converge here
        merge errorRail;

        // outputs
        object errOut : "Left e";
        object saved  : "Right Saved";

        // happy path
        flow from raw           to parse;
        flow from parse         to checkParse    : "Either e Parsed";
        flow from checkParse    to errorRail     : "Left e";
        flow from checkParse    to validate      : "Right parsed";

        flow from validate      to checkValidate : "Either e Valid";
        flow from checkValidate to errorRail     : "Left e";
        flow from checkValidate to save          : "Right valid";

        flow from save          to checkSave     : "Either e Saved";
        flow from checkSave     to errorRail     : "Left e";
        flow from checkSave     to saved         : "Right saved";

        flow from errorRail     to errOut;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without bind: explicit Left guard at every step"
    name  = "parseValidateSave"
    show raw      as value
    show parse    as function
    show validate as function
    show save     as function
    show errOut   as type
    show saved    as value
    tooltip raw            = "Raw input — for example a request body or untrusted user data."
    tooltip parse          = "parse(raw) → Either e Parsed. Returns Right parsed on success or Left e on a parse error."
    tooltip validate       = "validate(parsed) → Either e Valid. May return Left if a business rule is violated."
    tooltip save           = "save(valid) → Either e Saved. May return Left on a database / IO failure."
    tooltip checkParse     = "Guard #1: pattern-matches Either e Parsed. The Right branch unwraps parsed for validate; Left joins errorRail."
    tooltip checkValidate  = "Guard #2: same pattern repeated. Skipping this is a latent bug."
    tooltip checkSave      = "Guard #3: yet another check. Business logic is buried in guards."
    tooltip errorRail      = "Any Left terminates the chain here — three separate failure paths converge."
    tooltip errOut         = "Left e — returned when any step failed. Caller must also inspect this."
    tooltip saved          = "Right Saved — the happy-path result, reached only when all three checks pass."
}

