// SysML v2 — Reader motivation: WITHOUT the Reader monad (bind)
//
// Every helper takes Config as a parameter — even if it uses only one
// field.  The plumbing changes the signal-vs-noise ratio of the API:
// most of every signature is "and a config".  Adding a new helper
// means threading config through every call site.

package ReaderMotivationWithout {
    private import FpDiagram::*;

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

    action def BuildUrlWithout {
        // input
        #FpNodePresentation { role = "type"; tooltip = "Config — the environment record. Every helper requires it as an argument."; }
        item cfg : Config;

        // every helper receives cfg explicitly
        #FpNodePresentation { role = "function"; tooltip = "getHost(config) — needs only config.host but takes the whole record."; }
        action getHost  : GetHost;
        #FpNodePresentation { role = "function"; tooltip = "getPort(config) — needs only config.port but still receives the whole record."; }
        action getPort  : GetPort;
        #FpNodePresentation { role = "function"; tooltip = "buildUrl(config, host, port) — receives config a third time. Adding a new helper repeats the plumbing."; }
        action buildUrl : BuildUrl;

        // output
        #FpNodePresentation { role = "type"; tooltip = "URL — the result. Most of the signatures involved were boilerplate."; }
        item url      : "URL";

        flow from cfg     to getHost;
        flow from cfg     to getPort;
        flow from cfg     to buildUrl;
        flow from getHost to buildUrl : "host : String";
        flow from getPort to buildUrl : "port : Int";
        flow from buildUrl to url;
    }
    #FpViewPresentation { name = "buildUrl"; }
    view diagram : FpActivityView {
        doc /*Without bind: config passed into every function explicitly*/
        expose BuildUrlWithout;
        render fpActivityDiagram;
    }
}

