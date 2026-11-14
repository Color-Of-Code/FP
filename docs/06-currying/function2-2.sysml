// SysML v2 — currying activity diagram

package Function2Currying {
    private import FpDiagram::*;

    action def CurryOp {
        in  f2      : "(a,b) ⟶ c";    // multi-arg function, HOF input
        out curried : "a ⟶ (b ⟶ c)";  // curried form
    }

    action def ApplyFirst {
        in  curried : "a ⟶ (b ⟶ c)";  // curried fn, HOF input
        in  a       : a;                  // first argument
        out f1      : "b ⟶ c";          // specialised function
    }

    action def CurryingProcess {
        #FpNodePresentation { role = "hof"; tooltip = "(a,b) ⟶ c — original multi-argument function, flowing in as a data token"; }
        item f2      : "(a,b) ⟶ c";      // function, HOF input
        #FpNodePresentation { role = "function"; tooltip = "curry: transforms a multi-arg function into a chain of single-arg functions"; }
        action curry   : CurryOp;
        #FpNodePresentation { role = "function"; tooltip = "a ⟶ (b ⟶ c) — the curried form, itself a function"; }
        item curried : "a ⟶ (b ⟶ c)";  // curried form

        item a       : a;               // first argument
        #FpNodePresentation { role = "function"; tooltip = "Apply the first argument a, yielding the specialised function"; }
        action applyA  : ApplyFirst;
        #FpNodePresentation { role = "function"; tooltip = "b ⟶ c — the specialised function with a already applied"; }
        item f1      : "b ⟶ c";        // specialised function

        flow from f2      to curry : "curry";
        flow from curry   to curried;
        flow from curried to applyA : "apply a";
        flow from a       to applyA;
        flow from applyA  to f1;

        succession curry then applyA;
    }
    #FpViewPresentation { name = "curry"; }
    view diagram : FpActivityView {
        doc /*Currying: (a,b) ⟶ c  ⟹  a ⟶ (b ⟶ c)*/
        expose CurryingProcess;
        render fpActivityDiagram;
    }
}

