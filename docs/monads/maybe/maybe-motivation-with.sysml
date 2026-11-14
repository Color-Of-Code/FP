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
    private import FpDiagram::*;

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

    action def LookupUserCityWith {
        // input
        #FpNodePresentation { role = "value"; tooltip = "The input: a plain UserId."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "0"; }
        item userId       : UserId;

        // lift the plain UserId into Maybe — entry point of the chain
        #FpNodePresentation { role = "function"; tooltip = "pure : UserId → Maybe UserId. Lifts the plain value into Maybe so the chain can start uniformly with bind."; laneId = "monad"; laneLabel = "Maybe monad"; laneOrder = "1"; laneMemberOrder = "0"; }
        action pureId       : Pure;

        // every subsequent step is bind applied to the previous Maybe
        // and the next fallible function (passed in as an HOF value).
        #FpNodePresentation { role = "hof"; tooltip = "find_user : UserId → Maybe User. Passed as an argument to bind — its input type is UserId, not Maybe UserId, so it cannot sit on the main flow."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "1"; }
        item findUserFn   : "UserId ⟶ Maybe User";
        #FpNodePresentation { role = "function"; tooltip = ">>= : takes Maybe UserId and (UserId → Maybe User). Unwraps Just id and applies findUser; propagates Nothing."; laneId = "monad"; laneLabel = "Maybe monad"; laneOrder = "1"; laneMemberOrder = "1"; }
        action bindUser     : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "find_address : User → Maybe Address. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "2"; }

        item findAddrFn   : "User ⟶ Maybe Address";
        #FpNodePresentation { role = "function"; tooltip = ">>= : takes Maybe User and (User → Maybe Address). Same pattern."; laneId = "monad"; laneLabel = "Maybe monad"; laneOrder = "1"; laneMemberOrder = "2"; }
        action bindAddr     : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "find_city : Address → Maybe City. Same: supplied to bind as the continuation."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "3"; }

        item findCityFn   : "Address ⟶ Maybe City";
        #FpNodePresentation { role = "function"; tooltip = ">>= : takes Maybe Address and (Address → Maybe City). Same pattern."; laneId = "monad"; laneLabel = "Maybe monad"; laneOrder = "1"; laneMemberOrder = "3"; }
        action bindCity     : Bind;

        #FpNodePresentation { role = "hof"; tooltip = "lift_name : City → Maybe String (= pure ∘ .name). Lifts the plain String back into Maybe."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "4"; }

        item liftNameFn   : "City ⟶ Maybe String";
        #FpNodePresentation { role = "function"; tooltip = ">>= : takes Maybe City and (City → Maybe String). Same pattern."; laneId = "monad"; laneLabel = "Maybe monad"; laneOrder = "1"; laneMemberOrder = "4"; }
        action bindName     : Bind;

        // output
        #FpNodePresentation { role = "type"; tooltip = "Maybe String — Just city.name on success; Nothing if any step failed.\nNo explicit null checks anywhere in this chain; pure starts it, bind drives it."; laneId = "plain"; laneLabel = "Plain values & functions"; laneOrder = "0"; laneMemberOrder = "5"; }
        item cityName     : "Maybe String";

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


    }
    #FpViewPresentation { name = "lookupUserCity"; }
    view diagram : FpActivityView {
        doc /*With pure + bind: every step has the same shape; bind is the glue*/
        expose LookupUserCityWith;
        render fpActivityDiagram;
    }
}

