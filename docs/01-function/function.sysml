// SysML v2 — function activity diagram
// Concept: f :: a ⟶ b maps a value from the domain type to the codomain type.

package FunctionActivity {

  action def FunctionOp {
    in  a : a;
    out b : b;
  }

  activity def FunctionConcept {
    object a : "type a";
    action f : FunctionOp;
    object b : "type b";

    flow from a to f : "domain";
    flow from f to b : "codomain";
  }
}

#diagram {
  type  = activity
  title = "Function f :: a ⟶ b"
  name  = "function"
  show a as type
  show f as function
  show b as type
  tooltip a = "type a — the domain of f"
  tooltip f = "f consumes a value of type a and produces a value of type b"
  tooltip b = "type b — the codomain of f"
}
