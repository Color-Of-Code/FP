// SysML v2 — declaration activity diagram
// Concept: the signature f :: a ⟶ b declares the accepted and produced types.

package FunctionDeclarationActivity {

    action def DeclaredFunction {
        in  a : a;
        out b : b;
    }

    activity def DeclarationConcept {
        action f : DeclaredFunction;
    }
}

#diagram {
    type  = activity
    title = "Declaration f :: a ⟶ b"
    name  = "declaration"
    show f as function
    tooltip f = "The function identified by the declaration f :: a ⟶ b."
}