// SysML v2 — Maybe motivation: WITHOUT the Maybe monad
//
// Every step in the chain may return null.  The caller must insert an
// explicit null-guard decision after each step; one missed guard is a
// NullPointerException.  The earlyExit merge collects all three failure
// paths so they flow to a single Nothing/null output.
//
// Style: types ride on the flow edges as "name : Type", so the decision
// node IS the pattern-match.  No intermediate object boxes for the
// nullable result and the post-check confirmed value — the action's
// output type and the decision branch labels carry that information.

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

        // three fallible steps
        action findUser     : FindUser;
        action findAddress  : FindAddress;
        action findCity     : FindCity;

        // one null-guard per step — each pattern-matches its predecessor's output
        decision checkUser : "null?";
        decision checkAddr : "null?";
        decision checkCity : "null?";

        // all null branches converge here
        merge earlyExit;

        // outputs
        object nothing   : "null";
        object cityName  : "String";

        // --- flows ---
        // Each action's nullable output is carried directly to its guard,
        // labelled with the type that flows on the edge.
        flow from userId      to findUser;
        flow from findUser    to checkUser  : "User | null";
        flow from checkUser   to earlyExit  : "null";
        flow from checkUser   to findAddress : "user : User";        // confirmed non-null

        flow from findAddress to checkAddr  : "Address | null";
        flow from checkAddr   to earlyExit  : "null";
        flow from checkAddr   to findCity   : "address : Address";   // confirmed non-null

        flow from findCity    to checkCity  : "City | null";
        flow from checkCity   to earlyExit  : "null";
        flow from checkCity   to cityName   : "city.name";           // happy-path extract

        flow from earlyExit   to nothing;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without Maybe: explicit null guard at every step"
    name  = "lookupUserCity"
    show userId      as value
    show findUser    as function
    show findAddress as function
    show findCity    as function
    show nothing     as type
    show cityName    as value
    tooltip userId      = "The input: a user ID to look up."
    tooltip findUser    = "find_user(id) — may return null if the user does not exist."
    tooltip findAddress = "find_address(user.address_id) — may return null if no address on file."
    tooltip findCity    = "find_city(address.city_id) — may return null if the city record is missing."
    tooltip checkUser   = "Null guard #1: pattern-matches User | null. The non-null branch carries 'user : User' to findAddress; the null branch joins earlyExit."
    tooltip checkAddr   = "Null guard #2: same pattern repeated. Skipping this is a latent bug."
    tooltip checkCity   = "Null guard #3: yet another check. Business logic is buried in guards."
    tooltip earlyExit   = "Any null terminates the chain here — three separate null paths converge."
    tooltip nothing     = "null — returned when any step failed. Caller must also guard against this."
    tooltip cityName    = "city.name — the happy-path result, reached only when all three checks pass."
}

