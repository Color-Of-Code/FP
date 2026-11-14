package LazyEvaluationMotivation {
    private import FpDiagram::*;

    action def MaterializeFilter {
        in values : "N records";
        out _ : "materialized filtered list";
    }
    action def MaterializeMap {
        in values : "filtered list";
        out _ : "materialized mapped list";
    }
    action def EagerTake {
        in values : "mapped list";
        out _ : "first 10 (after processing all N)";
    }
    action def LazyFilter {
        in values : "source";
        out _ : "filtered values on demand";
    }
    action def LazyMap {
        in values : "filtered values";
        out _ : "mapped values on demand";
    }
    action def LazyTake {
        in values : "mapped values";
        out _ : "10 results; stop pulling";
    }

    action def SequenceProcessing {
        item eagerSource : "load N records";
        action eagerFilter : MaterializeFilter;
        action eagerMap : MaterializeMap;
        action eagerTake : EagerTake;
        item lazySource : "source (possibly infinite)";
        action filter : LazyFilter;
        action map : LazyMap;
        action take : LazyTake;

        flow from eagerSource to eagerFilter;
        flow from eagerFilter to eagerMap;
        flow from eagerMap to eagerTake;
        flow from lazySource to filter;
        flow from filter to map;
        flow from map to take;
    }

    view diagram : FpActivityView {
        doc /* Lazy pipelines stop when enough results are demanded */
        expose SequenceProcessing;
        render fpActivityDiagram;
    }
}
