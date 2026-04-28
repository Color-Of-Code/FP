// SysML v2 — List motivation: WITH the List monad
//
// Each dimension is one bind step.  Adding a third axis is one new
// line, not a new nested loop level.  pure (or return) lifts the
// final tuple back into a list.

package ListMotivationWith {

    action def BindX {
        in  xs : "[A]";
        out x  : A;
    }

    action def BindY {
        in  ys : "[B]";
        out y  : B;
    }

    action def Pair {
        in  x      : A;
        in  y      : B;
        out result : "(A, B)";
    }

    activity def CartesianWith {
        object xs : "[A]";
        object ys : "[B]";

        action bindX : BindX;
        action bindY : BindY;
        action pair  : Pair;

        object result : "[(A, B)]";

        flow from xs    to bindX;
        flow from bindX to bindY : ">>= x ->";
        flow from ys    to bindY;
        flow from bindY to pair  : ">>= y ->";
        flow from pair  to result : "pure (x, y)";
    }
}

#diagram {
    type  = activity
    title = "With List: one bind per dimension — flat pipeline"
    name  = "cartesian"
    show xs     as value
    show ys     as value
    show bindX  as function
    show bindY  as function
    show pair   as function
    show result as type
    tooltip xs     = "xs : [A] — the first list."
    tooltip ys     = "ys : [B] — the second list."
    tooltip bindX  = "xs >>= \\x -> ...  Iterates over xs, binding each element to the local name x."
    tooltip bindY  = "ys >>= \\y -> ...  Iterates over ys for each x, binding to y."
    tooltip pair   = "pure (x, y) — lifts a single pair back into the list monad."
    tooltip result = "[(A, B)] — the Cartesian product as a flat list.  Each new dimension is one more >>= line."
}
