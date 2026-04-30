// SysML v2 — Maybe motivation: WITHOUT the Maybe monad (bind)
//
// Every step in the chain returns Maybe X.  The caller must insert an
// explicit Nothing-guard decision after each step; one missed guard is a
// runtime error.  The earlyExit merge collects all three failure
// paths so they flow to a single Nothing output.
//
// Style: types ride on the flow edges as "name : Type", so the decision
// node IS the pattern-match.  No intermediate object boxes for the
// nullable result and the post-check confirmed value — the action's
// output type and the decision branch labels carry that information.
//
// We use "Maybe X" here (same as the with-monad diagram) to highlight
// that the type is identical — what differs is HOW you handle it:
// manual null-guards vs. automatic bind short-circuiting.

package MaybeMotivationWithout {

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

    activity def LookupUserCityWithout {
        // input
        object userId    : UserId;

        // three fallible steps
        action findUser     : FindUser;
        action findAddress  : FindAddress;
        action findCity     : FindCity;

        // one null-guard per step — each pattern-matches its predecessor's output
        decision checkUser : "Nothing?";
        decision checkAddr : "Nothing?";
        decision checkCity : "Nothing?";

        // all null branches converge here
        merge earlyExit;

        // outputs
        object nothing   : "Nothing";
        object cityName  : "String";

        // --- flows ---
        // Each action's Maybe output is carried directly to its guard,
        // labelled with the type that flows on the edge.
        flow from userId      to findUser;
        flow from findUser    to checkUser  : "Maybe User";
        flow from checkUser   to earlyExit  : "Nothing";
        flow from checkUser   to findAddress : "Just user";          // confirmed non-null

        flow from findAddress to checkAddr  : "Maybe Address";
        flow from checkAddr   to earlyExit  : "Nothing";
        flow from checkAddr   to findCity   : "Just address";        // confirmed non-null

        flow from findCity    to checkCity  : "Maybe City";
        flow from checkCity   to earlyExit  : "Nothing";
        flow from checkCity   to cityName   : "Just city → name";    // happy-path extract

        flow from earlyExit   to nothing;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without bind: explicit Nothing guard at every step"
    name  = "lookupUserCity"
    show userId      as value
    show findUser    as function
    show findAddress as function
    show findCity    as function
    show nothing     as type
    show cityName    as value
    tooltip userId      = "The input: a user ID to look up."
    tooltip findUser    = "find_user(id) → Maybe User. May return Nothing if the user does not exist."
    tooltip findAddress = "find_address(user.address_id) → Maybe Address. May return Nothing if no address on file."
    tooltip findCity    = "find_city(address.city_id) → Maybe City. May return Nothing if the city record is missing."
    tooltip checkUser   = "Guard #1: pattern-matches Maybe User. The Just branch unwraps user for findAddress; Nothing joins earlyExit."
    tooltip checkAddr   = "Guard #2: same pattern repeated. Skipping this is a latent bug."
    tooltip checkCity   = "Guard #3: yet another check. Business logic is buried in guards."
    tooltip earlyExit   = "Any Nothing terminates the chain here — three separate failure paths converge."
    tooltip nothing     = "Nothing — returned when any step failed. Caller must also guard against this."
    tooltip cityName    = "city.name — the happy-path result, reached only when all three checks pass."
}

