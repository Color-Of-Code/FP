// SysML v2 — Either bind: implementation activity
//
// Pattern-match on ea simultaneously tests the constructor AND
// destructures the payload:
//   Right a0  →  a0 : a   is available immediately; pass to f.
//                f returns Either e b directly — bind never re-wraps.
//                f's own result may itself be Right b' or Left e';
//                bind passes it through unchanged either way.
//   Left  e0  →  short-circuit: f is NEVER invoked.  The error value e0
//                is preserved exactly; only the static type widens from
//                Left e to Either e b (the e component is identical).
//
// Both branches converge at a merge into the single output ec : Either e b.
// This is the key correctness property of Either bind: short-circuit on
// Left, propagate the error verbatim, never invent a new error, never
// swallow one.

package EitherBindImpl {

    action def ApplyF {
        in  a0 : a;
        in  f  : "a ⟶ Either e b";
        out eb : "Either e b";          // whatever f returns: Right b' or Left e'
    }

    action def WidenLeft {
        in  e0    : e;
        out eLeft : "Either e b";       // = Left e0, retyped from Left e to Either e b
    }

    activity def EitherBindProcess {
        // inputs
        object ea : "Either e a";
        object f  : "a ⟶ Either e b";

        // pattern match: tests the constructor AND destructures both payloads
        decision matchEa;

        // Right path — destructured a0 : a flows directly into f
        action apply_f : ApplyF;

        // Left path — destructured e0 : e flows directly into widen
        action widen    : WidenLeft;

        // both branches converge here
        merge joinResult;

        // single output
        object ec : "Either e b";

        // ── main flow ────────────────────────────────────────────
        flow from ea to matchEa;

        // Right branch: destructured a0 flows directly into f
        flow from matchEa to apply_f  : "Right a0  (a0 : a)";
        flow from f       to apply_f;
        flow from apply_f to joinResult : "f(a0) — Right b' or Left e'";

        // Left branch: destructured e0 flows directly into widen (UNCHANGED, only type widens)
        flow from matchEa to widen    : "Left e0  (e0 : e, f skipped)";
        flow from widen   to joinResult : "Left e0 : Either e b";

        // single output
        flow from joinResult to ec;

        // ── notes (UML-style annotations pinned to specific nodes) ──
        note shortCircuit on matchEa :
            "Pattern match short-circuits:\nLeft skips f entirely.";
        note errorIdentity on widen :
            "Type widens, value preserved bit-identical.\nThis is what 'error preserved verbatim' means.";
        note fResultPassThrough on apply_f :
            "Whatever f returns (Right b' or Left e')\nis forwarded UNCHANGED — bind never\ninspects or rewraps f's result.";
    }
}

#diagram {
    type   = activity
    layout = elk
    title  = "Either bind — also called: andThen / and_then, Bind, flatMap, >>="
    name   = "bind"

    show ea       as type
    show f        as hof
    show apply_f  as function
    show widen    as function
    show ec       as type
    show shortCircuit       as note
    show errorIdentity      as note
    show fResultPassThrough as note

    tooltip ea         = "Either e a — the input.  Either Right a0 (success carrying a value of type a) or Left e0 (failure carrying an error value of type e)."
    tooltip f          = "(a ⟶ Either e b) — the continuation.  Invoked ONLY on the Right branch.  Skipped entirely when ea is Left."
    tooltip matchEa    = "Pattern match on the sum-type constructor.\n  Right a0 → a0 : a flows directly into f (no separate unwrap step).\n  Left  e0 → e0 : e flows directly into widen; the right branch is skipped.\nExactly one branch fires per invocation; the runtime never executes both."
    tooltip apply_f    = "Apply f(a0).  f returns Either e b directly (Right b' or Left e').  bind does NOT inspect f's result — whatever f returned is forwarded unchanged.  This is what makes bind compositional: a Left arising inside f propagates exactly the same way as a Left arising before f."
    tooltip widen      = "Re-tag the Left constructor: the runtime VALUE Left e0 stays bit-identical, but the static type widens from Left e to Either e b so it unifies with the Right branch's output type at the merge.  No allocation, no transformation — only the type changes."
    tooltip joinResult = "Merge node — both branches produce a value of the SAME type Either e b.  Exactly one inflow fires per invocation; the merge is a control-flow join, not a runtime choice."
    tooltip ec         = "Either e b — the single result of bind.  Carries either f's output (when ea was Right) or the original error e0 (when ea was Left)."
}
