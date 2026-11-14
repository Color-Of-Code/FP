package FpDiagram {
    private import Views::*;
    private import StandardViewDefinitions::*;

    metadata def FpNodePresentation {
        attribute role : String;
        attribute tooltip : String;
        attribute laneId : String;
        attribute laneLabel : String;
        attribute laneOrder : String;
        attribute laneMemberOrder : String;
    }

    metadata def FpViewPresentation {
        attribute name : String;
        attribute direction : String;
    }

    view def FpActivityView specializes ActionFlowView;
    view def FpIbdView specializes InterconnectionView;

    rendering def fpActivityDiagram specializes GraphicalRendering;
    rendering def fpIbdDiagram specializes GraphicalRendering;
}
