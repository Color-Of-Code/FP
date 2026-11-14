package Composition {
    private import FpDiagram::*;

    action def Compose {
        in first : "a ⟶ b";
        in second : "b ⟶ c";
        out _ : "a ⟶ c";
    }
    action def Apply {
        in function : "a ⟶ c";
        in value : a;
        out _ : c;
    }

    action def CompositionFlow {
        #FpNodePresentation { role = "hof"; tooltip = "f transforms a value from a to b."; }
        item f : "f :: a ⟶ b";
        #FpNodePresentation { role = "hof"; tooltip = "g transforms the intermediate b to c."; }
        item g : "g :: b ⟶ c";
        #FpNodePresentation { role = "value"; }
        item x : a;
        #FpNodePresentation { role = "function"; tooltip = "Composition creates a new function h = g ∘ f."; }
        action compose : Compose;
        item h : "h = g ∘ f :: a ⟶ c";
        action apply : Apply;

        flow from f to compose;
        flow from g to compose;
        flow from compose to h;
        flow from h to apply;
        flow from x to apply;
    }

    view diagram : FpActivityView {
        doc /* Function composition applies f then g */
        expose CompositionFlow;
        render fpActivityDiagram;
    }
}
