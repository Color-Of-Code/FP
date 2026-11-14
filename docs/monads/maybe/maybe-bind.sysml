// SysML v2 — Maybe bind: implementation activity
// Pattern match on ma simultaneously tests the constructor and
// destructures the payload.  The Just branch carries a : a (already
// unwrapped); f is applied and returns Maybe b directly — no re-wrap.
// The Nothing branch short-circuits: the same constructor is propagated
// as Nothing (: Maybe b) without calling f.  Wrapping is pure's job.

package MaybeBindImpl {
    private import FpDiagram::*;

    action def ApplyF {
        in  a0 : a;
        in  f  : "a ⟶ Maybe b";
        out mb : "Maybe b";
    }

    action def MaybeBindProcess {
        // inputs
        #FpNodePresentation { role = "type"; tooltip = "Maybe a — the input value. Either Just a0 or Nothing."; }
        item ma   : "Maybe a";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ Maybe b) — the continuation. Only called when ma is Just a0."; }
        item f    : "a ⟶ Maybe b";

        // decision: pattern match — tests constructor AND destructures in one step
        // Just branch  → a : a  (payload already unwrapped by the match)
        // Nothing branch → short-circuit directly to output
        #FpNodePresentation { tooltip = "Pattern match: simultaneously tests the constructor and destructures the payload.\nJust a0 → a0 (: a) flows directly to f — no separate unwrap step.\nNothing → skip f entirely."; }
        decide matchMa;

        // Just path: f consumes the unwrapped payload directly — no separate object
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a0). Returns Maybe b directly — bind never re-wraps. Wrapping is pure's job."; }
        action apply_f : ApplyF;

        // merge both paths
        #FpNodePresentation { tooltip = "Merge: both paths produce Maybe b (Just-path result or Nothing short-circuit)."; }
        merge joinResult;

        // output
        #FpNodePresentation { role = "type"; tooltip = "Maybe b — the single result of bind."; }
        item mb : "Maybe b";

        // main flow
        flow from ma to matchMa;

        // Just branch: decision destructures; the type 'a0 : a' rides on the edge
        flow from matchMa to apply_f : "Just a0  (a0 : a)";
        flow from f       to apply_f;
        flow from apply_f to joinResult;

        // Nothing branch: short-circuit — same constructor, type shifts to Maybe b
        flow from matchMa to joinResult : "Nothing (: Maybe b)";

        // single output
        flow from joinResult to mb;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*Maybe bind: pattern match unwraps Just or short-circuits Nothing — also called: flatMap, andThen / and_then, SelectMany, chain, >>=*/
        expose MaybeBindProcess;
        render fpActivityDiagram;
    }
}

