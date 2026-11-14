// SysML v2 — STM monad IBD: what happens inside bind
// (>>=) :: STM a ⟶ (a ⟶ STM b) ⟶ STM b      m >>= f = join (fmap f m)
//
// STM a is an atomic action on transactional variables (TVar). bind sequences
// two atomic actions inside the SAME transaction:
//   • fmap builds an action whose result is itself an action: STM (STM b)
//   • join runs the outer action, then the inner one, within one transaction
// The whole transaction commits atomically or retries — no partial commit.

package STMSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "STM a — an atomic action on TVars (transactional variables). Not yet committed."; }
        port in  ma : "STM a";
        #FpNodePresentation { tooltip = "f : a ⟶ STM b — user code; given result a of the first action, constructs the next atomic step"; }
        port in  f  : "a ⟶ STM b";
        #FpNodePresentation { tooltip = "STM b — the composed atomic action. Runs inside atomically :: STM a -> IO a. Never STM (STM b)."; }
        port out mb : "STM b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: STM a ⟶ STM (STM b)\nAn action that runs ma and returns f a — the next action — without running it."; }
        part fmap : "STM a ⟶ STM (STM b)" {
            port in  f : "a ⟶ STM b";
            port in  _ : "STM a";
            port out _ : "STM (STM b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: STM (STM b) ⟶ STM b — the STM-specific part\nRuns the outer action, then the inner action, within ONE transaction.\nIf any readTVar conflicts → the entire composed transaction retries from scratch."; }
        part join : "STM (STM b) ⟶ STM b" {
            port in  _ : "STM (STM b)";
            port out _ : "STM b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: STM a ⟶ (a ⟶ STM b) ⟶ STM b — inside bind: fmap f, then join runs both actions in one transaction — also called: >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
