package NaturalTransformations {
    private import FpDiagram::*;

    action def MapF {
        in function : "a ⟶ b";
        in value : "F a";
        out _ : "F b";
    }
    action def AlphaB {
        in value : "F b";
        out _ : "G b";
    }
    action def AlphaA {
        in value : "F a";
        out _ : "G a";
    }
    action def MapG {
        in function : "a ⟶ b";
        in value : "G a";
        out _ : "G b";
    }
    action def NaturalitySquare {
        #FpNodePresentation { role = "value"; }
        item fa : "F a";
        #FpNodePresentation { role = "hof"; tooltip = "The same ordinary function is used on both routes."; }
        item f : "f :: a ⟶ b";
        action fmapF : MapF;
        action alphaB : AlphaB;
        action alphaA : AlphaA;
        action fmapG : MapG;
        #FpNodePresentation { role = "function"; tooltip = "Both routes produce the same G b."; }
        item equals : "=";

        flow from fa to fmapF;
        flow from f to fmapF;
        flow from fmapF to alphaB;
        flow from fa to alphaA;
        flow from alphaA to fmapG;
        flow from f to fmapG;
        flow from alphaB to equals;
        flow from fmapG to equals;
    }

    view diagram : FpActivityView {
        doc /* The naturality square: both routes produce the same G b */
        expose NaturalitySquare;
        render fpActivityDiagram;
    }
}
