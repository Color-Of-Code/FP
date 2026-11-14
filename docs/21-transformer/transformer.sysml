package TransformerStack {
    private import FpDiagram::*;

    part def AppStack {
        #FpNodePresentation { role = "type"; tooltip = "The outer layer provides the environment."; }
        part reader : "ReaderT r";
        #FpNodePresentation { role = "type"; tooltip = "The next layer adds typed failure."; }
        part except : "ExceptT e";
        #FpNodePresentation { role = "type"; tooltip = "The inner effect accumulates a log."; }
        part writer : "WriterT w";
        #FpNodePresentation { role = "type"; tooltip = "The base monad supplies the final interpretation."; }
        part base : Identity;

        connection connect reader to except : "wraps";
        connection connect except to writer : "wraps";
        connection connect writer to base : "base";
    }

    view diagram : FpIbdView {
        doc /*transformer stack*/
        expose AppStack;
        render fpIbdDiagram;
    }
}
