package ConcurrencyMotivation {
    private import FpDiagram::*;

    action def Locking {
        in  shared : "Shared State";
        out outcome : "Race or deadlock";
    }

    action def PureParallelism {
        in  values : "Immutable Values";
        out results : "Parallel Results";
    }

    action def Transaction {
        in  shared : "Shared State";
        out result : "Atomic Result";
    }

    action def ActorMessage {
        in  message : "Immutable Message";
        out delivered : "Isolated State";
    }

    action def ConcurrencyChoices {
        item shared : "Shared State";
        #FpNodePresentation { role = "function"; tooltip = "Locks require coordination and can be misused."; }
        action locking : Locking;
        item unsafe : "Race or deadlock";

        item values : "Immutable Values";
        action parallel : PureParallelism;
        item results : "Parallel Results";

        action transaction : Transaction;
        item atomic : "Atomic Result";

        item message : "Immutable Message";
        action actor : ActorMessage;
        item isolated : "Isolated State";

        flow from shared to locking;
        flow from locking to unsafe;
        flow from values to parallel;
        flow from parallel to results;
        flow from shared to transaction;
        flow from transaction to atomic;
        flow from message to actor;
        flow from actor to isolated;
    }

    #FpViewPresentation { name = "concurrency"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*concurrency motivation*/
        expose ConcurrencyChoices;
        render fpActivityDiagram;
    }
}
