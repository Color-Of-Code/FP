// SysML v2 — Reader motivation: WITHOUT the Reader monad (bind)
//
// Every helper takes Config as a parameter — even if it uses only one
// field.  The plumbing changes the signal-vs-noise ratio of the API:
// most of every signature is "and a config".  Adding a new helper
// means threading config through every call site.

package ReaderMotivationWithout {

    action def GetHost {
        in  cfg  : Config;
        out _    : String;
    }

    action def GetPort {
        in  cfg  : Config;
        out _    : Int;
    }

    action def BuildUrl {
        in  cfg     : Config;
        in  host    : String;
        in  portNum : Int;
        out _       : "URL";
    }

    activity def BuildUrlWithout {
        // input
        object cfg : Config;

        // every helper receives cfg explicitly
        action getHost  : GetHost;
        action getPort  : GetPort;
        action buildUrl : BuildUrl;

        // output
        object url      : "URL";

        flow from cfg     to getHost;
        flow from cfg     to getPort;
        flow from cfg     to buildUrl;
        flow from getHost to buildUrl : "host : String";
        flow from getPort to buildUrl : "port : Int";
        flow from buildUrl to url;
    }
}

#diagram {
    type   = activity
    layout = elk
    title = "Without bind: config passed into every function explicitly"
    name  = "buildUrl"
    show cfg      as type
    show getHost  as function
    show getPort  as function
    show buildUrl as function
    show url      as type
    tooltip cfg      = "Config — the environment record. Every helper requires it as an argument."
    tooltip getHost  = "getHost(config) — needs only config.host but takes the whole record."
    tooltip getPort  = "getPort(config) — needs only config.port but still receives the whole record."
    tooltip buildUrl = "buildUrl(config, host, port) — receives config a third time. Adding a new helper repeats the plumbing."
    tooltip url      = "URL — the result. Most of the signatures involved were boilerplate."
}

