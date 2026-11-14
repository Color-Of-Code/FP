package AdtMotivation {
    private import FpDiagram::*;

    action def SafeDivide {
        in numerator : "Int";
        in denominator : "Int";
        out _ : "Maybe Int";
    }
    action def MatchMaybe {
        in result : "Maybe Int";
        out _ : "handled result";
    }
    action def NullableDivide {
        in numerator : "Int";
        in denominator : "Int";
        out _ : "Int or null";
    }
    action def UncheckedUse {
        in result : "Int or null";
        out _ : "runtime failure if null";
    }

    action def AbsenceHandling {
        item numerator : "10";
        item denominator : "0";
        action divide : SafeDivide;
        decide outcome;
        action match : MatchMaybe;
        action nullableDivide : NullableDivide;
        action unchecked : UncheckedUse;

        flow from numerator to divide;
        flow from denominator to divide;
        flow from divide to outcome;
        flow from outcome to match : "Nothing or Just — handle both";
        flow from numerator to nullableDivide;
        flow from denominator to nullableDivide;
        flow from nullableDivide to unchecked : "nullable result — unchecked";
    }

    view diagram : FpActivityView {
        doc /* Sum types make absence explicit */
        expose AbsenceHandling;
        render fpActivityDiagram;
    }
}
