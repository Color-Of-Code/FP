// SysML v2 — IO bind: implementation activity
// IO a is a DESCRIPTION (recipe) of a side-effectful computation — nothing runs until exec.
// bind sequences two recipes: execute first, feed its result to the second recipe, execute that.
// The order of bind calls determines the order of real-world side effects.

package IOBindImpl {

    action def ExecA {
        in  ia  : "IO a";  // a description of an effect
        out a   : a;       // the value produced when the effect actually runs
    }

    action def BuildNext {
        in  a   : a;
        in  f   : "a ⟶ IO b";
        out ib  : "IO b";  // the next effect description, built from a
    }

    action def ExecB {
        in  ib  : "IO b";
        out b   : b;
    }

    activity def IOBindProcess {
        object ia     : "IO a";
        object f      : "a ⟶ IO b";
        action exec_a  : ExecA;
        action build   : BuildNext;
        action exec_b  : ExecB;
        object b       : b;

        flow from ia      to exec_a;
        flow from exec_a  to build  : "a";
        flow from f       to build;
        flow from build   to exec_b : "IO b";
        flow from exec_b  to b;

        succession exec_a then build;
        succession build  then exec_b;
    }
}

#diagram {
    type  = activity
    title = "IO bind: execute ia, feed a to f to build IO b, execute IO b — also called: .then (Promises), >>="
    name  = "bind"
    show ia     as type
    show f      as hof
    show exec_a as function
    show build  as function
    show exec_b as function
    show b      as value
    tooltip ia     = "IO a — a description (recipe) of a side-effectful computation. Nothing has run yet."
    tooltip f      = "(a ⟶ IO b) — given result a, constructs the next IO action description"
    tooltip exec_a = "Execute ia: the runtime runs the described effect and produces value a. Real I/O happens here."
    tooltip build  = "Apply f(a): build the next IO action description from a. No effect yet — only the description is created."
    tooltip exec_b = "Execute IO b: the runtime runs the second described effect. Effects of ia happened BEFORE this."
    tooltip b      = "b — the final result. The sequencing of exec_a before exec_b is the entire bind contract."
}
