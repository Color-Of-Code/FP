// SysML v2 — application activity diagram
// Concept: applying f to a concrete value a0 yields a concrete result b0.

package FunctionApplicationActivity {

  action def ApplyOp {
    in  a : a;
    out b : b;
  }

  activity def ApplicationConcept {
    object a0;
    action f  : ApplyOp;
    object b0;

    flow from a0 to f;
    flow from f  to b0;
  }
}

#diagram {
  type  = activity
  title = "Application f(a0) = b0"
  name  = "apply"
  show a0 as value
  show f  as function
  show b0 as value
  tooltip a0 = "a0 — a concrete input value of type a"
  tooltip f  = "Apply f to the input value"
  tooltip b0 = "b0 — the resulting value of type b"
}
