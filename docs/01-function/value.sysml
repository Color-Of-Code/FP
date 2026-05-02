// SysML v2 — value activity diagram
// Concept: a concrete value a0 inhabits the type a.

package FunctionValueActivity {

    activity def ValueConcept {
        object a0 : "a0 : a";
        object a  : "type a";

        flow from a0 to a : "inhabits";
    }
}

#diagram {
    type  = activity
    title = "Value a0 of type a"
    name  = "value"
    show a0 as value
    show a  as type
    tooltip a0 = "a0 — one concrete representative, or witness, of type a."
    tooltip a  = "type a — the classification that a0 belongs to."
}