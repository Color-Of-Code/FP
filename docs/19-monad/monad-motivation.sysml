package MonadMotivation {
    private import FpDiagram::*;

    action def MapEffect {
        in  ma : "Maybe a";
        in  f  : "a -> Maybe b";
        out nested : "Maybe (Maybe b)";
    }

    action def Flatten {
        in  nested : "Maybe (Maybe b)";
        out result : "Maybe b";
    }

    action def Bind {
        in  ma : "Maybe a";
        in  f  : "a -> Maybe b";
        out result : "Maybe b";
    }

    action def BindComparison {
        #FpNodePresentation { role = "type"; }
        item ma : "Maybe a";
        #FpNodePresentation { role = "hof"; tooltip = "The next computation may itself return Nothing."; }
        item f : "a -> Maybe b";

        #FpNodePresentation { role = "function"; tooltip = "fmap applies f but leaves a nested Maybe."; }
        action fmap : MapEffect;
        item nested : "Maybe (Maybe b)";
        action flatten : Flatten;
        item flattened : "Maybe b";

        #FpNodePresentation { role = "function"; tooltip = "bind combines mapping and flattening in one step."; }
        action bind : Bind;
        item bound : "Maybe b";

        flow from ma to fmap;
        flow from f to fmap;
        flow from fmap to nested;
        flow from nested to flatten;
        flow from flatten to flattened;
        flow from ma to bind;
        flow from f to bind;
        flow from bind to bound;
    }

    #FpViewPresentation { name = "bind"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*monad motivation*/
        expose BindComparison;
        render fpActivityDiagram;
    }
}
