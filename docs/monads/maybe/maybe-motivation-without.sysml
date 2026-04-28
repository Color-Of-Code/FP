// SysML v2 — Maybe motivation: WITHOUT the Maybe monad
//
// Every step in the chain may return null.  The caller must insert an
// explicit null-guard decision after each step; one missed guard is a
// NullPointerException.  The earlyExit merge collects all three failure
// paths so they flow to a single Nothing/null output.

package MaybeMotivationWithout {

    action def FindUser {
        in  userId  : UserId;
        out result  : "User | null";
    }

    action def FindAddress {
        in  user    : User;
        out result  : "Address | null";
    }

    action def FindCity {
        in  address : Address;
        out result  : "City | null";
    }

    activity def LookupUserCityWithout {
        // input
        object userId    : UserId;

        // step 1
        action findUser      : FindUser;
        object userOrNull    : "User | null";
        decision checkUser : "null?";
        object user          : User;           // confirmed non-null after check

        // step 2
        action findAddress   : FindAddress;
        object addrOrNull    : "Address | null";
        decision checkAddr : "null?";
        object addr          : Address;        // confirmed non-null after check

        // step 3
        action findCity      : FindCity;
        object cityOrNull    : "City | null";
        decision checkCity : "null?";
        object city          : City;           // confirmed non-null after check

        // all null branches converge here
        merge earlyExit;

        // outputs
        object nothing   : "null";
        object cityName  : "String";

        // --- flows ---
        flow from userId     to findUser;
        flow from findUser   to userOrNull;
        flow from userOrNull to checkUser;

        flow from checkUser  to earlyExit : "null";
        flow from checkUser  to user      : "user";     // confirmed: User (not null)
        flow from user       to findAddress;

        flow from findAddress to addrOrNull;
        flow from addrOrNull  to checkAddr;

        flow from checkAddr  to earlyExit : "null";
        flow from checkAddr  to addr      : "address";  // confirmed: Address (not null)
        flow from addr       to findCity;

        flow from findCity   to cityOrNull;
        flow from cityOrNull  to checkCity;

        flow from checkCity  to earlyExit : "null";
        flow from checkCity  to city      : "city";     // confirmed: City (not null)
        flow from city       to cityName;

        flow from earlyExit  to nothing;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without Maybe: explicit null guard at every step"
    name  = "lookupUserCity"
    show userId    as value
    show findUser  as function
    show findAddress as function
    show findCity  as function
    show user      as value
    show addr      as value
    show city      as value
    show nothing   as type
    show cityName  as value
    tooltip userId     = "The input: a user ID to look up."
    tooltip findUser   = "find_user(id) — may return null if the user does not exist."
    tooltip findAddress = "find_address(user.address_id) — may return null if no address on file."
    tooltip findCity   = "find_city(address.city_id) — may return null if the city record is missing."
    tooltip user       = "User — confirmed non-null by guard #1. Now safe to pass to findAddress."
    tooltip addr       = "Address — confirmed non-null by guard #2. Now safe to pass to findCity."
    tooltip city       = "City — confirmed non-null by guard #3. Now safe to read city.name."
    tooltip checkUser  = "Null guard #1: must check after every fallible step — boilerplate."
    tooltip checkAddr  = "Null guard #2: same pattern repeated. Skipping this is a latent bug."
    tooltip checkCity  = "Null guard #3: yet another check. Business logic is buried in guards."
    tooltip earlyExit  = "Any null terminates the chain here — three separate null paths converge."
    tooltip nothing    = "null — returned when any step failed. Caller must also guard against this."
    tooltip cityName   = "city.name — the happy-path result, reached only when all three checks pass."
}
