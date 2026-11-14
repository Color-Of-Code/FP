package ImmutabilityMotivation {
    private import FpDiagram::*;

    action def MutateInPlace {
        in user : "User(age=30)";
        out _ : "User(age=31)";
    }
    action def ObserveReferences {
        in user : "User(age=31)";
        out _ : "all references see age 31";
    }
    action def CopyWithUpdate {
        in user : "User(age=30)";
        out _ : "new User(age=31)";
    }
    action def Outcome {
        in _ : "old and new User values";
    }

    action def Comparison {
        #FpNodePresentation { role = "value"; tooltip = "The starting value for both alternatives."; }
        item user : "User(age=30)";
        #FpNodePresentation { role = "function"; tooltip = "Mutation changes the value all aliases observe."; }
        action mutate : MutateInPlace;
        action observe : ObserveReferences;
        #FpNodePresentation { role = "function"; tooltip = "An update returns a distinct value and leaves the input intact."; }
        action copy : CopyWithUpdate;
        action coexist : Outcome;

        flow from user to mutate;
        flow from mutate to observe;
        flow from user to copy;
        flow from copy to coexist;
    }

    view diagram : FpActivityView {
        doc /* Immutability: mutation versus new values */
        expose Comparison;
        render fpActivityDiagram;
    }
}
