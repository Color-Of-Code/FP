// SysML v2 — type activity diagram
// Concept: a type describes the space of values that may inhabit it.

package FunctionTypeActivity {

  activity def TypeConcept {
    object values : "{a0, a1, ...}";
    object a      : "type a";

    flow from values to a : "all possible values";
  }
}

#diagram {
  type  = activity
  title = "Type a"
  name  = "type"
  show values as value
  show a      as type
  tooltip values = "A type can be seen as the set of values that may inhabit it."
  tooltip a      = "type a — used to describe the domain or codomain of a function."
}
