// SysML v2 — monad IBD: what happens inside bind
// (>>=) :: M a ⟶ (a ⟶ M b) ⟶ M b      m >>= f = join (fmap f m)
//
// Reading guide:
//   • the «block» frame is bind; its boundary ports are its whole call interface:
//     the wrapped input M a, the user's continuation f, and the wrapped result M b
//   • no step ever extracts a plain a from M a — there is no general M a ⟶ a;
//     f only sees an a inside fmap, as the instance decides
//   • fmap and join are supplied by the monad instance; f is the only user code
//   • the nested M (M b) exists only inside the block — join flattens it before
//     anything leaves through the boundary

package MonadSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "M a — the wrapped input"; }
        port in  ma : "M a";
        #FpNodePresentation { tooltip = "f : a ⟶ M b — user code; returns a new wrapped value"; }
        port in  f  : "a ⟶ M b";
        #FpNodePresentation { tooltip = "M b — the flat result; never M (M b)"; }
        port out mb : "M b";

        #FpNodePresentation { role = "function"; tooltip = "fmap :: (a ⟶ M b) ⟶ M a ⟶ M (M b) — from Functor. Applies f under the outer context without removing it: Maybe 0 or 1 times, List once per element, Reader/State once the environment/state is supplied."; }
        part fmap : "M a ⟶ M (M b)" {
            port in  f : "a ⟶ M b";
            port in  _ : "M a";
            port out _ : "M (M b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: M (M b) ⟶ M b — the monad-specific part. Merges outer and inner context: Maybe drops Nothing, List concatenates, Writer appends logs, State runs the outer then the inner computation."; }
        part join : "M (M b) ⟶ M b" {
            port in  _ : "M (M b)";
            port out _ : "M b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*(>>=) :: M a ⟶ (a ⟶ M b) ⟶ M b — inside bind: fmap f, then join; the nested M (M b) never leaves the block*/
        expose bind;
        render fpIbdDiagram;
    }
}
