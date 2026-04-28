// SysML v2 — Reader motivation: WITH the Reader monad
//
// The environment is supplied once at the call site (runReader env).
// Each step receives it implicitly.  asks projects out the field a
// step actually needs; nothing else has to know about the rest of the
// config record.

package ReaderMotivationWith {

    action def AsksHost {
        in  env  : Config;
        out host : String;
    }

    action def AsksPort {
        in  env  : Config;
        out portNum : Int;
    }

    action def BuildUrl {
        in  host : String;
        in  portNum : Int;
        out url  : "URL";
    }

    activity def BuildUrlWith {
        action asksHost : AsksHost;
        action asksPort : AsksPort;
        action buildUrl : BuildUrl;
        object url      : "URL";

        flow from asksHost to asksPort : ">>= bind";
        flow from asksPort to buildUrl : ">>= bind";
        flow from buildUrl to url      : "runReader env";
    }
}

#diagram {
    type  = activity
    title = "With Reader: environment supplied once at the top"
    name  = "buildUrl"
    show asksHost as function
    show asksPort as function
    show buildUrl as function
    show url      as type
    tooltip asksHost = "asks (.host) — projects the host field out of the implicit Config environment."
    tooltip asksPort = "asks (.port) — projects the port field out of the implicit Config environment.  bind chains it after asksHost without rethreading the config."
    tooltip buildUrl = "buildUrl(host, port) — pure assembly of the URL.  No need to receive the environment at all."
    tooltip url      = "URL — final value.  runReader env supplies the environment exactly once at the top of the chain."
}
