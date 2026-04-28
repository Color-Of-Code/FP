// SysML v2 — Reader motivation: WITHOUT the Reader monad
//
// Every helper takes Config as a parameter — even if it uses only one
// field.  The plumbing changes signal-vs-noise ratio of the API: most
// of every signature is "and a config".  Adding a new helper means
// threading config through every call site.

package ReaderMotivationWithout {

    action def GetHost {
        in  cfg  : Config;
        out host : String;
    }

    action def GetPort {
        in  cfg  : Config;
        out portNum : Int;
    }

    action def BuildUrl {
        in  cfg  : Config;
        in  host : String;
        in  portNum : Int;
        out url  : "URL";
    }

    activity def BuildUrlWithout {
        object cfg : Config;

        action getHost  : GetHost;
        action getPort  : GetPort;
        action buildUrl : BuildUrl;
        object url      : "URL";

        flow from cfg     to getHost;
        flow from cfg     to getPort;
        flow from cfg     to buildUrl;
        flow from getHost to buildUrl : "host";
        flow from getPort to buildUrl : "port";
        flow from buildUrl to url;
    }
}

#diagram {
    type  = activity
    title = "Without Reader: config passed into every function"
    name  = "buildUrl"
    show cfg      as type
    show getHost  as function
    show getPort  as function
    show buildUrl as function
    show url      as type
    tooltip cfg      = "Config — the environment record.  Every helper requires it as an argument."
    tooltip getHost  = "getHost(config) — needs only config.host but takes the whole record."
    tooltip getPort  = "getPort(config) — needs only config.port but still receives the whole record."
    tooltip buildUrl = "buildUrl(config, host, port) — receives config a third time.  Adding a new helper repeats the plumbing."
    tooltip url      = "URL — the result.  Most of the signatures involved were boilerplate."
}
