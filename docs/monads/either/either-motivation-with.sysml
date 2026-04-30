// SysML v2 — Either motivation: WITH the Either monad (bind + pure)
//
// The fallible functions DO NOT COMPOSE naturally:
//   parse    : String → Either e Parsed
//   validate : Parsed → Either e Valid     ← expects Parsed, not Either e Parsed
//   save     : Valid  → Either e Saved     ← expects Valid,  not Either e Valid
//
// Two combinators do all the work:
//   pure  : a → Either e a                          — lift a plain value
//   (>>=) : Either e a → (a → Either e b) → Either e b
//
// pure starts the chain by lifting the raw String into Either.  Every
// subsequent step is bind applied to an Either value and the next
// fallible function (passed in as an HOF argument).  All steps have
// the same shape; Left short-circuits the whole chain unchanged.

package EitherMotivationWith {

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

    // pure : a → Either e a
    action def Pure {
        in  a : a;
        out _ : "Either e a";
    }

    // bind : Either e a → (a → Either e b) → Either e b
    action def Bind {
        in  ma : "Either e a";
        in  f  : "a ⟶ Either e b";
        out _  : "Either e b";
    }

    activity def ParseValidateSaveWith {
        // input
        object raw          : String;

        // lift the plain String into Either — entry point of the chain
        action pureRaw      : Pure;

        // each subsequent step is bind + a fallible function (HOF argument)
        object parseFn      : "String ⟶ Either e Parsed";
        action bindParse    : Bind;

        object validateFn   : "Parsed ⟶ Either e Valid";
        action bindValidate : Bind;

        object saveFn       : "Valid ⟶ Either e Saved";
        action bindSave     : Bind;

        // output
        object eSaved       : "Either e Saved";

        // main flow runs through the bind nodes
        flow from raw          to pureRaw;
        flow from pureRaw      to bindParse    : "Either e String";
        flow from bindParse    to bindValidate : "Either e Parsed";
        flow from bindValidate to bindSave     : "Either e Valid";
        flow from bindSave     to eSaved       : "Either e Saved";

        // each fallible function is supplied to its bind as the f argument
        flow from parseFn      to bindParse;
        flow from validateFn   to bindValidate;
        flow from saveFn       to bindSave;
    }
}

#diagram {
    type  = activity
    title = "With pure + bind: Left propagates automatically; every step has the same shape"
    name  = "parseValidateSave"
    show raw          as value
    show pureRaw      as function
    show bindParse    as function
    show bindValidate as function
    show bindSave     as function
    show parseFn      as hof
    show validateFn   as hof
    show saveFn       as hof
    show eSaved       as type
    tooltip raw          = "Raw input — for example a request body or untrusted user data."
    tooltip pureRaw      = "pure : String → Either e String. Lifts the plain value so the chain can start uniformly with bind."
    tooltip bindParse    = ">>= : takes Either e String and (String → Either e Parsed). Right-path runs parse; Left propagates."
    tooltip bindValidate = ">>= : takes Either e Parsed and (Parsed → Either e Valid). Same pattern."
    tooltip bindSave     = ">>= : takes Either e Valid and (Valid → Either e Saved). Same pattern."
    tooltip parseFn      = "parse : String → Either e Parsed. HOF argument — its input is String, not Either e String, so it cannot sit on the main flow."
    tooltip validateFn   = "validate : Parsed → Either e Valid. Same: supplied to bind as the continuation."
    tooltip saveFn       = "save : Valid → Either e Saved. Same: supplied to bind as the continuation."
    tooltip eSaved       = "Either e Saved — Right on the happy path; the very first Left otherwise."
}

