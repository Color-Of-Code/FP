package SemigroupMonoid {
    private import FpDiagram::*;

    action def Combine {
        in left : a;
        in right : a;
        out _ : a;
    }
    action def Laws {
        item x : a;
        item y : a;
        item z : a;
        item empty : "mempty";
        action xy : Combine;
        action leftAssoc : Combine;
        action yz : Combine;
        action rightAssoc : Combine;
        action leftIdentity : Combine;
        #FpNodePresentation { role = "function"; tooltip = "Both associations produce the same result."; }
        item assocEquals : "=";
        #FpNodePresentation { role = "function"; tooltip = "Combining with mempty leaves x unchanged."; }
        item identityEquals : "=";

        flow from x to xy;
        flow from y to xy;
        flow from xy to leftAssoc;
        flow from z to leftAssoc;
        flow from y to yz;
        flow from z to yz;
        flow from x to rightAssoc;
        flow from yz to rightAssoc;
        flow from leftAssoc to assocEquals;
        flow from rightAssoc to assocEquals;
        flow from empty to leftIdentity;
        flow from x to leftIdentity;
        flow from leftIdentity to identityEquals;
        flow from x to identityEquals;
    }

    view diagram : FpActivityView {
        doc /* Semigroup associativity and monoid identity laws */
        expose Laws;
        render fpActivityDiagram;
    }
}
