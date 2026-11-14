package TraversalOptic {
    private import FpDiagram::*;

    action def CollectTargets {
        in  optic : "Traversal S A";
        in  source : S;
        out _ : "[A]";
    }

    action def ModifyTargets {
        in  optic : "Traversal S A";
        in  transform : "A ⟶ A";
        in  source : S;
        out _ : S;
    }

    action def TraversalProcess {
        item source : S;
        item optic : "Traversal S A";
        action collect : CollectTargets;
        item targets : "[A]";

        #FpNodePresentation { role = "hof"; tooltip = "Applied to every focused A; there may be zero, one, or many targets."; }
        item transform : "A ⟶ A";
        action modify : ModifyTargets;
        item updated : S;

        flow from optic to collect : "Traversal S A";
        flow from source to collect : "S";
        flow from collect to targets : "zero or more A";

        flow from optic to modify : "Traversal S A";
        flow from transform to modify : "A ⟶ A";
        flow from source to modify : "S";
        flow from modify to updated : "same structure, all foci modified";
    }

    view diagram : FpActivityView {
        doc /*Traversal updates and collects zero or more targets*/
        expose TraversalProcess;
        render fpActivityDiagram;
    }
}
