// SysML v2 — Reader motivation: WITH the Reader monad (bind + pure)
//
// The producing functions DO NOT COMPOSE naturally:
//   asksHost : Config → String
//   asksPort : Config → Int        ← also expects Config, not Reader Config String
//   build    : String → Int → URL  ← expects plain values, not Readers
//
// Two combinators do all the work:
//   pure  : a → Reader r a                              — ignore the env, return a
//   (>>=) : Reader r a → (a → Reader r b) → Reader r b
//
// bind feeds the SAME env to both sides: the inner function receives
// the unwrapped a and produces a new Reader, which is then run with
// the same env.  asks lifts a getter Config → X into Reader Config X.
// runReader env supplies the env exactly once at the top of the chain.

package ReaderMotivationWith {

    action def AsksHost {
        out _ : "Reader Config String";
    }

    action def AsksPort {
        out _ : "Reader Config Int";
    }

    action def BuildUrl {
        in  host : String;
        in  portNum : Int;
        out _    : "URL";
    }

    // pure : a → Reader r a
    action def Pure {
        in  a : a;
        out _ : "Reader r a";
    }

    // bind : Reader r a → (a → Reader r b) → Reader r b
    action def Bind {
        in  ma : "Reader r a";
        in  f  : "a ⟶ Reader r b";
        out _  : "Reader r b";
    }

    activity def BuildUrlWith {
        // entry — first projection from the env
        action asksHost  : AsksHost;

        // bind threads the unwrapped host into the next Reader-producing function
        object readPortFn : "String ⟶ Reader Config (String, Int)";
        action bindHost  : Bind;

        // and once both host and port are in scope, the final pure step
        // wraps the constructed URL back into Reader
        object pureUrlFn : "(String, Int) ⟶ Reader Config URL";
        action bindPair  : Bind;

        // output
        object url       : "URL";

        // main flow runs through the bind nodes
        flow from asksHost to bindHost : "Reader Config String";
        flow from bindHost to bindPair : "Reader Config (String, Int)";
        flow from bindPair to url      : "runReader env";

        // each Reader-producing function is supplied to its bind as the f argument
        flow from readPortFn to bindHost;
        flow from pureUrlFn  to bindPair;
    }
}

#diagram {
    type  = activity
    layout = elk
    title = "With pure + bind: env supplied once at the top; bind feeds it to every step"
    name  = "buildUrl"
    show asksHost   as function
    show bindHost   as function
    show bindPair   as function
    show readPortFn as hof
    show pureUrlFn  as hof
    show url        as type
    tooltip asksHost   = "asks (.host) : Reader Config String — projects host out of the implicit env."
    tooltip bindHost   = ">>= : runs asksHost with env, then runs the continuation (which itself returns a Reader) with the SAME env."
    tooltip bindPair   = ">>= : final bind — turns the (host, port) pair into the URL via build, lifted with pure."
    tooltip readPortFn = "λhost. asksPort >>= λport. pure (host, port). HOF argument — captures host in scope while running asksPort under the same env."
    tooltip pureUrlFn  = "λ(host, port). pure (build host port). HOF argument — wraps the pure URL back into Reader."
    tooltip url        = "URL — final value. runReader env supplies the environment exactly once at the top of the chain."
}

