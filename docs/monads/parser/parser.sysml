package ParserOverview {
    private import FpDiagram::*;

    action def RunParser {
        in  parser : "Parser a";
        in  input  : String;
        out result : "Maybe (a, String)";
    }

    action def ParserProcess {
        #FpNodePresentation { role = "value"; tooltip = "42 rest — the complete input supplied to the parser."; }
        item input : String;
        #FpNodePresentation { role = "function"; tooltip = "A parser is a function from input text to either failure or a parsed value paired with the unconsumed suffix."; }
        item parser : "Parser Int";
        #FpNodePresentation { role = "function"; tooltip = "Run the parser against the input string."; }
        action runParser : RunParser;
        #FpNodePresentation { role = "type"; tooltip = "Just (42, \" rest\") — the parsed value and the text the parser did not consume."; }
        item result : "Maybe (Int, String)";

        flow from input to runParser : String;
        flow from parser to runParser : "Parser Int";
        flow from runParser to result : "Maybe (Int, String)";
    }

    #FpViewPresentation { name = "Parser"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*A Parser a consumes input and returns a value with the unconsumed suffix*/
        expose ParserProcess;
        render fpActivityDiagram;
    }
}
