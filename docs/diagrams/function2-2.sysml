// SysML v2 — currying activity diagram

package Function2Currying {

    action def CurryOp {
        in  f2      : "(a,b) ⟶ c";    // multi-arg function, HOF input
        out curried : "a ⟶ (b ⟶ c)";  // curried form
    }

    action def ApplyFirst {
        in  curried : "a ⟶ (b ⟶ c)";  // curried fn, HOF input
        in  a       : a;                  // first argument
        out f1      : "b ⟶ c";          // specialised function
    }

    activity def CurryingProcess {
        object f2      : "(a,b) ⟶ c";      // function, HOF input
        action curry   : CurryOp;
        object curried : "a ⟶ (b ⟶ c)";  // curried form

        object a       : a;               // first argument
        action applyA  : ApplyFirst;
        object f1      : "b ⟶ c";        // specialised function

        flow from f2      to curry : "curry";
        flow from curry   to curried;
        flow from curried to applyA : "apply a";
        flow from a       to applyA;
        flow from applyA  to f1;

        succession curry then applyA;
    }
}

#diagram {
    type   = activity
    title  = "Currying: (a,b) ⟶ c  ⟹  a ⟶ (b ⟶ c)"
    name   = "curry"
    show f2      as hof
    show curry   as function
    show curried as function
    show applyA  as function
    show f1      as function
    tooltip f2      = "(a,b) ⟶ c — original multi-argument function, flowing in as a data token"
    tooltip curry   = "curry: transforms a multi-arg function into a chain of single-arg functions"
    tooltip curried = "a ⟶ (b ⟶ c) — the curried form, itself a function"
    tooltip applyA  = "Apply the first argument a, yielding the specialised function"
    tooltip f1      = "b ⟶ c — the specialised function with a already applied"
}
