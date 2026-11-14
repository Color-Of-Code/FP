package TypeClassesMotivation {
    private import FpDiagram::*;

    part def PolymorphicDispatch {
        #FpNodePresentation { role = "function"; tooltip = "Manual dispatch requires a separate function for each type."; }
        part showInt : "showInt :: Int ⟶ String";
        part showBool : "showBool :: Bool ⟶ String";
        #FpNodePresentation { role = "type"; tooltip = "A type class groups the shared operation behind one contract."; }
        part showClass : "class Show a where show :: a ⟶ String";
        #FpNodePresentation { role = "function"; }
        part intInstance : "instance Show Int";
        part boolInstance : "instance Show Bool";
        #FpNodePresentation { role = "value"; tooltip = "One polymorphic client works with every Show instance."; }
        part print : "print :: Show a ⇒ a ⟶ IO ()";

        connection connect showClass to intInstance : "implements";
        connection connect showClass to boolInstance : "implements";
        connection connect intInstance to print : "dispatch";
        connection connect boolInstance to print : "dispatch";
    }

    view diagram : FpIbdView {
        doc /* Type classes replace manual dispatch with polymorphic use */
        expose PolymorphicDispatch;
        render fpIbdDiagram;
    }
}
