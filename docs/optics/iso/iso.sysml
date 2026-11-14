package IsoOptic {
    private import FpDiagram::*;

    part def EmailIso {
        part email : Email;
        part iso : "Iso Email String";

        part viewOp : "view";
        part text : String;
        part reviewOp : "review";
        part rebuiltEmail : Email;

        connection connect iso to viewOp;
        connection connect email to viewOp;
        connection connect viewOp to text;
        connection connect iso to reviewOp;
        connection connect text to reviewOp;
        connection connect reviewOp to rebuiltEmail;
    }

    view diagram : FpIbdView {
        doc /*Iso converts losslessly in both directions*/
        expose EmailIso;
        render fpIbdDiagram;
    }
}
