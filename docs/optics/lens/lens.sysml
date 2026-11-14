package LensOptic {
    private import FpDiagram::*;

    part def ComposedLens {
        part addressL : "Lens Person Address";
        part cityL : "Lens Address City";
        part compose : "lens composition";
        part personCityL : "Lens Person City";

        part person : Person;
        part getOp : "get";
        part city : City;
        part replacementCity : City;
        part setOp : "set";
        part updatedPerson : Person;

        connection connect addressL to compose;
        connection connect cityL to compose;
        connection connect compose to personCityL;

        connection connect personCityL to getOp;
        connection connect person to getOp;
        connection connect getOp to city;

        connection connect personCityL to setOp;
        connection connect person to setOp;
        connection connect replacementCity to setOp;
        connection connect setOp to updatedPerson;
    }

    view diagram : FpIbdView {
        doc /*Lens composes field paths for get and set*/
        expose ComposedLens;
        render fpIbdDiagram;
    }
}
