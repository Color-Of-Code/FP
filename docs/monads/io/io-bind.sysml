// SysML v2 — IO bind: implementation activity
// IO a is a DESCRIPTION (recipe) of a side-effectful computation — nothing runs until exec.
// bind sequences two recipes: execute first, feed its result to the second recipe, execute that.
// The order of bind calls determines the order of real-world side effects.

package IOBindImpl {
    private import FpDiagram::*;

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

    action def IOBindProcess {
        #FpNodePresentation { role = "type"; tooltip = "IO a — a description (recipe) of a side-effectful computation. Nothing has run yet."; }
        item ia     : "IO a";
        #FpNodePresentation { role = "hof"; tooltip = "(a ⟶ IO b) — given result a, constructs the next IO action description"; }
        item f      : "a ⟶ IO b";
        #FpNodePresentation { role = "function"; tooltip = "Execute ia: the runtime runs the described effect and produces value a. Real I/O happens here."; }
        action exec_a  : ExecA;
        #FpNodePresentation { role = "function"; tooltip = "Apply f(a): build the next IO action description from a. No effect yet — only the description is created."; }
        action build   : BuildNext;
        #FpNodePresentation { role = "function"; tooltip = "Execute IO b: the runtime runs the second described effect. Effects of ia happened BEFORE this."; }
        action exec_b  : ExecB;
        #FpNodePresentation { role = "value"; tooltip = "b — the final result. The sequencing of exec_a before exec_b is the entire bind contract."; }
        item b       : b;

        flow from ia      to exec_a;
        flow from exec_a  to build  : "a";
        flow from f       to build;
        flow from build   to exec_b : "IO b";
        flow from exec_b  to b;

        succession exec_a then build;
        succession build  then exec_b;
    }
    #FpViewPresentation { name = "bind"; }
    view diagram : FpActivityView {
        doc /*IO bind: execute ia, feed a to f to build IO b, execute IO b — also called: .then (Promises), >>=*/
        expose IOBindProcess;
        render fpActivityDiagram;
    }
}

