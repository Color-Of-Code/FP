// SysML v2 — Maybe motivation: WITH the Maybe monad (bind + pure)
//
// The fallible functions DO NOT COMPOSE naturally:
//   findUser    : UserId  → Maybe User
//   findAddress : User    → Maybe Address      ← expects User, not Maybe User
//   findCity    : Address → Maybe City         ← expects Address, not Maybe Address
//   liftName    : City    → Maybe String       ← expects City, not Maybe City
//
// Two combinators do all the work:
//   pure  : a → Maybe a                       — lift a plain value into Maybe
//   (>>=) : Maybe a → (a → Maybe b) → Maybe b — chain a fallible step
//
// pure starts the chain by lifting the plain UserId into Maybe UserId;
// every subsequent step is bind applied to a Maybe value and the next
// fallible function (passed in as an HOF argument).  All four steps
// have the same shape — that uniformity is the point.

package MaybeMotivationWith {

    action def FindUser {
        in  userId  : UserId;
        out _       : "Maybe User";
    }

    action def FindAddress {
        in  user    : User;
        out _       : "Maybe Address";
    }

    action def FindCity {
        in  address : Address;
        out _       : "Maybe City";
    }

    action def LiftName {
        in  city    : City;
        out _       : "Maybe String";
    }

    // pure : a → Maybe a
    action def Pure {
        in  a : a;
        out _ : "Maybe a";
    }

    // bind : Maybe a → (a → Maybe b) → Maybe b
    action def Bind {
        in  ma : "Maybe a";
        in  f  : "a ⟶ Maybe b";
        out _  : "Maybe b";
    }

    activity def LookupUserCityWith {
        // input
        object userId       : UserId;

        // lift the plain UserId into Maybe — entry point of the chain
        action pureId       : Pure;

        // every subsequent step is bind applied to the previous Maybe
        // and the next fallible function (passed in as an HOF value).
        object findUserFn   : "UserId ⟶ Maybe User";
        action bindUser     : Bind;

        object findAddrFn   : "User ⟶ Maybe Address";
        action bindAddr     : Bind;

        object findCityFn   : "Address ⟶ Maybe City";
        action bindCity     : Bind;

        object liftNameFn   : "City ⟶ Maybe String";
        action bindName     : Bind;

        // output
        object cityName     : "Maybe String";

        // main flow runs through the bind nodes
        flow from userId   to pureId;
        flow from pureId   to bindUser   : "Maybe UserId";
        flow from bindUser to bindAddr   : "Maybe User";
        flow from bindAddr to bindCity   : "Maybe Address";
        flow from bindCity to bindName   : "Maybe City";
        flow from bindName to cityName   : "Maybe String";

        // each fallible function is supplied to its bind as the f argument
        flow from findUserFn  to bindUser;
        flow from findAddrFn  to bindAddr;
        flow from findCityFn  to bindCity;
        flow from liftNameFn  to bindName;

        // ── Swimlanes ───────────────────────────────────────────────────────
        lane plain : "Plain values & functions" =
            userId, findUserFn, findAddrFn, findCityFn, liftNameFn, cityName;
        lane monad : "Maybe monad" =
            pureId, bindUser, bindAddr, bindCity, bindName;
    }
}

#diagram {
    type  = activity
    title = "With pure + bind: every step has the same shape; bind is the glue"
    name  = "lookupUserCity"
    show userId      as value
    show pureId      as function
    show bindUser    as function
    show bindAddr    as function
    show bindCity    as function
    show bindName    as function
    show findUserFn  as hof
    show findAddrFn  as hof
    show findCityFn  as hof
    show liftNameFn  as hof
    show cityName    as type
    tooltip userId      = "The input: a plain UserId."
    tooltip pureId      = "pure : UserId → Maybe UserId. Lifts the plain value into Maybe so the chain can start uniformly with bind."
    tooltip bindUser    = ">>= : takes Maybe UserId and (UserId → Maybe User). Unwraps Just id and applies findUser; propagates Nothing."
    tooltip bindAddr    = ">>= : takes Maybe User and (User → Maybe Address). Same pattern."
    tooltip bindCity    = ">>= : takes Maybe Address and (Address → Maybe City). Same pattern."
    tooltip bindName    = ">>= : takes Maybe City and (City → Maybe String). Same pattern."
    tooltip findUserFn  = "find_user : UserId → Maybe User. Passed as an argument to bind — its input type is UserId, not Maybe UserId, so it cannot sit on the main flow."
    tooltip findAddrFn  = "find_address : User → Maybe Address. Same: supplied to bind as the continuation."
    tooltip findCityFn  = "find_city : Address → Maybe City. Same: supplied to bind as the continuation."
    tooltip liftNameFn  = "lift_name : City → Maybe String (= pure ∘ .name). Lifts the plain String back into Maybe."
    tooltip cityName    = "Maybe String — Just city.name on success; Nothing if any step failed.\nNo explicit null checks anywhere in this chain; pure starts it, bind drives it."
}
