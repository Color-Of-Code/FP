// SysML v2 — declaration activity diagram
// Concept: the signature f :: a ⟶ b declares the accepted and produced types.

package FunctionDeclarationActivity {
    private import FpDiagram::*;

    action def DeclaredFunction {
        in  a : a;
        out b : b;
    }

    action def DeclarationConcept {
        #FpNodePresentation { role = "function"; tooltip = "The function identified by the declaration f :: a ⟶ b."; }
        action f : DeclaredFunction;
    }
    #FpViewPresentation { name = "declaration"; }
    view diagram : FpActivityView {
        doc /*Declaration f :: a ⟶ b*/
        expose DeclarationConcept;
        render fpActivityDiagram;
    }
}

