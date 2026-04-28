// SysML v2 — Maybe motivation: WITH the Maybe monad
//
// Every function returns Maybe instead of a nullable type.  bind (>>=)
// handles the null test internally: if the incoming value is Nothing it
// short-circuits and never calls the next function.  No explicit guards,
// no repeated if-null-return-null boilerplate.

package MaybeMotivationWith {

    action def FindUser {
        in  userId  : UserId;
        out result  : "Maybe User";
    }

    action def FindAddress {
        in  user    : User;
        out result  : "Maybe Address";
    }

    action def FindCity {
        in  address : Address;
        out result  : "Maybe City";
    }

    action def LiftName {
        in  city    : City;
        out result  : "Maybe String";
    }

    activity def LookupUserCityWith {
        // input
        object userId   : UserId;

        // pipeline — each step returns a Maybe value
        action findUser     : FindUser;
        object maybeUser    : "Maybe User";

        action findAddress  : FindAddress;
        object maybeAddr    : "Maybe Address";

        action findCity     : FindCity;
        object maybeCity    : "Maybe City";

        action liftName     : LiftName;
        object cityName     : "Maybe String";

        // flows — ">>= bind" labels mark where bind does its short-circuit magic
        flow from userId     to findUser;
        flow from findUser   to maybeUser;
        flow from maybeUser  to findAddress : ">>= bind";
        flow from findAddress to maybeAddr;
        flow from maybeAddr  to findCity    : ">>= bind";
        flow from findCity   to maybeCity;
        flow from maybeCity  to liftName    : ">>= bind";
        flow from liftName   to cityName;
    }
}

#diagram {
    type  = activity
    title = "With Maybe: bind short-circuits on Nothing automatically"
    name  = "lookupUserCity"
    show userId      as value
    show findUser    as function
    show findAddress as function
    show findCity    as function
    show liftName    as function
    show maybeUser   as type
    show maybeAddr   as type
    show maybeCity   as type
    show cityName    as type
    tooltip userId      = "The input: a user ID to look up."
    tooltip findUser    = "find_user(id) → Maybe User.  Returns Just user or Nothing."
    tooltip findAddress = "find_address(user.address_id) → Maybe Address.\nbind skips this entirely if findUser returned Nothing."
    tooltip findCity    = "find_city(address.city_id) → Maybe City.\nbind skips this if any earlier step was Nothing."
    tooltip liftName    = "pure(city.name) → Maybe String.  Lifts the plain String into Maybe."
    tooltip maybeUser   = "Maybe User — Just the user record, or Nothing."
    tooltip maybeAddr   = "Maybe Address — Just the address, or Nothing propagated from above."
    tooltip maybeCity   = "Maybe City — Just the city, or Nothing propagated from above."
    tooltip cityName    = "Maybe String — Just city.name on success; Nothing if any step failed.\nNo explicit null checks anywhere in this chain."
}
