package OpticsMotivation {
    private import FpDiagram::*;

    action def RebuildPerson {
        in  person : Person;
        in  city : String;
        out updated : Person;
    }

    action def SetCity {
        in  person : Person;
        in  lens : "Lens Person String";
        in  city : String;
        out updated : Person;
    }

    action def NestedUpdate {
        item person : Person;
        item city : String;
        #FpNodePresentation { role = "function"; tooltip = "Without a lens, every intermediate immutable record must be reconstructed."; }
        action rebuild : RebuildPerson;
        item rebuilt : Person;

        #FpNodePresentation { role = "hof"; tooltip = "A composed lens focuses from Person through Address to the city name."; }
        item path : "Lens Person String";
        #FpNodePresentation { role = "function"; tooltip = "set updates the focused field and returns a new Person."; }
        action set : SetCity;
        item updated : Person;

        flow from person to rebuild;
        flow from city to rebuild;
        flow from rebuild to rebuilt;
        flow from person to set;
        flow from path to set;
        flow from city to set;
        flow from set to updated;
    }

    #FpViewPresentation { name = "lens update"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /*optics motivation*/
        expose NestedUpdate;
        render fpActivityDiagram;
    }
}
