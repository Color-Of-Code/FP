// SysML v2 — total vs partial activity diagram
// Concept: classification by whether the function is defined for every input.

package FunctionDefinitionsActivity {

  activity def TotalityConcept {
    object f       : "f :: a ⟶ b";
    decision total : "defined for every a?";
    object safe    : "total";
    object partial : "partial";

    flow from f     to total;
    flow from total to safe    : "yes";
    flow from total to partial : "no";
  }
}

#diagram {
  type  = activity
  title = "Total vs partial"
  name  = "totality"
  layout = elk
  show f       as function
  show total   as decision
  show safe    as value
  show partial as value
  tooltip f       = "A function under discussion."
  tooltip total   = "A total function returns a result for every input in the domain."
  tooltip safe    = "Total — defined for all values of type a."
  tooltip partial = "Partial — undefined for some values of type a."
}
