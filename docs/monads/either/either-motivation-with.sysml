// SysML v2 — Either motivation: WITH the Either monad
//
// Each step returns Either e a.  bind (>>=) inspects the constructor: a
// Left short-circuits the whole chain unchanged; only Right values feed
// the next step.  No explicit error checks anywhere in the pipeline.

package EitherMotivationWith {

    action def Parse {
        in  raw  : String;
        out result : "Either e Parsed";
    }

    action def Validate {
        in  parsed : Parsed;
        out result : "Either e Valid";
    }

    action def Save {
        in  valid : Valid;
        out result : "Either e Saved";
    }

    activity def ParseValidateSaveWith {
        object raw     : String;

        action parse    : Parse;
        object eParsed  : "Either e Parsed";

        action validate : Validate;
        object eValid   : "Either e Valid";

        action save     : Save;
        object eSaved   : "Either e Saved";

        flow from raw       to parse;
        flow from parse     to eParsed;
        flow from eParsed   to validate : ">>= bind";
        flow from validate  to eValid;
        flow from eValid    to save     : ">>= bind";
        flow from save      to eSaved;
    }
}

#diagram {
    type  = activity
    title = "With Either: bind propagates Left automatically"
    name  = "parseValidateSave"
    show raw      as value
    show parse    as function
    show validate as function
    show save     as function
    show eParsed  as type
    show eValid   as type
    show eSaved   as type
    tooltip raw      = "The raw input — for example a request body or untrusted user data."
    tooltip parse    = "parse(raw) → Either e Parsed.  Returns Right parsed on success or Left e on a parse error."
    tooltip validate = "validate(parsed) → Either e Valid.\nbind skips this step entirely if parse returned Left — the original error flows through unchanged."
    tooltip save     = "save(valid) → Either e Saved.\nbind skips this if any earlier step returned Left."
    tooltip eParsed  = "Either e Parsed — Right parsed or Left propagated from parse."
    tooltip eValid   = "Either e Valid — Right valid or Left propagated from any earlier step."
    tooltip eSaved   = "Either e Saved — final outcome.  Right on the happy path; the very first Left otherwise."
}
