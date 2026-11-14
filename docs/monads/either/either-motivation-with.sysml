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
    private import FpDiagram::*;

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

    action def ParseValidateSaveWith {
        // input
        #FpNodePresentation { role = "value"; tooltip = "Raw input — for example a request body or untrusted user data."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item raw          : String;

        // lift the plain String into Either — entry point of the chain
        #FpNodePresentation { role = "function"; tooltip = "pure : String → Either e String. Lifts the plain value so the chain can start uniformly with bind."; laneId = "monad"; laneLabel = "Either monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action pureRaw      : Pure;

        // each subsequent step is bind + a fallible function (HOF argument)
        #FpNodePresentation { role = "hof"; tooltip = "parse : String → Either e Parsed. HOF argument — its input is String, not Either e String, so it cannot sit on the main flow."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }
        item parseFn      : "String ⟶ Either e Parsed";
        #FpNodePresentation { role = "function"; tooltip = ">>= : takes Either e String and (String → Either e Parsed). Right-path runs parse; Left propagates."; laneId = "monad"; laneLabel = "Either monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindParse    : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "validate : Parsed → Either e Valid. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "2"; }

        item validateFn   : "Parsed ⟶ Either e Valid";
        #FpNodePresentation { role = "function"; tooltip = ">>= : takes Either e Parsed and (Parsed → Either e Valid). Same pattern."; laneId = "monad"; laneLabel = "Either monad"; laneOrder = "1"; laneMemberOrder = "2"; }
        action bindValidate : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "save : Valid → Either e Saved. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "3"; }

        item saveFn       : "Valid ⟶ Either e Saved";
        #FpNodePresentation { role = "function"; tooltip = ">>= : takes Either e Valid and (Valid → Either e Saved). Same pattern."; laneId = "monad"; laneLabel = "Either monad"; laneOrder = "1"; laneMemberOrder = "3"; }
        action bindSave     : Bind;

        // output
        #FpNodePresentation { role = "type"; tooltip = "Either e Saved — Right on the happy path; the very first Left otherwise."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "4"; }
        item eSaved       : "Either e Saved";

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

        // ── Swimlanes ───────────────────────────────────────────────────────
        // Top lane: raw input, final output, and the user-supplied fallible
        // functions all live in plain-value land.
        // Bottom lane: pure (entry into the monad) and the bind chain — the
        // operations that work on the elevated values.


    }
    #FpViewPresentation { name = "parseValidateSave"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: Left propagates automatically; every step has the same shape*/
        expose ParseValidateSaveWith;
        render fpActivityDiagram;
    }
}

